-- check_ins 表
create table public.check_ins (
  id         uuid        primary key default uuid_generate_v4(),
  user_id    uuid        not null references auth.users(id) on delete cascade,
  card_id    uuid        not null references public.cards(id),
  photo_url  text,
  note       text,
  created_at timestamptz not null default now()
);

create index idx_check_ins_user_id on public.check_ins (user_id);
create index idx_check_ins_card_id on public.check_ins (card_id);
create index idx_check_ins_created_at on public.check_ins (created_at desc);

-- RLS：只能读/写自己的打卡记录
alter table public.check_ins enable row level security;

create policy "check_ins_select_own"
  on public.check_ins for select
  to authenticated
  using (auth.uid() = user_id);

create policy "check_ins_insert_own"
  on public.check_ins for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "check_ins_delete_own"
  on public.check_ins for delete
  to authenticated
  using (auth.uid() = user_id);

-- Storage bucket：check-in-photos
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'check-in-photos',
  'check-in-photos',
  true,
  10485760,  -- 10MB
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do nothing;

-- Storage RLS：登录用户可上传到自己的目录，所有人可读
create policy "check_in_photos_upload"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'check-in-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "check_in_photos_read"
  on storage.objects for select
  to public
  using (bucket_id = 'check-in-photos');

create policy "check_in_photos_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'check-in-photos' and (storage.foldername(name))[1] = auth.uid()::text);
