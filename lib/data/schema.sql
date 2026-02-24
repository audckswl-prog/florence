-- Create a table for books
create table public.books (
  isbn text not null primary key,
  title text not null,
  author text,
  cover_url text,
  publisher text,
  category_name text,
  pub_date text,
  description text,
  link text,
  price_sales int,
  created_at timestamptz default now()
);

-- Create a table for user_books (linking users and books)
create table public.user_books (
  id uuid not null default uuid_generate_v4() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  isbn text not null references public.books(isbn) on delete cascade,
  status text check (status in ('reading', 'read', 'wish')),
  rating float4,
  read_pages int default 0,
  total_pages int,
  read_count int default 1,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz default now(),
  unique(user_id, isbn)
);

-- Enable Row Level Security (RLS)
alter table public.books enable row level security;
alter table public.user_books enable row level security;

-- Policies for books (Public read, Authenticated insert)
create policy "Books are viewable by everyone" on public.books
  for select using (true);

create policy "Users can insert books" on public.books
  for insert with check (auth.role() = 'authenticated');

-- Policies for user_books (Users can only see and modify their own data)
create policy "Users can view their own books" on public.user_books
  for select using (auth.uid() = user_id);

create policy "Users can insert their own books" on public.user_books
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own books" on public.user_books
  for update using (auth.uid() = user_id);

create policy "Users can delete their own books" on public.user_books
  for delete using (auth.uid() = user_id);

-- 3. Memos 테이블 생성
create table public.memos (
  id uuid not null default uuid_generate_v4() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  isbn text not null references public.books(isbn) on delete cascade,
  content text not null,
  image_url text, -- Supabase Storage URL
  page_number int,
  created_at timestamptz default now()
);

-- RLS for memos
alter table public.memos enable row level security;

create policy "Users can view their own memos" on public.memos
  for select using (auth.uid() = user_id);

create policy "Users can insert their own memos" on public.memos
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own memos" on public.memos
  for update using (auth.uid() = user_id);

create policy "Users can delete their own memos" on public.memos
  for delete using (auth.uid() = user_id);

-- 4. Projects 테이블 생성
create table public.projects (
  id uuid not null default uuid_generate_v4() primary key,
  name text not null,
  description text,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- 5. Project Members 테이블 생성 (N:N)
create table public.project_members (
  id uuid not null default uuid_generate_v4() primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text check (role in ('owner', 'member')) default 'member',
  reading_status text check (reading_status in ('reading', 'completed')) default 'reading',
  ai_question_count int default 0,
  receipt_url text,
  joined_at timestamptz default now(),
  unique(project_id, user_id)
);

-- 6. Project Books 테이블 생성 (프로젝트 대상 도서)
create table public.project_books (
  id uuid not null default uuid_generate_v4() primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  isbn text not null references public.books(isbn) on delete cascade,
  target_date timestamptz,
  created_at timestamptz default now()
);

-- 7. Project Invites 테이블 생성 (초대 딥링크용)
create table public.project_invites (
  id uuid not null default uuid_generate_v4() primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz default now()
);

-- 8. AI QnA Logs 테이블 생성 (Gemini 문답 아카이빙)
create table public.ai_qna_logs (
  id uuid not null default uuid_generate_v4() primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  question text not null,
  answer text not null,
  created_at timestamptz default now()
);

-- RLS for projects
alter table public.projects enable row level security;
alter table public.project_members enable row level security;
alter table public.project_books enable row level security;
alter table public.project_invites enable row level security;
alter table public.ai_qna_logs enable row level security;

-- Projects are viewable by everyone
create policy "Projects are viewable by everyone" on public.projects
  for select using (true);

create policy "Authenticated users can create projects" on public.projects
  for insert with check (auth.role() = 'authenticated');

-- Project Members policies
create policy "Project members are viewable by everyone" on public.project_members
  for select using (true);

create policy "Users can join projects" on public.project_members
  for insert with check (auth.role() = 'authenticated');

create policy "Users can update their own membership" on public.project_members
  for update using (auth.uid() = user_id);

-- Project Books policies
create policy "Project books are viewable by everyone" on public.project_books
  for select using (true);

create policy "Authenticated users can add books to projects" on public.project_books
  for insert with check (auth.role() = 'authenticated');

-- Project Invites policies
create policy "Project invites are viewable by everyone" on public.project_invites
  for select using (true);

create policy "Authenticated users can create invites" on public.project_invites
  for insert with check (auth.role() = 'authenticated');

-- AI QnA Logs policies
create policy "AI QnA logs are viewable by project members" on public.ai_qna_logs
  for select using (true);

create policy "Users can log their AI QnA" on public.ai_qna_logs
  for insert with check (auth.uid() = user_id);

-- AI Book Promotions
create table public.book_promotions (
  isbn text primary key,
  hook_title text not null,
  historical_background text not null,
  closing_question text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Book Promotions policies
create policy "Book promotions are viewable by everyone" on public.book_promotions
  for select using (true);
  
create policy "Authenticated users can create book promotions" on public.book_promotions
  for insert with check (auth.role() = 'authenticated');
