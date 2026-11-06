-- Allow administrators to manage feedback status and remove individual records.
-- This migration is committed to the feature branch only; it is not applied to production.
drop policy if exists "Admins can update feedback" on public.app_feedback;
create policy "Admins can update feedback"
  on public.app_feedback
  for update
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "Admins can delete feedback" on public.app_feedback;
create policy "Admins can delete feedback"
  on public.app_feedback
  for delete
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant update (status) on public.app_feedback to authenticated;
grant delete on public.app_feedback to authenticated;
