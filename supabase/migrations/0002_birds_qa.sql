-- ============================================================
-- Birds — community Q&A for the species study area
-- Run via: supabase db push  OR  paste into Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────
-- BIRD QUESTIONS
-- ─────────────────────────────────────────
create table public.bird_questions (
  id            uuid primary key default uuid_generate_v4(),
  author_id     uuid not null references public.profiles on delete cascade,
  title         text not null check (char_length(trim(title)) between 8 and 160),
  body          text not null check (char_length(trim(body)) between 20 and 5000),
  -- Slug from the in-app species catalogue; not a foreign key because the
  -- catalogue ships with the application rather than living in the database.
  species_slug  text,
  answer_count  integer not null default 0,
  created_at    timestamptz not null default now()
);

create index bird_questions_created_at_idx on public.bird_questions (created_at desc);
create index bird_questions_species_idx on public.bird_questions (species_slug) where species_slug is not null;

alter table public.bird_questions enable row level security;

-- The study area is public, so questions are readable without signing in
create policy "bird_questions: public read"
  on public.bird_questions for select
  to anon, authenticated
  using (true);

create policy "bird_questions: own insert"
  on public.bird_questions for insert
  to authenticated
  with check (author_id = auth.uid());

create policy "bird_questions: own update"
  on public.bird_questions for update
  to authenticated
  using (author_id = auth.uid())
  with check (author_id = auth.uid());

create policy "bird_questions: own delete"
  on public.bird_questions for delete
  to authenticated
  using (author_id = auth.uid());

-- ─────────────────────────────────────────
-- BIRD ANSWERS
-- ─────────────────────────────────────────
create table public.bird_answers (
  id           uuid primary key default uuid_generate_v4(),
  question_id  uuid not null references public.bird_questions on delete cascade,
  author_id    uuid not null references public.profiles on delete cascade,
  body         text not null check (char_length(trim(body)) between 10 and 5000),
  created_at   timestamptz not null default now()
);

create index bird_answers_question_idx on public.bird_answers (question_id, created_at);

alter table public.bird_answers enable row level security;

create policy "bird_answers: public read"
  on public.bird_answers for select
  to anon, authenticated
  using (true);

create policy "bird_answers: own insert"
  on public.bird_answers for insert
  to authenticated
  with check (author_id = auth.uid());

create policy "bird_answers: own update"
  on public.bird_answers for update
  to authenticated
  using (author_id = auth.uid())
  with check (author_id = auth.uid());

create policy "bird_answers: own delete"
  on public.bird_answers for delete
  to authenticated
  using (author_id = auth.uid());

-- ─────────────────────────────────────────
-- ANSWER COUNT — kept in sync by trigger so the
-- question list does not need a per-row aggregate
-- ─────────────────────────────────────────
create or replace function public.sync_bird_answer_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (tg_op = 'INSERT') then
    update public.bird_questions
       set answer_count = answer_count + 1
     where id = new.question_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.bird_questions
       set answer_count = greatest(answer_count - 1, 0)
     where id = old.question_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger bird_answers_count_sync
  after insert or delete on public.bird_answers
  for each row execute function public.sync_bird_answer_count();
