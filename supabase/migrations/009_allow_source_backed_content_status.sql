-- Distinguish content grounded in a source from AI-enriched content.
alter table public.places drop constraint if exists places_content_review_status_check;
alter table public.places add constraint places_content_review_status_check
  check (content_review_status in ('needs_review','verified','source_backed','stale','rejected'));
