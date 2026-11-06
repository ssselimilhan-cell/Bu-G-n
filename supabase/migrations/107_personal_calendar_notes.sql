-- Personal calendar notes. This migration is committed for the next app release;
-- it is intentionally not applied to the live Supabase project during development.
create table if not exists public.calendar_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  details text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  all_day boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint calendar_notes_valid_range check (ends_at is null or ends_at >= starts_at)
);

create index if not exists calendar_notes_user_date_idx
  on public.calendar_notes(user_id, starts_at);

alter table public.calendar_notes enable row level security;

drop policy if exists "Users can read own calendar notes" on public.calendar_notes;
create policy "Users can read own calendar notes"
  on public.calendar_notes for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create own calendar notes" on public.calendar_notes;
create policy "Users can create own calendar notes"
  on public.calendar_notes for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own calendar notes" on public.calendar_notes;
create policy "Users can update own calendar notes"
  on public.calendar_notes for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own calendar notes" on public.calendar_notes;
create policy "Users can delete own calendar notes"
  on public.calendar_notes for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.calendar_notes to authenticated;
