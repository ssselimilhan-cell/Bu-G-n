create extension if not exists postgis;
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  city text not null default 'Ankara',
  interests jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  source_type text not null check (source_type in ('official','ticketing','business','community','news','user')),
  base_url text,
  trust_score int not null default 50 check (trust_score between 0 and 100),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  city text not null default 'Ankara',
  address text,
  latitude double precision,
  longitude double precision,
  location geography(point,4326),
  phone text,
  website text,
  image_url text,
  rating numeric(3,2),
  price_level int,
  verified boolean not null default false,
  trust_score int not null default 50 check (trust_score between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists places_location_gix on places using gist(location);

create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references sources(id),
  place_id uuid references places(id),
  title text not null,
  description text,
  category text not null,
  subcategory text,
  city text not null default 'Ankara',
  starts_at timestamptz not null,
  ends_at timestamptz,
  price_min numeric(10,2),
  price_max numeric(10,2),
  ticket_url text,
  source_url text,
  image_url text,
  trust_score int not null default 50 check (trust_score between 0 and 100),
  popularity_score numeric(8,3) not null default 0,
  recommendation_score numeric(8,3) not null default 0,
  is_active boolean not null default true,
  fingerprint text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists events_fingerprint_uq on events(fingerprint) where fingerprint is not null;
create index if not exists events_city_time_idx on events(city, starts_at) where is_active = true;

create table if not exists offers (
  id uuid primary key default gen_random_uuid(),
  place_id uuid references places(id) on delete cascade,
  title text not null,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  discount_text text,
  source_id uuid references sources(id),
  source_url text,
  trust_score int not null default 50 check (trust_score between 0 and 100),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists user_interactions (
  id bigint generated always as identity primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  entity_type text not null check (entity_type in ('event','place','offer','news','activity')),
  entity_id uuid not null,
  action text not null check (action in ('view','save','share','navigate','ticket_click','hide')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists interactions_user_time_idx on user_interactions(user_id, created_at desc);

create table if not exists saved_items (
  user_id uuid not null references profiles(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  created_at timestamptz not null default now(),
  primary key(user_id, entity_type, entity_id)
);

create table if not exists content_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  entity_type text not null,
  entity_id uuid not null,
  reason text not null,
  status text not null default 'open' check (status in ('open','reviewing','resolved','rejected')),
  created_at timestamptz not null default now()
);
