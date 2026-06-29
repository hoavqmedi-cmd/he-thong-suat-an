-- ============================================================
--  VAI TRÒ & NGƯỜI DÙNG — Đăng nhập bằng GOOGLE (Supabase Auth)
--  Hệ thống suất ăn Nhi Đồng 1
--  Dán toàn bộ vào: Supabase → SQL Editor → Run
-- ============================================================
--  ĐIỀU KIỆN TRƯỚC KHI CHẠY:
--    Authentication → Providers → bật GOOGLE (điền Client ID/Secret).
--  CƠ CHẾ:
--    • KHÔNG QUẢN LÝ MẬT KHẨU — không có cột mật khẩu; Google lo xác thực.
--    • Admin nhập trước Gmail được phép vào bảng tai_khoan_cho_phep
--      (kèm vai trò). Khi người đó "Đăng nhập Google" lần đầu, Supabase
--      tạo dòng auth.users → trigger tạo hồ sơ nguoi_dung và:
--         - nếu Gmail có trong danh sách cho phép → gán vai trò + BẬT ngay;
--         - nếu KHÔNG có → tạo hồ sơ chờ (trang_thai=false) để admin duyệt.
-- ============================================================

-- ------------------------------------------------------------
-- 1) VAI TRÒ (7 vai trò cố định)
-- ------------------------------------------------------------
create table if not exists vai_tro (
  ma      text primary key,          -- 'admin','kdd','khoa',...
  ten     text not null,
  mo_ta   text,
  thu_tu  int
);

insert into vai_tro (ma, ten, mo_ta, thu_tu) values
  ('admin',      'Admin',            'Quản trị — tổng hoặc phụ (theo cap_quan_tri)', 1),
  ('kdd',        'KDD',              'Khoa Dinh Dưỡng — duyệt & gửi sản xuất',       2),
  ('khoa',       'Khoa lâm sàng',    'Đăng ký suất theo bệnh nhân',                  3),
  ('bep_dv',     'Bếp dịch vụ',      'Sản xuất cơm/cháo dịch vụ',                    4),
  ('bep_benh_ly','Bếp bệnh lý',      'Sản xuất cơm/cháo bệnh lý',                    5),
  ('sua_soup',   'Phòng sữa - soup', 'Pha sữa, nấu soup sonde',                      6),
  ('giao',       'Người giao',       'Giao suất tới giường bệnh',                    7)
on conflict (ma) do update
  set ten=excluded.ten, mo_ta=excluded.mo_ta, thu_tu=excluded.thu_tu;

-- ------------------------------------------------------------
-- 2) BỘ PHẬN SẢN XUẤT (phạm vi cho Admin phụ + nhân sự)
-- ------------------------------------------------------------
create table if not exists dm_bo_phan (
  ma   text primary key,             -- 'bep_dv','bep_benh_ly','sua_soup'
  ten  text not null
);
insert into dm_bo_phan (ma, ten) values
  ('bep_dv',      'Bếp phòng dịch vụ'),
  ('bep_benh_ly', 'Bếp cơm bệnh lý'),
  ('sua_soup',    'Phòng sữa - soup')
on conflict (ma) do nothing;

-- ------------------------------------------------------------
-- 2b) DANH MỤC KHU VỰC GIAO (gom nhiều khoa) + GÁN KHOA
--     1 khu vực = 1 nhóm khoa để người giao phụ trách.
-- ------------------------------------------------------------
create table if not exists dm_khu_vuc (
  ma      text primary key,          -- 'KV_A','KV_B','KV_C'
  ten     text not null,
  thu_tu  int
);
insert into dm_khu_vuc (ma, ten, thu_tu) values
  ('KV_A', 'Khu A', 1),
  ('KV_B', 'Khu B', 2),
  ('KV_C', 'Khu C', 3)
on conflict (ma) do update set ten=excluded.ten, thu_tu=excluded.thu_tu;

-- Gắn khoa vào khu vực: thêm cột khu_vuc cho dm_khoa (đã tạo ở danh-muc.sql)
alter table dm_khoa add column if not exists khu_vuc text references dm_khu_vuc(ma);

-- Gán mặc định (admin chỉnh lại sau): K01–K07=A, K08–K14=B, K15–K21=C
update dm_khoa set khu_vuc='KV_A' where ma in ('K01','K02','K03','K04','K05','K06','K07');
update dm_khoa set khu_vuc='KV_B' where ma in ('K08','K09','K10','K11','K12','K13','K14');
update dm_khoa set khu_vuc='KV_C' where ma in ('K15','K16','K17','K18','K19','K20','K21');

-- ------------------------------------------------------------
-- 3) NGƯỜI DÙNG (hồ sơ gắn với tài khoản Google)
--    id = auth.users.id (uuid) — KHÔNG có cột mật khẩu.
-- ------------------------------------------------------------
create table if not exists nguoi_dung (
  id            uuid primary key references auth.users(id) on delete cascade,
  email         text unique not null,
  ho_ten        text,
  vai_tro       text references vai_tro(ma),                 -- null = chờ admin gán
  bo_phan       text,                                        -- ma dm_bo_phan HOẶC ma dm_khoa (phạm vi phụ trách)
  khu_vuc       text,                                        -- khu vực MẶC ĐỊNH của người giao (tham khảo); phân công thực tế theo ngày/ca ở phan_cong_giao
  cap_quan_tri  text check (cap_quan_tri in ('tong','phu')), -- chỉ dùng khi vai_tro='admin'
  trang_thai    boolean not null default false,             -- false = chưa kích hoạt
  ghi_chu       text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index if not exists idx_nd_vaitro on nguoi_dung(vai_tro);
create index if not exists idx_nd_bophan on nguoi_dung(bo_phan);

-- tự cập nhật updated_at khi sửa
create or replace function fn_touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists trg_nd_touch on nguoi_dung;
create trigger trg_nd_touch before update on nguoi_dung
  for each row execute function fn_touch_updated_at();

-- ------------------------------------------------------------
-- 3b) PHÂN CÔNG NGƯỜI GIAO — ĐỔI CA THEO NGÀY
--     Mỗi (ngày, ca, khu vực) gán 1 người giao. Khác ngày/ca có thể
--     đổi người → KHÔNG để khu vực cố định trong hồ sơ.
-- ------------------------------------------------------------
create table if not exists phan_cong_giao (
  id          bigint generated always as identity primary key,
  ngay        date not null,
  ca          text not null check (ca in ('Sáng','Trưa','Chiều')),
  khu_vuc     text not null references dm_khu_vuc(ma),
  nguoi_giao  uuid references nguoi_dung(id),
  ghi_chu     text,
  created_at  timestamptz default now(),
  unique (ngay, ca, khu_vuc)            -- 1 khu vực trong 1 ca chỉ 1 người
);
create index if not exists idx_pcg_ngay  on phan_cong_giao(ngay);
create index if not exists idx_pcg_nguoi on phan_cong_giao(nguoi_giao);

-- ------------------------------------------------------------
-- 3c) DANH SÁCH GMAIL ĐƯỢC PHÉP (admin nhập trước vai trò)
--     Người không có trong danh sách này vẫn đăng nhập Google được
--     nhưng hồ sơ ở trạng thái CHỜ (admin duyệt sau).
-- ------------------------------------------------------------
create table if not exists tai_khoan_cho_phep (
  email        text primary key,        -- Gmail được phép
  ho_ten       text,
  vai_tro      text references vai_tro(ma),
  bo_phan      text,
  cap_quan_tri text check (cap_quan_tri in ('tong','phu')),
  ghi_chu      text
);
-- Gmail chủ hệ thống = Admin tổng (đăng nhập phát là có quyền ngay)
insert into tai_khoan_cho_phep (email, ho_ten, vai_tro, cap_quan_tri) values
  ('hoavq.medi@gmail.com', 'Chủ hệ thống', 'admin', 'tong')
on conflict (email) do update
  set vai_tro=excluded.vai_tro, cap_quan_tri=excluded.cap_quan_tri;

-- ------------------------------------------------------------
-- 4) TỰ TẠO HỒ SƠ KHI CÓ TÀI KHOẢN GOOGLE MỚI
--    Tra danh sách cho phép → gán sẵn vai trò + bật nếu có.
-- ------------------------------------------------------------
create or replace function fn_tao_ho_so_nguoi_dung()
returns trigger language plpgsql security definer set search_path = public as $$
declare cp public.tai_khoan_cho_phep%rowtype;
begin
  select * into cp from public.tai_khoan_cho_phep where email = new.email;
  insert into public.nguoi_dung (id, email, ho_ten, vai_tro, bo_phan, cap_quan_tri, trang_thai)
  values (
    new.id,
    new.email,
    coalesce(cp.ho_ten, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    cp.vai_tro,
    cp.bo_phan,
    cp.cap_quan_tri,
    (cp.email is not null)             -- có trong danh sách cho phép → bật ngay
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_tao_ho_so on auth.users;
create trigger trg_tao_ho_so
  after insert on auth.users
  for each row execute function fn_tao_ho_so_nguoi_dung();

-- ------------------------------------------------------------
-- 5) HÀM TIỆN ÍCH (security definer → tránh đệ quy RLS)
-- ------------------------------------------------------------
create or replace function fn_la_admin_tong()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.nguoi_dung
    where id = auth.uid()
      and vai_tro = 'admin' and cap_quan_tri = 'tong' and trang_thai
  );
$$;

-- trả về bộ phận mà người đang đăng nhập làm Admin PHỤ; null nếu không phải
create or replace function fn_bo_phan_admin_phu()
returns text language sql stable security definer set search_path = public as $$
  select bo_phan from public.nguoi_dung
  where id = auth.uid()
    and vai_tro = 'admin' and cap_quan_tri = 'phu' and trang_thai
  limit 1;
$$;

-- ------------------------------------------------------------
-- 6) BẬT RLS + POLICY
-- ------------------------------------------------------------
alter table vai_tro            enable row level security;
alter table dm_bo_phan         enable row level security;
alter table dm_khu_vuc         enable row level security;
alter table nguoi_dung         enable row level security;
alter table phan_cong_giao     enable row level security;
alter table tai_khoan_cho_phep enable row level security;

-- vai_tro / dm_bo_phan: mọi người ĐÃ ĐĂNG NHẬP đọc được; chỉ Admin tổng sửa
drop policy if exists p_vaitro_read on vai_tro;
create policy p_vaitro_read on vai_tro
  for select to authenticated using (true);
drop policy if exists p_vaitro_write on vai_tro;
create policy p_vaitro_write on vai_tro
  for all to authenticated using (fn_la_admin_tong()) with check (fn_la_admin_tong());

drop policy if exists p_bophan_read on dm_bo_phan;
create policy p_bophan_read on dm_bo_phan
  for select to authenticated using (true);
drop policy if exists p_bophan_write on dm_bo_phan;
create policy p_bophan_write on dm_bo_phan
  for all to authenticated using (fn_la_admin_tong()) with check (fn_la_admin_tong());

-- nguoi_dung:
--   • đọc: hồ sơ của chính mình | Admin tổng (tất cả) | Admin phụ (người cùng bộ phận)
drop policy if exists p_nd_read on nguoi_dung;
create policy p_nd_read on nguoi_dung
  for select to authenticated
  using (
    id = auth.uid()
    or fn_la_admin_tong()
    or (fn_bo_phan_admin_phu() is not null and bo_phan = fn_bo_phan_admin_phu())
  );

--   • sửa/tạo/xoá: Admin tổng (tất cả) | Admin phụ (chỉ người trong bộ phận mình)
drop policy if exists p_nd_write on nguoi_dung;
create policy p_nd_write on nguoi_dung
  for all to authenticated
  using (
    fn_la_admin_tong()
    or (fn_bo_phan_admin_phu() is not null and bo_phan = fn_bo_phan_admin_phu())
  )
  with check (
    fn_la_admin_tong()
    or (fn_bo_phan_admin_phu() is not null and bo_phan = fn_bo_phan_admin_phu())
  );

--   • (tuỳ chọn) cho mỗi người tự sửa HỌ TÊN của mình (không đổi vai trò):
-- drop policy if exists p_nd_self_update on nguoi_dung;
-- create policy p_nd_self_update on nguoi_dung
--   for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- dm_khu_vuc: ai đăng nhập đọc được; chỉ Admin tổng sửa
drop policy if exists p_kv_read on dm_khu_vuc;
create policy p_kv_read on dm_khu_vuc
  for select to authenticated using (true);
drop policy if exists p_kv_write on dm_khu_vuc;
create policy p_kv_write on dm_khu_vuc
  for all to authenticated using (fn_la_admin_tong()) with check (fn_la_admin_tong());

-- phan_cong_giao: ai đăng nhập đọc được (xem lịch giao); chỉ Admin tổng sửa
drop policy if exists p_pcg_read on phan_cong_giao;
create policy p_pcg_read on phan_cong_giao
  for select to authenticated using (true);
drop policy if exists p_pcg_write on phan_cong_giao;
create policy p_pcg_write on phan_cong_giao
  for all to authenticated using (fn_la_admin_tong()) with check (fn_la_admin_tong());

-- tai_khoan_cho_phep: NHẠY CẢM — chỉ Admin tổng đọc & sửa
--   (trigger đọc bảng này bằng security definer nên không bị RLS chặn)
drop policy if exists p_cp_all on tai_khoan_cho_phep;
create policy p_cp_all on tai_khoan_cho_phep
  for all to authenticated using (fn_la_admin_tong()) with check (fn_la_admin_tong());

-- ============================================================
-- 7) KHỞI TẠO ADMIN ĐẦU TIÊN  (làm SAU khi chị đã đăng nhập
--    Google lần đầu — lúc đó hồ sơ của chị đã tự tạo)
--    SQL Editor chạy quyền cao nên bỏ qua RLS, set được admin.
-- ============================================================
update nguoi_dung
   set vai_tro = 'admin', cap_quan_tri = 'tong', trang_thai = true
 where email = 'hoavq.medi@gmail.com';

-- ------------------------------------------------------------
--  GHI CHÚ
--  • Danh mục vai trò = bảng vai_tro (7 vai trò). Màn "Danh mục vai trò"
--    của admin đọc trực tiếp từ bảng này.
--  • Admin phụ: vai_tro='admin', cap_quan_tri='phu', bo_phan=<ma dm_bo_phan>.
--  • Người giao: vai_tro='giao'. Khu vực KHÔNG cố định — phân công theo
--    ngày/ca ở bảng phan_cong_giao. Số liệu giao để bảng 'giao_hang' riêng.
--  • Thêm Gmail được phép: insert vào tai_khoan_cho_phep (email + vai_tro)
--    TRƯỚC khi người đó đăng nhập Google.
--  • App phải đăng nhập bằng supabase.auth.signInWithOAuth({provider:'google'})
--    thì RLS mới nhận diện được người dùng (anon key sẽ KHÔNG đọc nguoi_dung).
-- ============================================================
