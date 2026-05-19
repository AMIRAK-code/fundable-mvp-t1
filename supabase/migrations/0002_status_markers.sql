-- ============================================================
-- 0002 — Status markers for startups and investors
-- Run via: Supabase SQL Editor (Database → SQL → New query)
-- ============================================================

-- Founder/startup product status (current product/company state)
alter table public.startups
  add column if not exists status text
  check (
    status is null
    or status in (
      'idea',
      'pre_seed',
      'mvp',
      'pre_launch',
      'launched',
      'scaling',
      'profitable'
    )
  );

-- Investor availability status (current openness to deals)
alter table public.investor_details
  add column if not exists status text
  check (
    status is null
    or status in (
      'looking',
      'reviewing',
      'invested',
      'advisory',
      'closed'
    )
  );
