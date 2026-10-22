-- BUGÜN core features: city offers and invitation events
-- Admin identity is set only by Supabase Auth app_metadata.role = 'admin'.
alter table public.offers add column if not exists city text;
alter table public.offers add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.offers add column if not exists updated_at timestamptz not null default now();

update public.offers o
set city = p.city
from public.places p
where o.place_id = p.id and (o.city is null or btrim(o.city) = '');

create index if not exists offers_city_active_idx
  on public.offers(city, is_active, starts_at, ends_at);

alter table public.offers enable row level security;
drop policy if exists "Public can read active offers" on public.offers;
create policy "Public can read active offers"
  on public.offers for select to anon, authenticated
  using (is_active = true and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at >= now()));

drop policy if exists "Only admins can insert offers" on public.offers;
create policy "Only admins can insert offers"
  on public.offers for insert to authenticated
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin' and created_by = auth.uid());

drop policy if exists "Only admins can update offers" on public.offers;
create policy "Only admins can update offers"
  on public.offers for update to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Only admins can delete offers" on public.offers;
create policy "Only admins can delete offers"
  on public.offers for delete to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create table if not exists public.community_events (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 3 and 100),
  city text not null,
  starts_at timestamptz not null,
  meeting_point text,
  description text,
  invite_code text not null unique,
  created_at timestamptz not null default now()
);
create index if not exists community_events_city_date_idx on public.community_events(city, starts_at);
alter table public.community_events enable row level security;
drop policy if exists "Signed-in users can read community events" on public.community_events;
create policy "Signed-in users can read community events"
  on public.community_events for select to authenticated using (true);
drop policy if exists "Users create own community events" on public.community_events;
create policy "Users create own community events"
  on public.community_events for insert to authenticated with check (creator_id = auth.uid());
drop policy if exists "Creators update own community events" on public.community_events;
create policy "Creators update own community events"
  on public.community_events for update to authenticated using (creator_id = auth.uid()) with check (creator_id = auth.uid());
drop policy if exists "Creators delete own community events" on public.community_events;
create policy "Creators delete own community events"
  on public.community_events for delete to authenticated using (creator_id = auth.uid());
