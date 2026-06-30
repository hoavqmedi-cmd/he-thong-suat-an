-- ============================================================
--  CHUẨN HÓA DỮ LIỆU — GIAI ĐOẠN 2: BACKFILL + CHUẨN HÓA DANH MỤC
--  Theo KE-HOACH-chuan-hoa-du-lieu.md (G2). Chạy SAU file G1.
--
--  An toàn & lặp được (idempotent): chạy lại nhiều lần ra cùng kết quả.
--  KHÔNG xóa cột cũ (loai/cu/buoi/khoa/giao_gio/gio_xuat vẫn còn) — app
--  tiếp tục chạy bằng cột cũ. Việc bỏ cột cũ để dành G4.
--
--  ⚠️ NÊN EXPORT (backup) bảng dang_ky_suat & benh_nhan trước khi chạy.
--  Dán vào: Supabase → SQL Editor → Run.
--
--  LƯU Ý vận hành: backfill ma_khoa cần bảng ánh xạ tên→mã do tên khoa
--  cũ chưa chắc khớp dm_khoa.ten. Quy trình:
--    1) Chạy file lần 1.
--    2) Xem query (b) ở cuối → liệt kê tên khoa CHƯA map được.
--    3) Thêm dòng vào map_khoa_ten (mục 2) cho các tên đó.
--    4) Chạy lại file → lặp đến khi query (a) báo khoa_sot = 0.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 1) CHUẨN HÓA DANH MỤC MÓN (quyết định #2: gộp Sữa, đổi Sonde→Súp Sonde)
--    G2 chỉ THÊM món gộp + remap ma trận cữ×món. KHÔNG xóa món cũ
--    (Sữa thường/Sữa đặc trị/Sonde) — xóa + sửa danh-muc.js để dành G3.
-- ════════════════════════════════════════════════════════════

insert into dm_ma_mon (ma, ten, loai_suat, don_vi) values
  ('Sữa',       'Sữa',       'BL', 'ml'),
  ('Súp Sonde', 'Súp Sonde', 'BL', 'ml')
on conflict (ma) do nothing;

-- Remap dm_cu_mon (PK = cu_so,mon) sang món chuẩn theo khung 11 cữ:
--   Sữa     : cữ 01,02,03,05,06,09,10,11
--   Súp Sonde: cữ 02,04,07,10
delete from dm_cu_mon where mon in ('Sữa thường','Sữa đặc trị','Sonde');
insert into dm_cu_mon (cu_so, mon) values
  ('01','Sữa'),('02','Sữa'),('03','Sữa'),('05','Sữa'),
  ('06','Sữa'),('09','Sữa'),('10','Sữa'),('11','Sữa'),
  ('02','Súp Sonde'),('04','Súp Sonde'),('07','Súp Sonde'),('10','Súp Sonde')
on conflict (cu_so, mon) do nothing;


-- ════════════════════════════════════════════════════════════
-- 2) BẢNG ÁNH XẠ TÊN KHOA → MÃ
--    dm_khoa.ten viết HOA ("KHOA NỘI TỔNG QUÁT 1"); khoa cũ trong dữ
--    liệu có thể là tên ngắn/thường → cần map thủ công phần lệch.
-- ════════════════════════════════════════════════════════════

create table if not exists map_khoa_ten (
  ten_cu text primary key,   -- giá trị khoa cũ NGUYÊN VĂN trong benh_nhan/dang_ky_suat
  ma     text not null       -- mã trong dm_khoa (K01..K21)
);

-- TODO: điền theo tên khoa THỰC TẾ trong DB. Chạy query (b) ở cuối file
--       để lấy danh sách tên chưa map, rồi thêm dòng vào đây và chạy lại.
-- Ví dụ mẫu (BỎ COMMENT & sửa cho khớp dữ liệu thật):
-- insert into map_khoa_ten (ten_cu, ma) values
--   ('Nhi Tổng hợp',      'K07'),
--   ('Sơ sinh',           'K19'),
--   ('Hồi sức tích cực',  'K21')
-- on conflict (ten_cu) do update set ma = excluded.ma;

-- Backfill ma_khoa cho dang_ky_suat
--   (a) khớp trực tiếp theo tên (chuẩn hóa HOA + bỏ khoảng trắng thừa)
update dang_ky_suat d set ma_khoa = k.ma
  from dm_khoa k
  where d.ma_khoa is null and d.khoa is not null
    and upper(trim(d.khoa)) = k.ten;
--   (b) phần còn lại tra bảng map thủ công
update dang_ky_suat d set ma_khoa = m.ma
  from map_khoa_ten m
  where d.ma_khoa is null and trim(d.khoa) = m.ten_cu;

-- Backfill ma_khoa cho benh_nhan (tương tự)
update benh_nhan b set ma_khoa = k.ma
  from dm_khoa k
  where b.ma_khoa is null and b.khoa is not null
    and upper(trim(b.khoa)) = k.ten;
update benh_nhan b set ma_khoa = m.ma
  from map_khoa_ten m
  where b.ma_khoa is null and trim(b.khoa) = m.ten_cu;


-- ════════════════════════════════════════════════════════════
-- 3) BACKFILL ma_mon TỪ loai (GHI ĐÈ để sửa giá trị pha1 cũ)
--    where loai is not null (không dùng "ma_mon is null") để chuẩn lại
--    các dòng pha1 từng điền 'Sữa thường'/'Sữa đặc trị'/'Sonde'.
-- ════════════════════════════════════════════════════════════

update dang_ky_suat set ma_mon = case loai
    when 'com_dv'  then 'CPDV'
    when 'chao_dv' then 'ChPDV'
    when 'com_bl'  then 'Cơm'
    when 'chao_bl' then 'Cháo'
    when 'sua_bt'  then 'Sữa'
    when 'sua_db'  then 'Sữa'
    when 'sonde'   then 'Súp Sonde'
    else ma_mon
  end
where loai is not null;


-- ════════════════════════════════════════════════════════════
-- 4) BACKFILL cu_so TỪ cu (giờ text → số cữ)
--    Map ĐẦY ĐỦ 11 cữ theo MEAL_SESSIONS (danh-muc.js). Luồng BL ghi
--    cu = giờ thực của cữ (03:00..00:00), không chỉ 3 mốc DV → phải đủ
--    11 mốc, nếu không cu_so của sữa/sonde sẽ NULL (cu_sot != 0).
-- ════════════════════════════════════════════════════════════

update dang_ky_suat set cu_so = case cu
    when '03:00' then '01'
    when '06:00' then '02'
    when '09:00' then '03'
    when '11:00' then '04'
    when '12:00' then '05'
    when '15:00' then '06'
    when '16:00' then '07'
    when '17:00' then '08'
    when '18:00' then '09'
    when '21:00' then '10'
    when '00:00' then '11'
    else cu_so
  end
where cu is not null;


-- ════════════════════════════════════════════════════════════
-- 5) BACKFILL so_luong: mặc định 1 cho món đơn vị 'suất'; để NULL cho 'ml'
--    (số lượng ml của sữa/súp do KDD/sản xuất nhập sau.)
-- ════════════════════════════════════════════════════════════

update dang_ky_suat d set so_luong = 1
  from dm_ma_mon m
  where d.so_luong is null
    and d.ma_mon = m.ma
    and m.don_vi = 'suất';


-- ════════════════════════════════════════════════════════════
-- 6) BACKFILL GIỜ TEXT → timestamptz (canh regex để tránh lỗi cast, +07)
-- ════════════════════════════════════════════════════════════

-- giao_gio ('HH:MM') + ngay → giao_gio_ts
update dang_ky_suat
  set giao_gio_ts = (ngay::text || ' ' || giao_gio || ' +07')::timestamptz
  where giao_gio_ts is null
    and ngay is not null
    and giao_gio ~ '^[0-9]{1,2}:[0-9]{2}$';

-- gio_xuat (text) → gio_xuat_vien. Định dạng chưa chắc → chỉ parse khi
-- bắt đầu bằng 'YYYY-MM-DD'; dòng không khớp để NULL (an toàn).
update benh_nhan
  set gio_xuat_vien = gio_xuat::timestamptz
  where gio_xuat_vien is null
    and gio_xuat ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}';


-- ════════════════════════════════════════════════════════════
-- 7) QUERY KIỂM TRA (đọc kết quả trước khi qua G3)
-- ════════════════════════════════════════════════════════════

-- (a) Đếm dòng còn NULL ở cột chuẩn của dang_ky_suat
--     Kỳ vọng: mon_sot = 0, cu_sot = 0. khoa_sot = 0 sau khi điền đủ map.
select
  count(*)                                  tong_dong,
  count(*) filter (where ma_khoa is null)   khoa_sot,
  count(*) filter (where ma_mon  is null)   mon_sot,
  count(*) filter (where cu_so   is null)   cu_sot
from dang_ky_suat;

-- (a2) benh_nhan: số dòng còn thiếu ma_khoa
select
  count(*)                                  tong_bn,
  count(*) filter (where ma_khoa is null)   bn_khoa_sot
from benh_nhan;

-- (b) Liệt kê TÊN KHOA chưa map được → điền vào map_khoa_ten (mục 2) rồi chạy lại file.
select 'dang_ky_suat' nguon, khoa ten_chua_map
  from dang_ky_suat where ma_khoa is null and khoa is not null
union
select 'benh_nhan'    nguon, khoa
  from benh_nhan    where ma_khoa is null and khoa is not null
order by ten_chua_map;
