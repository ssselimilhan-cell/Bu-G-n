alter table public.activity_participants
  drop constraint if exists activity_participants_status_check;

alter table public.activity_participants
  add constraint activity_participants_status_check
  check (status in ('going', 'maybe', 'declined', 'cancelled'));
