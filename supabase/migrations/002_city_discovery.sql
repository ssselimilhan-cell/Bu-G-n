-- =========================================================
-- BUGÜN - City Discovery / Business / AI foundation
-- Migration: 002_city_discovery.sql
-- =========================================================

-- =========================================================
-- 1. PLACES: Ankara keşif noktalarını zenginleştir
-- =========================================================

alter table public.places
  add column if not exists slug text,
  add column if not exists short_description text,
  add column if not exists place_type text,
  add column if not exists is_free boolean,
  add column if not exists visit_duration_min int,
  add column if not exists indoor boolean,
  add column if not exists outdoor boolean,
  add column if not exists parking_available boolean,
  add column if not exists kids_friendly boolean,
  add column if not exists pet_friendly boolean,
  add column if not exists difficulty_level text,
  add column if not exists best_time text,
  add column if not exists tags jsonb not null default '[]'::jsonb,
  add column if not exists is_active boolean not null default true;

create index if not exists places_city_category_idx
  on public.places(city, category);

create index if not exists places_active_idx
  on public.places(is_active);

create index if not exists places_slug_idx
  on public.places(slug);

-- =========================================================
-- 2. BUSINESSES: işletmeler
-- =========================================================

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),

  place_id uuid
    references public.places(id)
    on delete set null,

  name text not null,

  category text not null,

  description text,

  phone text,

  website text,

  instagram_url text,

  menu_url text,

  logo_url text,

  cover_image_url text,

  opening_hours jsonb not null default '{}'::jsonb,

  verified boolean not null default false,

  is_active boolean not null default true,

  owner_user_id uuid
    references auth.users(id)
    on delete set null,

  trust_score int not null default 50
    check (trust_score between 0 and 100),

  created_at timestamptz not null default now(),

  updated_at timestamptz not null default now()
);

create index if not exists businesses_place_idx
  on public.businesses(place_id);

create index if not exists businesses_category_idx
  on public.businesses(category);

create index if not exists businesses_active_idx
  on public.businesses(is_active);

create index if not exists businesses_owner_idx
  on public.businesses(owner_user_id);

-- =========================================================
-- 3. OFFERS: işletme kampanyaları
-- =========================================================

alter table public.offers
  add column if not exists business_id uuid
    references public.businesses(id)
    on delete cascade;

alter table public.offers
  add column if not exists price_before numeric(10,2);

alter table public.offers
  add column if not exists price_after numeric(10,2);

alter table public.offers
  add column if not exists conditions text;

alter table public.offers
  add column if not exists redemption_text text;

alter table public.offers
  add column if not exists featured boolean not null default false;

create index if not exists offers_business_idx
  on public.offers(business_id);

create index if not exists offers_active_time_idx
  on public.offers(is_active, starts_at, ends_at);

-- =========================================================
-- 4. PROFILES: AI önerileri için kullanıcı tercihleri
-- =========================================================

alter table public.profiles
  add column if not exists budget_level int;

alter table public.profiles
  add column if not exists preferred_radius_km numeric(6,2);

alter table public.profiles
  add column if not exists preferred_visit_duration_min int;

alter table public.profiles
  add column if not exists preferred_transport text;

alter table public.profiles
  add column if not exists ai_preferences jsonb
    not null default '{}'::jsonb;

-- =========================================================
-- 5. SAVED ITEMS: sorgulamayı hızlandıracak indeks
-- =========================================================

create index if not exists saved_items_entity_idx
  on public.saved_items(entity_type, entity_id);

-- =========================================================
-- 6. Örnek Ankara keşif noktaları
-- =========================================================

insert into public.places (
  name,
  slug,
  category,
  place_type,
  city,
  address,
  latitude,
  longitude,
  short_description,
  is_free,
  visit_duration_min,
  indoor,
  outdoor,
  parking_available,
  kids_friendly,
  pet_friendly,
  difficulty_level,
  best_time,
  tags,
  verified,
  trust_score,
  is_active
)
select
  v.name,
  v.slug,
  v.category,
  v.place_type,
  v.city,
  v.address,
  v.latitude,
  v.longitude,
  v.short_description,
  v.is_free,
  v.visit_duration_min,
  v.indoor,
  v.outdoor,
  v.parking_available,
  v.kids_friendly,
  v.pet_friendly,
  v.difficulty_level,
  v.best_time,
  v.tags::jsonb,
  v.verified,
  v.trust_score,
  v.is_active
from (
  values
  (
    'Eymir Gölü',
    'eymir-golu',
    'Doğa',
    'Göl',
    'Ankara',
    'ODTÜ Eymir Gölü, Gölbaşı, Ankara',
    39.8456::double precision,
    32.8267::double precision,
    'Doğa yürüyüşü, bisiklet ve göl çevresinde vakit geçirmek için popüler bir alan.',
    true,
    120,
    false,
    true,
    true,
    true,
    true,
    'Kolay',
    'Sabah, Gün Batımı',
    '["göl","yürüyüş","bisiklet","doğa","manzara"]',
    true,
    90,
    true
  ),
  (
    'Mogan Gölü',
    'mogan-golu',
    'Doğa',
    'Göl',
    'Ankara',
    'Gölbaşı, Ankara',
    39.7902::double precision,
    32.8055::double precision,
    'Göl çevresinde yürüyüş, piknik ve açık hava aktiviteleri için uygun alan.',
    true,
    120,
    false,
    true,
    true,
    true,
    true,
    'Kolay',
    'Sabah, Akşam',
    '["göl","piknik","yürüyüş","doğa","aile"]',
    true,
    90,
    true
  ),
  (
    'Kurtboğazı Barajı',
    'kurtbogazi-baraji',
    'Doğa',
    'Baraj',
    'Ankara',
    'Kurtboğazı, Ankara',
    40.1854::double precision,
    32.7484::double precision,
    'Doğa, göl manzarası ve sakin bir açık hava gezisi için seçenek.',
    true,
    150,
    false,
    true,
    true,
    true,
    true,
    'Kolay',
    'Sabah, Gün Batımı',
    '["baraj","göl","piknik","doğa","manzara"]',
    true,
    85,
    true
  ),
  (
    'Atatürk Orman Çiftliği',
    'ataturk-orman-ciftligi',
    'Doğa',
    'Park',
    'Ankara',
    'Atatürk Orman Çiftliği, Yenimahalle, Ankara',
    39.9417::double precision,
    32.8065::double precision,
    'Şehir içinde açık hava, yürüyüş ve aile aktiviteleri için geniş alan.',
    true,
    120,
    false,
    true,
    true,
    true,
    true,
    'Kolay',
    'Sabah, Akşam',
    '["park","aile","yürüyüş","doğa","piknik"]',
    true,
    90,
    true
  )
) as v(
  name,
  slug,
  category,
  place_type,
  city,
  address,
  latitude,
  longitude,
  short_description,
  is_free,
  visit_duration_min,
  indoor,
  outdoor,
  parking_available,
  kids_friendly,
  pet_friendly,
  difficulty_level,
  best_time,
  tags,
  verified,
  trust_score,
  is_active
)
where not exists (
  select 1
  from public.places p
  where p.slug = v.slug
);

-- =========================================================
-- 7. RLS - BUSINESSES
-- =========================================================

alter table public.businesses enable row level security;

drop policy if exists "Public can read active businesses"
on public.businesses;

create policy "Public can read active businesses"
on public.businesses
for select
to anon, authenticated
using (is_active = true);

-- =========================================================
-- 8. RLS - OFFERS
-- =========================================================

alter table public.offers enable row level security;

drop policy if exists "Public can read active offers"
on public.offers;

create policy "Public can read active offers"
on public.offers
for select
to anon, authenticated
using (
  is_active = true
  and (
    starts_at is null
    or starts_at <= now()
  )
  and (
    ends_at is null
    or ends_at >= now()
  )
);

-- =========================================================
-- 9. PLACES RLS
-- =========================================================

alter table public.places enable row level security;

drop policy if exists "Public can read places"
on public.places;

drop policy if exists "Public can read active places"
on public.places;

create policy "Public can read active places"
on public.places
for select
to anon, authenticated
using (is_active = true);