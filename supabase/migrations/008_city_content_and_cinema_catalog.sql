-- Add source-backed place enrichment and lawful cinema catalogue tables.
alter table public.places
  add column if not exists long_description text,
  add column if not exists source_url text,
  add column if not exists verified_at timestamptz,
  add column if not exists content_updated_at timestamptz,
  add column if not exists content_review_status text not null default 'needs_review'
    check (content_review_status in ('needs_review','verified','stale','rejected'));

create index if not exists places_city_active_name_idx
  on public.places (lower(city), is_active, name);

create table if not exists public.cinema_venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text not null,
  address text,
  latitude double precision,
  longitude double precision,
  website text,
  source_url text,
  external_source text not null,
  external_id text not null,
  is_active boolean not null default true,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (external_source, external_id)
);

create table if not exists public.cinema_movies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  original_title text,
  overview text,
  genre_names text[] not null default '{}',
  runtime_minutes integer,
  age_rating text,
  poster_url text,
  trailer_url text,
  release_date date,
  source_url text,
  external_source text not null,
  external_id text not null,
  is_active boolean not null default true,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (external_source, external_id)
);

create table if not exists public.cinema_screenings (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.cinema_venues(id) on delete cascade,
  movie_id uuid not null references public.cinema_movies(id) on delete cascade,
  starts_at timestamptz not null,
  language text,
  format text,
  ticket_url text,
  source_url text not null,
  external_source text not null,
  external_id text not null,
  is_active boolean not null default true,
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (external_source, external_id)
);

create index if not exists cinema_venues_city_active_idx
  on public.cinema_venues (lower(city), is_active);
create index if not exists cinema_movies_release_idx
  on public.cinema_movies (release_date desc) where is_active;
create index if not exists cinema_screenings_venue_time_idx
  on public.cinema_screenings (venue_id, starts_at) where is_active;
create index if not exists cinema_screenings_movie_time_idx
  on public.cinema_screenings (movie_id, starts_at) where is_active;

alter table public.cinema_venues enable row level security;
alter table public.cinema_movies enable row level security;
alter table public.cinema_screenings enable row level security;

drop policy if exists "Public can read active cinema venues" on public.cinema_venues;
create policy "Public can read active cinema venues"
  on public.cinema_venues for select to anon, authenticated using (is_active);
drop policy if exists "Public can read active cinema movies" on public.cinema_movies;
create policy "Public can read active cinema movies"
  on public.cinema_movies for select to anon, authenticated using (is_active);
drop policy if exists "Public can read active cinema screenings" on public.cinema_screenings;
create policy "Public can read active cinema screenings"
  on public.cinema_screenings for select to anon, authenticated using (is_active);

grant select on public.cinema_venues, public.cinema_movies, public.cinema_screenings to anon, authenticated;
