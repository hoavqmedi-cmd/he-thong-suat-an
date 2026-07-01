-- ============================================================
--  CHUẨN HÓA — G4c: DROP cột khoa (tên) ở 2 bảng
--  Chạy CUỐI: sau khi (1) g4b-backfill xong (ma_khoa hết NULL),
--  (2) đã DEPLOY code bỏ khoa (writer gửi ma_khoa; readers dựng tên
--  từ ma_khoa), (3) đã kiểm 5 màn hiển thị đúng tên khoa.
--
--  ⚠️ Nếu chạy trước khi deploy code → writer cũ còn gửi 'khoa' → INSERT
--     lỗi; readers cũ mất tên khoa. PHẢI deploy code trước.
-- ============================================================

-- Tiền kiểm: đảm bảo ma_khoa đã đầy đủ (0 dòng có khoa mà thiếu ma_khoa)
select
  (select count(*) from benh_nhan   where ma_khoa is null and khoa is not null) bn_sot,
  (select count(*) from dang_ky_suat where ma_khoa is null and khoa is not null) dks_sot;
-- Kỳ vọng: bn_sot = 0 và dks_sot = 0. Nếu >0 → DỪNG, chạy lại g4b.

alter table dang_ky_suat drop column if exists khoa cascade;
alter table benh_nhan     drop column if exists khoa cascade;

-- Hậu kiểm: cột khoa đã biến mất (kỳ vọng 0 dòng)
select table_name, column_name
from information_schema.columns
where column_name='khoa' and table_name in ('dang_ky_suat','benh_nhan');
