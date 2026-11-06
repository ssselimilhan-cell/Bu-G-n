-- Permit BUGÜN administrators to moderate all user-created community events.
-- Existing creator policies remain active; creators retain their own edit/delete rights.
-- The current authenticated SELECT policy already allows the admin screen to list events.
drop policy if exists "Admins can update all community events" on public.community_events;
create policy "Admins can update all community events"
  on public.community_events
  for update
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can delete all community events" on public.community_events;
create policy "Admins can delete all community events"
  on public.community_events
  for delete
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant update, delete on public.community_events to authenticated;
