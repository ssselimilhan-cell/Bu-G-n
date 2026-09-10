alter table events
  add column if not exists external_id text,
  add column if not exists external_source text,
  add column if not exists venue_name text,
  add column if not exists venue_address text,
  add column if not exists last_synced_at timestamptz;

create unique index if not exists events_external_source_id_uq
  on events(external_source, external_id)
  where external_source is not null
    and external_id is not null;

create index if not exists events_external_source_idx
  on events(external_source);

create index if not exists events_last_synced_idx
  on events(last_synced_at);

delete from sources
where name = 'Ticketmaster';

insert into sources (
  name,
  source_type,
  base_url,
  trust_score,
  is_active
)
values (
  'Ticketmaster',
  'ticketing',
  'https://www.ticketmaster.com/',
  95,
  true
);
