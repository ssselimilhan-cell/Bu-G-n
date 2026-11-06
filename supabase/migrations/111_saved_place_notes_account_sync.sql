-- Sync personal notes attached to saved places across the user's devices.
-- Apply with the other pending migrations before the combined release test.

create table if not exists public.saved_place_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id text not null,
  note text not null check (char_length(note) between 1 and 240),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint saved_place_notes_user_place_unique unique (user_id, place_id)
);

create index if not exists saved_place_notes_user_idx
  on public.saved_place_notes(user_id);

alter table public.saved_place_notes enable row level security;

drop policy if exists "Users can read own saved place notes" on public.saved_place_notes;
create policy "Users can read own saved place notes"
  on public.saved_place_notes for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create own saved place notes" on public.saved_place_notes;
create policy "Users can create own saved place notes"
  on public.saved_place_notes for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own saved place notes" on public.saved_place_notes;
create policy "Users can update own saved place notes"
  on public.saved_place_notes for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own saved place notes" on public.saved_place_notes;
create policy "Users can delete own saved place notes"
  on public.saved_place_notes for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.saved_place_notes to authenticated;
