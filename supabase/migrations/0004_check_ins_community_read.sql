-- 允许登录用户读取所有人的打卡记录（社区广场）
create policy "check_ins_select_community"
  on public.check_ins for select
  to authenticated
  using (true);
