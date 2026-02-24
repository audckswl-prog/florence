-- 1. Profiles (Nickname & Profile Image)
create table public.profiles (
  id uuid not null references auth.users(id) on delete cascade primary key,
  nickname text unique,
  profile_url text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);

-- 2. Friendships
create table public.friendships (
  id uuid not null default uuid_generate_v4() primary key,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  status text check (status in ('pending', 'accepted')) default 'pending',
  created_at timestamptz default now(),
  unique(requester_id, receiver_id)
);

alter table public.friendships enable row level security;
create policy "Users can view their own friendships" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = receiver_id);
create policy "Users can insert friendships" on public.friendships
  for insert with check (auth.uid() = requester_id);
create policy "Users can update their received friendships" on public.friendships
  for update using (auth.uid() = receiver_id);
create policy "Users can delete their own friendships" on public.friendships
  for delete using (auth.uid() = requester_id or auth.uid() = receiver_id);

-- 3. Notifications
create table public.notifications (
  id uuid not null default uuid_generate_v4() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete set null,
  type text check (type in ('friend_request', 'project_invite', 'project_started', 'page_milestone', 'project_success')) not null,
  message text,
  related_id uuid, -- For project UUID, or friendship UUID
  is_read boolean default false,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;
create policy "Users can view their notifications" on public.notifications
  for select using (auth.uid() = user_id);
create policy "Users can update their notifications (mark as read)" on public.notifications
  for update using (auth.uid() = user_id);
create policy "System/Anyone can insert notifications" on public.notifications
  for insert with check (true); -- Usually you restrict this via a database function, but for now we'll allow client side.

-- 4. Alter projects & project_members
alter table public.projects
  add column status text default 'pending_books' check (status in ('pending_books', 'in_progress', 'completed', 'failed')),
  add column start_date timestamptz,
  add column end_date timestamptz;

alter table public.project_members
  add column selected_isbn text references public.books(isbn) on delete set null;
