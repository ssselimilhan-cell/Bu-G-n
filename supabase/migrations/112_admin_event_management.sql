-- Admin-managed event lifecycle and featured placement.
-- External feed records remain distinguishable and cannot be deleted from the app UI.
alter table public.events add column if not exists admin_managed boolean not null default false;
alter table public.events add column if not exists is_featured boolean not null default false;
create index if not exists events_featured_city_active_start_idx
  on public.events (is_featured desc, city, starts_at) where is_active = true;

drop policy if exists "Admins can read all events" on public.events;
create policy "Admins can read all events" on public.events for select to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can insert managed events" on public.events;
create policy "Admins can insert managed events" on public.events for insert to authenticated
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
    and admin_managed = true and source_id is null and external_id is null);

drop policy if exists "Admins can update events" on public.events;
create policy "Admins can update events" on public.events for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can delete managed events" on public.events;
create policy "Admins can delete managed events" on public.events for delete to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin' and admin_managed = true);

grant select, insert, update, delete on public.events to authenticated;
