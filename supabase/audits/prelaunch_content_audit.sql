-- BUGÜN pre-launch content audit (read-only; does not modify live data)
-- Run in Supabase SQL Editor before each release candidate.
-- Review outliers manually before deactivating or deleting any records.

-- 1) Active events with implausibly distant start dates (investigate; do not auto-delete).
select
  id, city, title, category, starts_at, source_url, ticket_url,
  external_source, external_id, last_synced_at
from public.events
where is_active = true
  and starts_at >= now() + interval '2 years'
order by starts_at;

-- 2) Active events whose start time has passed (some may be multi-day; review first).
select
  id, city, title, starts_at, ends_at, source_url,
  external_source, external_id, last_synced_at
from public.events
where is_active = true
  and coalesce(ends_at, starts_at) < now()
order by starts_at desc
limit 250;

-- 3) Active events without a verifiable source URL.
select
  id, city, title, starts_at, external_source, external_id, source_id
from public.events
where is_active = true
  and nullif(trim(source_url), '') is null
order by starts_at;

-- 4) Current and next-31-day event coverage by city.
select
  city,
  count(*) filter (
    where is_active
      and starts_at >= date_trunc('day', now())
      and starts_at < date_trunc('day', now()) + interval '1 day'
  )::int as today_count,
  count(*) filter (
    where is_active
      and starts_at >= now()
      and starts_at < now() + interval '31 days'
  )::int as next_31_days_count,
  max(last_synced_at) as last_synced_at
from public.events
group by city
order by next_31_days_count desc, city;

-- 5) Place coverage by city and review status.
select city, content_review_status, count(*)::int as total
from public.places
where is_active
group by city, content_review_status
order by city, content_review_status;
