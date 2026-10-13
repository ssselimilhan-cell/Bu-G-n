-- Harden maintenance RPC exposure and fix trigger-function search_path.
-- The expiry maintenance function is intended for trusted scheduled/server-side execution only.
REVOKE EXECUTE ON FUNCTION public.deactivate_expired_events() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.deactivate_expired_events() TO service_role;

-- Keep the trigger's object resolution deterministic.
ALTER FUNCTION public.set_place_location() SET search_path = public, pg_temp;
