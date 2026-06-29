-- ============================================================
--  MIGRATE PHA 1 — ADDITIVE (an toàn, KHÔNG vỡ app)
--  Thêm cột chuẩn + backfill từ cột cũ. GIỮ NGUYÊN cột cũ.
--  Dán vào: Supabase → SQL Editor → Run.
--  Pha 2 (sửa code app) và Pha 3 (dọn cột cũ) làm sau.
-- ============================================================

-- ── dang_ky_suat: thêm cột chuẩn ──
alter table dang_ky_suat add column if not exists ma_khoa      text;  -- FK dm_khoa (K01..K21)
alter table dang_ky_suat add column if not exists ma_mon       text;  -- FK dm_ma_mon
alter table dang_ky_suat add column if not exists muc_do       text;  -- FK dm_muc_do_benh (01..04)
alter table dang_ky_suat add column if not exists ml           numeric;
alter table dang_ky_suat add column if not exists nhom_tuoi_ma text;  -- '1'..'5' (thay nhom_tuoi int)

-- Backfill ma_mon từ loai (mã món cũ -> mã danh mục)
update dang_ky_suat set ma_mon = case loai
    when 'com_dv'  then 'CPDV'
    when 'chao_dv' then 'ChPDV'
    when 'com_bl'  then 'Cơm'
    when 'chao_bl' then 'Cháo'
    when 'sua_bt'  then 'Sữa thường'
    when 'sua_db'  then 'Sữa đặc trị'
    when 'sonde'   then 'Sonde'
    else ma_mon
  end
where ma_mon is null and loai is not null;

-- Backfill nhom_tuoi_ma từ nhom_tuoi (int -> text)
update dang_ky_suat set nhom_tuoi_ma = nhom_tuoi::text
where nhom_tuoi_ma is null and nhom_tuoi is not null;

-- ── benh_nhan: đảm bảo cột chuẩn tồn tại (additive) ──
alter table benh_nhan add column if not exists ma_khoa        text;       -- FK dm_khoa
alter table benh_nhan add column if not exists loai_phong     text;       -- 'thuong' | 'dich_vu'
alter table benh_nhan add column if not exists gioi_tinh      text;
alter table benh_nhan add column if not exists gio_nhap_vien  timestamptz;
alter table benh_nhan add column if not exists gio_xuat_vien  timestamptz; -- chuẩn (gio_xuat cũ = text)

-- ── KIỂM TRA backfill ──
select 'dang_ky_suat' bang,
  count(*)                                   tong_dong,
  count(*) filter (where ma_mon is not null) ma_mon_da_dien,
  count(*) filter (where nhom_tuoi_ma is not null) nhomma_da_dien,
  count(*) filter (where loai is not null and ma_mon is null) ma_mon_chua_map
from dang_ky_suat;
