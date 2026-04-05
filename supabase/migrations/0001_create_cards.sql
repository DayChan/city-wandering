-- 启用 UUID 扩展
create extension if not exists "uuid-ossp";

-- cards 表
create table public.cards (
  id          uuid        primary key default uuid_generate_v4(),
  title       text        not null,
  difficulty  smallint    not null check (difficulty between 1 and 3),
  theme       text        not null check (theme in ('food','architecture','culture','nature','color-walk','random')),
  city        text        not null default 'universal',
  hint        text        not null,
  is_active   boolean     not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 索引
create index idx_cards_theme      on public.cards (theme)      where is_active = true;
create index idx_cards_city       on public.cards (city)       where is_active = true;
create index idx_cards_difficulty on public.cards (difficulty) where is_active = true;
create index idx_cards_theme_city on public.cards (theme, city) where is_active = true;

-- 自动更新 updated_at
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger cards_updated_at
  before update on public.cards
  for each row execute function update_updated_at();

-- RLS：匿名只读
alter table public.cards enable row level security;

create policy "cards_public_read"
  on public.cards for select
  to anon, authenticated
  using (is_active = true);
