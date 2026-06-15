-- ============================================================
-- 0003 — Read receipts / unread message tracking
-- Run via: Supabase SQL Editor (Database → SQL → New query)
-- ============================================================

create table public.message_reads (
  chat_room_id  uuid not null references public.chat_rooms on delete cascade,
  user_id       uuid not null references public.profiles on delete cascade,
  last_read_at  timestamptz not null default now(),
  primary key (chat_room_id, user_id)
);

alter table public.message_reads enable row level security;

-- Both participants can see read state (enables "seen" indicators)
create policy "message_reads: participants read"
  on public.message_reads for select
  to authenticated
  using (
    exists (
      select 1 from public.chat_rooms cr
      join public.connections c on c.id = cr.connection_id
      where cr.id = chat_room_id
        and (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    )
  );

-- Users only write their own read marker
create policy "message_reads: own insert"
  on public.message_reads for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "message_reads: own update"
  on public.message_reads for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Per-room unread counts for the current user, one round-trip
create or replace function public.get_unread_counts()
returns table (chat_room_id uuid, unread_count bigint)
language sql
security invoker
set search_path = public
as $$
  select m.chat_room_id, count(*)::bigint
  from public.messages m
  join public.chat_rooms cr on cr.id = m.chat_room_id
  join public.connections c on c.id = cr.connection_id
  where (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    and m.sender_id <> auth.uid()
    and m.created_at > coalesce(
      (select mr.last_read_at
         from public.message_reads mr
        where mr.chat_room_id = m.chat_room_id
          and mr.user_id = auth.uid()),
      'epoch'::timestamptz
    )
  group by m.chat_room_id;
$$;

-- Conversation list overview: last message + unread count per room,
-- one round-trip instead of fetching every message in every room
create or replace function public.get_conversation_overview()
returns table (
  chat_room_id uuid,
  last_content text,
  last_type text,
  last_sender_id uuid,
  last_at timestamptz,
  unread_count bigint
)
language sql
security invoker
set search_path = public
as $$
  with my_rooms as (
    select cr.id
    from public.chat_rooms cr
    join public.connections c on c.id = cr.connection_id
    where c.sender_id = auth.uid() or c.receiver_id = auth.uid()
  ),
  last_msg as (
    select distinct on (m.chat_room_id)
      m.chat_room_id, m.content, m.message_type, m.sender_id, m.created_at
    from public.messages m
    join my_rooms r on r.id = m.chat_room_id
    order by m.chat_room_id, m.created_at desc
  ),
  unread as (
    select m.chat_room_id, count(*)::bigint as cnt
    from public.messages m
    join my_rooms r on r.id = m.chat_room_id
    where m.sender_id <> auth.uid()
      and m.created_at > coalesce(
        (select mr.last_read_at
           from public.message_reads mr
          where mr.chat_room_id = m.chat_room_id
            and mr.user_id = auth.uid()),
        'epoch'::timestamptz
      )
    group by m.chat_room_id
  )
  select lm.chat_room_id, lm.content, lm.message_type, lm.sender_id, lm.created_at,
         coalesce(u.cnt, 0)
  from last_msg lm
  left join unread u on u.chat_room_id = lm.chat_room_id;
$$;

-- FIX: cross-user push delivery. The "Users manage own subscriptions" RLS
-- policy on push_subscriptions means a sender's session can never read the
-- recipient's subscription rows, so pushes silently never fire. This
-- security-definer function returns a target's subscriptions ONLY when the
-- caller shares a connection (any status) with the target.
create or replace function public.get_push_targets(target uuid)
returns table (endpoint text, p256dh text, auth text)
language sql
security definer
set search_path = public
as $$
  select ps.endpoint, ps.p256dh, ps.auth
  from public.push_subscriptions ps
  where ps.user_id = target
    and exists (
      select 1 from public.connections c
      where (c.sender_id = auth.uid() and c.receiver_id = target)
         or (c.sender_id = target and c.receiver_id = auth.uid())
    );
$$;

revoke all on function public.get_push_targets(uuid) from public;
grant execute on function public.get_push_targets(uuid) to authenticated;

-- Ensure realtime is on for messages (idempotent)
do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;
end $$;

-- Speed up the unread scan and common lookups
create index if not exists messages_room_created_idx
  on public.messages (chat_room_id, created_at desc);

create index if not exists connections_receiver_status_idx
  on public.connections (receiver_id, status);

create index if not exists connections_sender_idx
  on public.connections (sender_id);

create index if not exists startups_founder_idx
  on public.startups (founder_id);

create index if not exists investment_offers_investor_idx
  on public.investment_offers (investor_id);
