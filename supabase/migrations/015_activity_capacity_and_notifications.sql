-- Server-side capacity enforcement for community activity RSVPs.
create table if not exists public.activity_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  activity_id uuid not null references public.community_activities(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  kind text not null check (kind in ('going','maybe','declined')),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index if not exists activity_notifications_recipient_idx
  on public.activity_notifications(recipient_user_id, created_at desc);
alter table public.activity_notifications enable row level security;
drop policy if exists "Users read own activity notifications" on public.activity_notifications;
create policy "Users read own activity notifications" on public.activity_notifications
for select to authenticated using (recipient_user_id = auth.uid());
drop policy if exists "Users update own activity notifications" on public.activity_notifications;
create policy "Users update own activity notifications" on public.activity_notifications
for update to authenticated using (recipient_user_id = auth.uid())
with check (recipient_user_id = auth.uid());
grant select, update on public.activity_notifications to authenticated;

create or replace function public.enforce_activity_capacity()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  activity public.community_activities%rowtype;
  attendee_count integer;
begin
  select * into activity from public.community_activities
    where id = new.activity_id for update;
  if not found or activity.status <> 'open' or activity.starts_at <= now() then
    raise exception 'Etkinlik kapalı veya başlamış.';
  end if;
  if new.status in ('going','maybe') and
     (tg_op = 'INSERT' or old.status not in ('going','maybe')) then
    select count(*) into attendee_count from public.activity_participants
      where activity_id = new.activity_id and status in ('going','maybe')
        and (tg_op <> 'UPDATE' or user_id <> new.user_id);
    if activity.capacity is not null and attendee_count >= activity.capacity then
      raise exception 'Etkinliğin kişi sınırı doldu.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists activity_capacity_guard on public.activity_participants;
create trigger activity_capacity_guard
before insert or update of status on public.activity_participants
for each row execute function public.enforce_activity_capacity();

create or replace function public.notify_activity_host_of_response()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  host_id uuid;
begin
  if new.status not in ('going','maybe','declined') then return new; end if;
  if tg_op = 'UPDATE' and old.status = new.status then return new; end if;
  select host_user_id into host_id from public.community_activities where id = new.activity_id;
  if host_id is not null and host_id <> new.user_id then
    insert into public.activity_notifications(recipient_user_id, activity_id, actor_user_id, kind)
      values (host_id, new.activity_id, new.user_id, new.status);
  end if;
  return new;
end;
$$;
drop trigger if exists activity_response_notification on public.activity_participants;
create trigger activity_response_notification
after insert or update of status on public.activity_participants
for each row execute function public.notify_activity_host_of_response();
