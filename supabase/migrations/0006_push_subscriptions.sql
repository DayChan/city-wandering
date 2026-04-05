-- push_subscriptions：存储用户的 Web Push 订阅
create table public.push_subscriptions (
  id         uuid        primary key default uuid_generate_v4(),
  user_id    uuid        not null references auth.users(id) on delete cascade,
  endpoint   text        not null,
  p256dh     text        not null,
  auth_key   text        not null,
  created_at timestamptz not null default now(),
  unique (endpoint)
);

create index idx_push_subscriptions_user_id on public.push_subscriptions (user_id);

alter table public.push_subscriptions enable row level security;

-- 用户只能读写自己的订阅
create policy "push_subs_select_own"
  on public.push_subscriptions for select
  to authenticated
  using (auth.uid() = user_id);

create policy "push_subs_insert_own"
  on public.push_subscriptions for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "push_subs_delete_own"
  on public.push_subscriptions for delete
  to authenticated
  using (auth.uid() = user_id);
