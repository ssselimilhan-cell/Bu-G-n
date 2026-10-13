-- BUGÜN launch features: profile photos, saved-place notes, feedback and community activities.
alter table public.profiles add column if not exists avatar_url text;
alter table public.saved_items add column if not exists note text;
alter table public.places add column if not exists external_source text;
alter table public.places add column if not exists external_id text;
create unique index if not exists places_external_source_id_uq
  on public.places(external_source, external_id) where external_source is not null and external_id is not null;

create table if not exists public.app_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text,
  category text not null default 'Genel',
  message text not null check (char_length(trim(message)) between 5 and 4000),
  app_version text,
  status text not null default 'new' check (status in ('new','reviewing','answered','closed')),
  created_at timestamptz not null default now()
);
alter table public.app_feedback enable row level security;
drop policy if exists "Anyone can submit feedback" on public.app_feedback;
create policy "Anyone can submit feedback" on public.app_feedback
for insert to anon, authenticated with check (user_id is null or user_id = auth.uid());
drop policy if exists "Users can read own feedback" on public.app_feedback;
create policy "Users can read own feedback" on public.app_feedback
for select to authenticated using (user_id = auth.uid());

create table if not exists public.community_activities (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 3 and 120),
  description text not null default '' check (char_length(description) <= 3000),
  city text not null,
  venue text,
  address text,
  latitude double precision,
  longitude double precision,
  starts_at timestamptz not null,
  ends_at timestamptz,
  activity_type text not null default 'Diğer',
  capacity integer check (capacity is null or capacity between 2 and 500),
  estimated_cost numeric(10,2),
  is_free boolean not null default false,
  invite_code text not null unique default encode(gen_random_bytes(6), 'hex'),
  status text not null default 'open' check (status in ('open','cancelled','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists community_activities_city_date_idx
  on public.community_activities(city, starts_at) where status = 'open';
alter table public.community_activities enable row level security;
drop policy if exists "Public can read open community activities" on public.community_activities;
create policy "Public can read open community activities" on public.community_activities
for select to anon, authenticated using (status = 'open' and starts_at >= now() - interval '1 day');
drop policy if exists "Hosts can create own community activities" on public.community_activities;
create policy "Hosts can create own community activities" on public.community_activities
for insert to authenticated with check (auth.uid() = host_user_id);
drop policy if exists "Hosts can update own community activities" on public.community_activities;
create policy "Hosts can update own community activities" on public.community_activities
for update to authenticated using (auth.uid() = host_user_id) with check (auth.uid() = host_user_id);
drop policy if exists "Hosts can delete own community activities" on public.community_activities;
create policy "Hosts can delete own community activities" on public.community_activities
for delete to authenticated using (auth.uid() = host_user_id);

create table if not exists public.activity_invitations (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.community_activities(id) on delete cascade,
  inviter_user_id uuid not null references auth.users(id) on delete cascade,
  invitee_email text not null,
  invite_code text not null unique default encode(gen_random_bytes(8), 'hex'),
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  unique(activity_id, invitee_email)
);
create index if not exists activity_invitations_email_idx on public.activity_invitations(lower(invitee_email));
alter table public.activity_invitations enable row level security;
drop policy if exists "Inviters can create activity invitations" on public.activity_invitations;
create policy "Inviters can create activity invitations" on public.activity_invitations
for insert to authenticated with check (
  auth.uid() = inviter_user_id and exists (
    select 1 from public.community_activities a
    where a.id = activity_id and a.host_user_id = auth.uid()
  )
);
drop policy if exists "Inviters can read own activity invitations" on public.activity_invitations;
create policy "Inviters can read own activity invitations" on public.activity_invitations
for select to authenticated using (auth.uid() = inviter_user_id);

-- Public profile-photo bucket. Each signed-in user may only upload into their own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-avatars', 'profile-avatars', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];
drop policy if exists "Users upload own profile avatar" on storage.objects;
create policy "Users upload own profile avatar" on storage.objects
for insert to authenticated with check (
  bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "Users update own profile avatar" on storage.objects;
create policy "Users update own profile avatar" on storage.objects
for update to authenticated using (
  bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "Users delete own profile avatar" on storage.objects;
create policy "Users delete own profile avatar" on storage.objects
for delete to authenticated using (
  bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "Public can view profile avatars" on storage.objects;
create policy "Public can view profile avatars" on storage.objects
for select to anon, authenticated using (bucket_id = 'profile-avatars');
