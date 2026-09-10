alter table public.events
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

create index if not exists events_coordinates_idx
  on public.events(latitude, longitude);
