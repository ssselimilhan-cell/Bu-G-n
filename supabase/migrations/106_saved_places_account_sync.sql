-- Keep saved places attached to the authenticated account, not only the device.
alter table public.saved_items enable row level security;

drop policy if exists "Users can read own saved items" on public.saved_items;
create policy "Users can read own saved items"
on public.saved_items
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can save items to own account" on public.saved_items;
create policy "Users can save items to own account"
on public.saved_items
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can remove own saved items" on public.saved_items;
create policy "Users can remove own saved items"
on public.saved_items
for delete
to authenticated
using (auth.uid() = user_id);

create index if not exists saved_items_user_type_idx
on public.saved_items(user_id, entity_type);
