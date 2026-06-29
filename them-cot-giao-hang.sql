-- ============================================================
--  THÊM CỘT KẾT QUẢ GIAO SUẤT — màn "Người giao – Bếp dịch vụ"
--  (giao-hang-bep-dich-vu.html). Chạy 1 lần trong Supabase →
--  SQL Editor → Run. An toàn chạy lại nhiều lần (IF NOT EXISTS).
--  Các cột này TÁCH RIÊNG khỏi vòng đời chính (trang_thai) nên
--  KHÔNG ảnh hưởng luồng Khoa → KDD → Sản xuất.
-- ============================================================

alter table dang_ky_suat add column if not exists giao_trang_thai text;  -- null = chưa giao | 'da_giao' | 'giao_that_bai'
alter table dang_ky_suat add column if not exists giao_ly_do      text;  -- lý do thất bại (BN vắng, từ chối, đã xuất viện...)
alter table dang_ky_suat add column if not exists giao_cach_xu_ly text;  -- 'Đem về bếp' | 'Gửi điều dưỡng khoa'
alter table dang_ky_suat add column if not exists giao_ghi_chu    text;  -- ghi chú thêm (khi lý do = "Khác")
alter table dang_ky_suat add column if not exists giao_gio        text;  -- giờ giao, dạng HH:MM
alter table dang_ky_suat add column if not exists giao_nguoi      text;  -- người giao / người sửa trạng thái
alter table dang_ky_suat add column if not exists giao_cap_nhat   timestamptz; -- thời điểm cập nhật gần nhất

create index if not exists idx_dks_giao on dang_ky_suat(giao_trang_thai);
