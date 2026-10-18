-- Allow a signed-in user to update only their own saved-place note/metadata.
alter table public.saved_items enable row level security;
drop policy if exists "Users can update own saved items" on public.saved_items;
create policy "Users can update own saved items"
on public.saved_items
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
