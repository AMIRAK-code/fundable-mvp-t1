-- ============================================================
-- Fundable — Initial Schema Migration
-- Run via: supabase db push  OR  paste into Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────
-- EXTENSIONS
-- ─────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────
create table public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  role        text not null check (role in ('founder', 'investor')),
  full_name   text,
  avatar_url  text,
  bio         text,
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Anyone authenticated can read any profile (needed for feed)
create policy "profiles: authenticated read"
  on public.profiles for select
  to authenticated
  using (true);

-- Users can only insert/update their own profile
create policy "profiles: own insert"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

create policy "profiles: own update"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ─────────────────────────────────────────
-- STARTUPS  (founder-specific)
-- ─────────────────────────────────────────
create table public.startups (
  id              uuid primary key default uuid_generate_v4(),
  founder_id      uuid not null references public.profiles on delete cascade,
  name            text not null,
  pitch           text not null,
  hero_image_url  text,
  industry        text,
  created_at      timestamptz not null default now()
);

alter table public.startups enable row level security;

create policy "startups: authenticated read"
  on public.startups for select
  to authenticated
  using (true);

create policy "startups: founder insert"
  on public.startups for insert
  to authenticated
  with check (founder_id = auth.uid());

create policy "startups: founder update"
  on public.startups for update
  to authenticated
  using (founder_id = auth.uid())
  with check (founder_id = auth.uid());

create policy "startups: founder delete"
  on public.startups for delete
  to authenticated
  using (founder_id = auth.uid());

-- ─────────────────────────────────────────
-- INVESTOR DETAILS  (investor-specific)
-- ─────────────────────────────────────────
create table public.investor_details (
  id           uuid primary key default uuid_generate_v4(),
  investor_id  uuid not null unique references public.profiles on delete cascade,
  firm_name    text,
  check_size   text,
  sectors      text[],
  thesis       text,
  created_at   timestamptz not null default now()
);

alter table public.investor_details enable row level security;

create policy "investor_details: authenticated read"
  on public.investor_details for select
  to authenticated
  using (true);

create policy "investor_details: own insert"
  on public.investor_details for insert
  to authenticated
  with check (investor_id = auth.uid());

create policy "investor_details: own update"
  on public.investor_details for update
  to authenticated
  using (investor_id = auth.uid())
  with check (investor_id = auth.uid());

-- ─────────────────────────────────────────
-- CONNECTIONS
-- ─────────────────────────────────────────
create table public.connections (
  id           uuid primary key default uuid_generate_v4(),
  sender_id    uuid not null references public.profiles on delete cascade,
  receiver_id  uuid not null references public.profiles on delete cascade,
  status       text not null default 'pending'
                 check (status in ('pending', 'accepted', 'declined')),
  created_at   timestamptz not null default now(),
  unique (sender_id, receiver_id)
);

alter table public.connections enable row level security;

-- Sender or receiver can read the connection
create policy "connections: participants read"
  on public.connections for select
  to authenticated
  using (sender_id = auth.uid() or receiver_id = auth.uid());

-- Only the sender can create a pending request
create policy "connections: sender insert"
  on public.connections for insert
  to authenticated
  with check (sender_id = auth.uid() and status = 'pending');

-- Only the receiver can update status (accept/decline)
create policy "connections: receiver update"
  on public.connections for update
  to authenticated
  using (receiver_id = auth.uid());

-- ─────────────────────────────────────────
-- CHAT ROOMS
-- ─────────────────────────────────────────
create table public.chat_rooms (
  id             uuid primary key default uuid_generate_v4(),
  connection_id  uuid not null unique references public.connections on delete cascade,
  created_at     timestamptz not null default now()
);

alter table public.chat_rooms enable row level security;

-- Only the two participants of the underlying connection can see the room
create policy "chat_rooms: participants read"
  on public.chat_rooms for select
  to authenticated
  using (
    exists (
      select 1 from public.connections c
      where c.id = connection_id
        and (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    )
  );

-- Only the trigger (service role) inserts chat rooms — no direct user insert
-- (If you need manual inserts during testing, temporarily grant insert to authenticated)

-- ─────────────────────────────────────────
-- MESSAGES
-- ─────────────────────────────────────────
create table public.messages (
  id            uuid primary key default uuid_generate_v4(),
  chat_room_id  uuid not null references public.chat_rooms on delete cascade,
  sender_id     uuid not null references public.profiles on delete cascade,
  content       text not null,
  created_at    timestamptz not null default now()
);

alter table public.messages enable row level security;

-- Only participants of the chat room can read messages
create policy "messages: participants read"
  on public.messages for select
  to authenticated
  using (
    exists (
      select 1 from public.chat_rooms cr
      join public.connections c on c.id = cr.connection_id
      where cr.id = chat_room_id
        and (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    )
  );

-- Only participants can send messages, and sender_id must be themselves
create policy "messages: participants insert"
  on public.messages for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.chat_rooms cr
      join public.connections c on c.id = cr.connection_id
      where cr.id = chat_room_id
        and (c.sender_id = auth.uid() or c.receiver_id = auth.uid())
    )
  );

-- ─────────────────────────────────────────
-- TRIGGER: auto-create profile on signup
-- ─────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'founder'),
    coalesce(new.raw_user_meta_data->>'full_name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─────────────────────────────────────────
-- TRIGGER: auto-create chat_room when connection accepted
-- ─────────────────────────────────────────
create or replace function public.handle_connection_accepted()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status = 'pending' then
    insert into public.chat_rooms (connection_id)
    values (new.id)
    on conflict (connection_id) do nothing;
  end if;
  return new;
end;
$$;

create trigger on_connection_accepted
  after update on public.connections
  for each row execute procedure public.handle_connection_accepted();

-- ─────────────────────────────────────────
-- STORAGE BUCKETS
-- ─────────────────────────────────────────
insert into storage.buckets (id, name, public)
values
  ('avatars',      'avatars',      true),
  ('hero-images',  'hero-images',  true)
on conflict (id) do nothing;

-- Authenticated users can upload to their own folder (path: {uid}/filename)
create policy "avatars: owner upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars: owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars: public read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

create policy "hero-images: owner upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'hero-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "hero-images: owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'hero-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "hero-images: public read"
  on storage.objects for select
  to public
  using (bucket_id = 'hero-images');

-- ─────────────────────────────────────────
-- REALTIME  (enable for messages)
-- ─────────────────────────────────────────
-- Run this in Supabase Dashboard → Database → Replication
-- OR uncomment the line below if your Supabase version supports it via SQL:
-- alter publication supabase_realtime add table public.messages;
