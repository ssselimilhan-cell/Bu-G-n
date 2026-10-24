-- Correctly allow a participant to change to declined even if an event has since closed,
-- while enforcing open/future status and capacity for new going/maybe responses.
create or replace function public.enforce_activity_capacity()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  activity public.community_activities%rowtype;
  attendee_count integer;
  entering_attending boolean := false;
begin
  if tg_op = 'INSERT' then
    entering_attending := new.status in ('going', 'maybe');
  elsif new.status in ('going', 'maybe') then
    entering_attending := old.status not in ('going', 'maybe');
  end if;

  if not entering_attending then
    return new;
  end if;

  select * into activity from public.community_activities
    where id = new.activity_id for update;
  if not found or activity.status <> 'open' or activity.starts_at <= now() then
    raise exception 'Etkinlik kapalı veya başlamış.';
  end if;

  select count(*) into attendee_count
    from public.activity_participants
    where activity_id = new.activity_id
      and status in ('going', 'maybe')
      and (tg_op <> 'UPDATE' or user_id <> new.user_id);

  if activity.capacity is not null and attendee_count >= activity.capacity then
    raise exception 'Etkinliğin kişi sınırı doldu.';
  end if;
  return new;
end;
$$;
