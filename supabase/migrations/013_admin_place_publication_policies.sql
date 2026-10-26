-- Let administrators manage place publication status from the in-app admin panel.
-- Public users continue to see only active places via the existing public policy.
alter table public.places enable row level security;

drop policy if exists "Admins can read all places" on public.places;
create policy "Admins can read all places"
  on public.places
  for select
  to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can update places" on public.places;
create policy "Admins can update places"
  on public.places
  for update
  to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant select, update on public.places to authenticated;
