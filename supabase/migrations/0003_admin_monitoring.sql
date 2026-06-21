-- ============================================================
-- Fundable — Admin & Monitoring
--
--   * profiles.is_admin   — gates the /admin monitoring dashboard
--   * app_events          — lightweight operational event log (push failures,
--                           server-action errors, …). Server-only: written and
--                           read via the service role; no authenticated/anon
--                           policies exist, so RLS denies all regular clients.
-- ============================================================

alter table public.profiles
  add column if not exists is_admin boolean not null default false;

create table if not exists public.app_events (
  id          uuid primary key default uuid_generate_v4(),
  type        text not null,
  level       text not null default 'info' check (level in ('info', 'warn', 'error')),
  message     text,
  context     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists app_events_created_at_idx on public.app_events (created_at desc);
create index if not exists app_events_level_idx      on public.app_events (level);

-- RLS on with no policies → only the service role can read/write (the dashboard
-- and logEvent both use the service-role client server-side).
alter table public.app_events enable row level security;

-- To grant yourself dashboard access, run (replace the email):
--   update public.profiles set is_admin = true
--   where id = (select id from auth.users where email = 'you@example.com');
