-- user_badges 表：记录用户已解锁的徽章
create table public.user_badges (
  id         uuid        primary key default uuid_generate_v4(),
  user_id    uuid        not null references auth.users(id) on delete cascade,
  badge_id   text        not null,
  earned_at  timestamptz not null default now(),
  unique (user_id, badge_id)
);

create index idx_user_badges_user_id on public.user_badges (user_id);

-- RLS：只能读写自己的徽章
alter table public.user_badges enable row level security;

create policy "user_badges_select_own"
  on public.user_badges for select
  to authenticated
  using (auth.uid() = user_id);

create policy "user_badges_insert_own"
  on public.user_badges for insert
  to authenticated
  with check (auth.uid() = user_id);
