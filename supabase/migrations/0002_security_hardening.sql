-- ============================================================
-- Fundable — Security Hardening Migration
--
-- Brings previously-undocumented schema into version control and ENSURES
-- row level security is enabled with owner-scoped policies. Idempotent: safe
-- to run against a database where some of these objects already exist.
--
-- Addresses audit findings:
--   #2  Unversioned schema / unverifiable RLS (push_subscriptions,
--       investment_offers, message-media bucket, added columns)
--   #3  Private chat media exposed via public bucket
--   #9  Unpublished startup drafts readable by any authenticated user
-- ============================================================

-- ─────────────────────────────────────────
-- Columns added after the initial schema
-- ─────────────────────────────────────────
alter table public.startups
  add column if not exists published boolean not null default false,
  add column if not exists links     jsonb   not null default '{}'::jsonb;

alter table public.messages
  add column if not exists message_type text not null default 'text',
  add column if not exists media_url    text;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'messages_message_type_check'
  ) then
    alter table public.messages
      add constraint messages_message_type_check
      check (message_type in ('text', 'image'));
  end if;
end$$;

-- ─────────────────────────────────────────
-- INVESTMENT OFFERS  (investor-specific)
-- ─────────────────────────────────────────
create table if not exists public.investment_offers (
  id           uuid primary key default uuid_generate_v4(),
  investor_id  uuid not null references public.profiles on delete cascade,
  title        text not null,
  description  text not null default '',
  amount       text,
  stage        text,
  sectors      text[],
  status       text not null default 'active' check (status in ('active', 'closed')),
  links        jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);

alter table public.investment_offers enable row level security;

drop policy if exists "investment_offers: read active or own" on public.investment_offers;
create policy "investment_offers: read active or own"
  on public.investment_offers for select
  to authenticated
  using (status = 'active' or investor_id = auth.uid());

drop policy if exists "investment_offers: owner insert" on public.investment_offers;
create policy "investment_offers: owner insert"
  on public.investment_offers for insert
  to authenticated
  with check (investor_id = auth.uid());

drop policy if exists "investment_offers: owner update" on public.investment_offers;
create policy "investment_offers: owner update"
  on public.investment_offers for update
  to authenticated
  using (investor_id = auth.uid())
  with check (investor_id = auth.uid());

drop policy if exists "investment_offers: owner delete" on public.investment_offers;
create policy "investment_offers: owner delete"
  on public.investment_offers for delete
  to authenticated
  using (investor_id = auth.uid());

-- ─────────────────────────────────────────
-- PUSH SUBSCRIPTIONS
-- Owner-only for the authenticated client. Push DELIVERY reads these via the
-- service-role key (see src/lib/supabase/admin.ts), which bypasses RLS — so no
-- cross-user read policy is needed (and must not exist).
-- ─────────────────────────────────────────
create table if not exists public.push_subscriptions (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.profiles on delete cascade,
  endpoint    text not null,
  p256dh      text not null,
  auth        text not null,
  created_at  timestamptz not null default now(),
  unique (user_id, endpoint)
);

alter table public.push_subscriptions enable row level security;

drop policy if exists "push_subscriptions: owner select" on public.push_subscriptions;
create policy "push_subscriptions: owner select"
  on public.push_subscriptions for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "push_subscriptions: owner insert" on public.push_subscriptions;
create policy "push_subscriptions: owner insert"
  on public.push_subscriptions for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "push_subscriptions: owner update" on public.push_subscriptions;
create policy "push_subscriptions: owner update"
  on public.push_subscriptions for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "push_subscriptions: owner delete" on public.push_subscriptions;
create policy "push_subscriptions: owner delete"
  on public.push_subscriptions for delete
  to authenticated
  using (user_id = auth.uid());

-- ─────────────────────────────────────────
-- #9  Tighten startups read: drafts only visible to their owner
-- ─────────────────────────────────────────
drop policy if exists "startups: authenticated read" on public.startups;
drop policy if exists "startups: read published or own" on public.startups;
create policy "startups: read published or own"
  on public.startups for select
  to authenticated
  using (published = true or founder_id = auth.uid());

-- ─────────────────────────────────────────
-- #3  Private message-media bucket, scoped to chat-room participants
-- ─────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('message-media', 'message-media', false)
on conflict (id) do update set public = false;

-- Object path convention: {chat_room_id}/{filename}
drop policy if exists "message-media: participants read" on storage.objects;
create policy "message-media: participants read"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'message-media'
    and exists (
      select 1
      from public.chat_rooms cr
      join public.connections c on c.id = cr.connection_id
      where cr.id::text = (storage.foldername(name))[1]
        and (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    )
  );

drop policy if exists "message-media: participants upload" on storage.objects;
create policy "message-media: participants upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'message-media'
    and exists (
      select 1
      from public.chat_rooms cr
      join public.connections c on c.id = cr.connection_id
      where cr.id::text = (storage.foldername(name))[1]
        and (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    )
  );
