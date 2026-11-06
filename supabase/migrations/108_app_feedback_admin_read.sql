-- Allow only administrators to read submitted user feedback.
-- Existing users may continue submitting feedback under the current INSERT policy.
alter table public.app_feedback enable row level security;

drop policy if exists "Admins can read all feedback" on public.app_feedback;
create policy "Admins can read all feedback"
  on public.app_feedback
  for select
  to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant select on public.app_feedback to authenticated;
