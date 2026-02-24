-- 1. Profiles 테이블 생성
create table public.profiles (
  id uuid not null references auth.users(id) on delete cascade primary key,
  nickname text unique not null,
  profile_url text,
  created_at timestamptz default now()
);

-- RLS for profiles
alter table public.profiles enable row level security;
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id);

-- 2. Friendships 테이블 생성
create table public.friendships (
  id uuid not null default uuid_generate_v4() primary key,
  requester_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text check (status in ('pending', 'accepted', 'rejected')) default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(requester_id, receiver_id)
);

-- RLS for friendships
alter table public.friendships enable row level security;
create policy "Users can view their friendships" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = receiver_id);
create policy "Users can insert friendships" on public.friendships
  for insert with check (auth.uid() = requester_id);
create policy "Users can update their friendships" on public.friendships
  for update using (auth.uid() = requester_id or auth.uid() = receiver_id);
create policy "Users can delete their friendships" on public.friendships
  for delete using (auth.uid() = requester_id or auth.uid() = receiver_id);

-- 3. Notifications 테이블 생성
create table public.notifications (
  id uuid not null default uuid_generate_v4() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete set null,
  type text not null,
  message text not null,
  is_read boolean default false,
  related_id uuid, -- Can be project_id, friendship_id, etc.
  created_at timestamptz default now()
);

-- RLS for notifications
alter table public.notifications enable row level security;
create policy "Users can view their own notifications" on public.notifications
  for select using (auth.uid() = user_id);
create policy "Authenticated users can create notifications" on public.notifications
  for insert with check (auth.role() = 'authenticated' and (sender_id is null or sender_id = auth.uid()));
create policy "Users can update their own notifications" on public.notifications
  for update using (auth.uid() = user_id);
create policy "Users can delete their own notifications" on public.notifications
  for delete using (auth.uid() = user_id);
