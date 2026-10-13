-- Community activity attendance and invite-code joining.
create table if not exists public.activity_participants (
  activity_id uuid not null references public.community_activities(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'going' check (status in ('going','cancelled')),
  created_at timestamptz not null default now(),
  primary key(activity_id, user_id)
);
create index if not exists activity_participants_user_idx on public.activity_participants(user_id, created_at desc);
alter table public.activity_participants enable row level security;
drop policy if exists "Users can read own participation and hosts can see attendees" on public.activity_participants;
create policy "Users can read own participation and hosts can see attendees"
on public.activity_participants for select to authenticated
using (
  auth.uid() = user_id or exists (
    select 1 from public.community_activities a
    where a.id = activity_id and a.host_user_id = auth.uid()
  )
);
drop policy if exists "Users can join open future activities" on public.activity_participants;
create policy "Users can join open future activities"
on public.activity_participants for insert to authenticated
with check (
  auth.uid() = user_id and exists (
    select 1 from public.community_activities a
    where a.id = activity_id and a.status = 'open' and a.starts_at > now()
  )
);
drop policy if exists "Users can update own participation" on public.activity_participants;
create policy "Users can update own participation"
on public.activity_participants for update to authenticated
using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Users can leave activities" on public.activity_participants;
create policy "Users can leave activities"
on public.activity_participants for delete to authenticated
using (auth.uid() = user_id);
grant select, insert, update, delete on public.activity_participants to authenticated;
