-- Admin-managed city food guide. Isolated feature branch migration; do not apply to production yet.
create table if not exists public.city_foods (
  id uuid primary key default gen_random_uuid(),
  city text not null,
  name text not null,
  short_description text,
  long_description text,
  where_to_eat text,
  venue_name text,
  venue_address text,
  map_url text,
  image_url text,
  sort_order integer not null check (sort_order between 1 and 5),
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint city_foods_city_sort_order_uq unique (city, sort_order) deferrable initially deferred
);
create index if not exists city_foods_city_active_order_idx on public.city_foods (lower(city), is_active, sort_order);
alter table public.city_foods enable row level security;
drop policy if exists "Public can read published city foods" on public.city_foods;
create policy "Public can read published city foods" on public.city_foods for select to anon, authenticated using (is_active = true);
drop policy if exists "Admins can read all city foods" on public.city_foods;
create policy "Admins can read all city foods" on public.city_foods for select to authenticated using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
drop policy if exists "Admins can insert city foods" on public.city_foods;
create policy "Admins can insert city foods" on public.city_foods for insert to authenticated with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
drop policy if exists "Admins can update city foods" on public.city_foods;
create policy "Admins can update city foods" on public.city_foods for update to authenticated using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
drop policy if exists "Admins can delete city foods" on public.city_foods;
create policy "Admins can delete city foods" on public.city_foods for delete to authenticated using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
grant select on public.city_foods to anon, authenticated;
grant insert, update, delete on public.city_foods to authenticated;

-- Allow administrators to swap two positions atomically without exposing temporary duplicate order values.
create or replace function public.swap_city_food_order(p_food_a uuid, p_food_b uuid)
returns void
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_city_a text;
  v_city_b text;
  v_order_a integer;
  v_order_b integer;
begin
  if (select auth.jwt() -> 'app_metadata' ->> 'role') is distinct from 'admin' then
    raise insufficient_privilege using message = 'Administrator access required';
  end if;

  select city, sort_order into v_city_a, v_order_a
  from public.city_foods where id = p_food_a for update;
  select city, sort_order into v_city_b, v_order_b
  from public.city_foods where id = p_food_b for update;

  if v_city_a is null or v_city_b is null or v_city_a <> v_city_b then
    raise exception 'Food records must exist in the same city';
  end if;

  update public.city_foods set sort_order = v_order_b, updated_at = now() where id = p_food_a;
  update public.city_foods set sort_order = v_order_a, updated_at = now() where id = p_food_b;
end;
$$;
revoke all on function public.swap_city_food_order(uuid, uuid) from public;
grant execute on function public.swap_city_food_order(uuid, uuid) to authenticated;
