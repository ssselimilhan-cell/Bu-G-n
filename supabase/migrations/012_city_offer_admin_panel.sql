-- BUGÜN: yönetici paneli için şehir bazlı reklam kampanyaları
alter table public.offers add column if not exists advertiser_name text;
alter table public.offers add column if not exists image_url text;

create index if not exists offers_city_schedule_idx
  on public.offers (city, starts_at, ends_at, is_active);

-- Admins can view drafts and inactive campaigns; public users still only see
-- campaigns allowed by the existing active/date policy.
drop policy if exists "Admins can read all offers" on public.offers;
create policy "Admins can read all offers"
  on public.offers for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant select, insert, update, delete on public.offers to authenticated;
