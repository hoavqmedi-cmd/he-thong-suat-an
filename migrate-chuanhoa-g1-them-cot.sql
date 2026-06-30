-- ============================================================
--  CHUẨN HÓA DỮ LIỆU — GIAI ĐOẠN 1: THÊM CỘT CHUẨN (additive)
--  Theo KE-HOACH-chuan-hoa-du-lieu.md (G1).
--  An toàn: chỉ THÊM cột (if not exists), KHÔNG backfill, KHÔNG FK,
--  KHÔNG xóa gì. App vẫn chạy y như cũ (cột mới rỗng).
--  Chạy lại nhiều lần vô hại. Dán vào: Supabase → SQL Editor → Run.
--  (Backfill ở file G2; sửa code app + FK ở G3 — làm sau, từng checkpoint.)
-- ============================================================

-- ── benh_nhan: cột chuẩn ──
alter table benh_nhan
  add column if not exists ma_khoa        text,         -- → dm_khoa.ma (FK ở G3)
  add column if not exists gioi_tinh      text,         -- phục vụ nối HIS sau
  add column if not exists gio_xuat_vien  timestamptz;  -- thay gio_xuat (text), chuẩn hóa ở G2

-- ── dang_ky_suat: cột chuẩn ──
alter table dang_ky_suat
  add column if not exists ma_khoa      text,         -- → dm_khoa.ma
  add column if not exists ma_mon       text,         -- → dm_ma_mon.ma (CPDV/ChPDV/Cơm/Cháo/Sữa/Súp Sonde)
  add column if not exists cu_so        text,         -- → dm_cu_an.so ('02'/'04'/'08'…)
  add column if not exists so_luong     numeric,      -- đơn vị theo dm_ma_mon.don_vi (suất/ml)
  add column if not exists giao_gio_ts  timestamptz;  -- thay giao_gio (text)

-- ── KIỂM TRA: các cột chuẩn đã tồn tại chưa ──
select table_name, column_name, data_type
from information_schema.columns
where (table_name = 'benh_nhan'
        and column_name in ('ma_khoa','gioi_tinh','gio_xuat_vien'))
   or (table_name = 'dang_ky_suat'
        and column_name in ('ma_khoa','ma_mon','cu_so','so_luong','giao_gio_ts'))
order by table_name, column_name;
