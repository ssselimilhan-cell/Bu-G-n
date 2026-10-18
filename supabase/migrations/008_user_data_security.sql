-- BUGÜN: reproducible per-user RLS for saves, interactions and reports.
-- This migration mirrors the account isolation policies required by the app.

alter table public.saved_items enable row level security;
drop policy if exists "Users can read own saved items" on public.saved_items;
create policy "Users can read own saved items" on public.saved_items
for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Users can create own saved items" on public.saved_items;
create policy "Users can create own saved items" on public.saved_items
for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Users can update own saved items" on public.saved_items;
create policy "Users can update own saved items" on public.saved_items
for update to authenticated using (auth.uid() = user_id)
with check (auth.uid() = user_id);
drop policy if exists "Users can delete own saved items" on public.saved_items;
create policy "Users can delete own saved items" on public.saved_items
for delete to authenticated using (auth.uid() = user_id);

alter table public.user_interactions enable row level security;
drop policy if exists "Users can read own interactions" on public.user_interactions;
create policy "Users can read own interactions" on public.user_interactions
for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Users can create own interactions" on public.user_interactions;
create policy "Users can create own interactions" on public.user_interactions
for insert to authenticated with check (auth.uid() = user_id);

alter table public.content_reports enable row level security;
drop policy if exists "Anyone can submit anonymous content reports" on public.content_reports;
create policy "Anyone can submit anonymous content reports" on public.content_reports
for insert to anon with check (user_id is null);
drop policy if exists "Users can submit own content reports" on public.content_reports;
create policy "Users can submit own content reports" on public.content_reports
for insert to authenticated with check (user_id is null or auth.uid() = user_id);

-- The client must never be granted write access to public event/place content.
