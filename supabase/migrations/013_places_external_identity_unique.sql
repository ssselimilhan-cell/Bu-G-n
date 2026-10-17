-- Keep the place collector's PostgREST upsert conflict target inferable.
-- A partial unique index on these columns cannot reliably be inferred by
-- on_conflict=external_source,external_id without a matching predicate.
-- PostgreSQL unique indexes permit multiple NULL pairs, so the non-partial
-- index preserves rows that do not have external identity fields.
create unique index if not exists places_external_source_id_key
  on public.places (external_source, external_id);

drop index if exists public.places_external_source_id_uq;
