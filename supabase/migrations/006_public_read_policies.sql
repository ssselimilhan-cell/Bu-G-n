-- BUGÜN - public read access for client-side content
-- The Flutter app uses the Supabase publishable/anon key, so public content
-- must be readable through RLS without requiring a logged-in user.

alter table public.events enable row level security;

DROP POLICY IF EXISTS "Public can read active events" ON public.events;
CREATE POLICY "Public can read active events"
ON public.events
FOR SELECT
TO anon, authenticated
USING (is_active = true);

alter table public.places enable row level security;

DROP POLICY IF EXISTS "Public can read places" ON public.places;
DROP POLICY IF EXISTS "Public can read active places" ON public.places;
CREATE POLICY "Public can read active places"
ON public.places
FOR SELECT
TO anon, authenticated
USING (is_active = true);
