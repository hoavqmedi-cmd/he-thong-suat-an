-- ============================================================
--  CHUẨN HÓA DỮ LIỆU — GIAI ĐOẠN 4: DỌN CỘT CŨ (DROP)
--  Theo KE-HOACH-chuan-hoa-du-lieu.md (G4). Chạy CUỐI CÙNG.
--
--  ⚠️⚠️ ĐIỀU KIỆN BẮT BUỘC TRƯỚC KHI CHẠY ⚠️⚠️
--  1) G3-PR1 + G3-PR2 đã deploy & chạy ổn ≥ 1 chu kỳ thật.
--  2) WRITER (màn Khoa) đã NGỪNG ghi cột cũ. Hiện _chuanHoa vẫn ghi
--     song song loai/cu/buoi/khoa. PHẢI sửa writer để KHÔNG gửi các cột
--     này NỮA trước khi drop — nếu không, INSERT sẽ lỗi "column does not
--     exist". (Cách: trong _chuanHoa, sau khi suy ra cột chuẩn, delete
--     r.loai/r.cu/r.buoi/r.khoa; hoặc bỏ chúng khỏi 3 row-builder.)
--  3) Đã xác nhận KHÔNG còn nơi nào đọc cột cũ ngoài fallback _denorm
--     (các fallback này tự xử lý khi cột vắng — an toàn sau khi drop).
--  4) Backup (nếu không phải data test).
--
--  An toàn & lặp được: drop column IF EXISTS. CASCADE để bỏ luôn unique
--  index cũ trên (ma_bn,ngay,cu,loai) phụ thuộc cu/loai.
--  Dán vào: Supabase → SQL Editor → Run.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 0) TIỀN KIỂM (đọc trước khi drop — đảm bảo cột chuẩn đã đầy đủ)
--    Kỳ vọng: cu_so_null = 0, ma_mon_null = 0. Nếu >0 → DỪNG, quay lại G2.
-- ════════════════════════════════════════════════════════════

select
  count(*)                                  tong,
  count(*) filter (where cu_so  is null)    cu_so_null,
  count(*) filter (where ma_mon is null)    ma_mon_null,
  count(*) filter (where ma_khoa is null)   ma_khoa_null
from dang_ky_suat;

-- Kiểm benh_nhan: gio_xuat_vien đã backfill cho dòng có gio_xuat chưa?
select
  count(*)                                          tong_bn,
  count(*) filter (where ma_khoa is null)           bn_ma_khoa_null,
  count(*) filter (where gio_xuat is not null
                    and gio_xuat_vien is null)      bn_gio_chua_parse
from benh_nhan;


-- ════════════════════════════════════════════════════════════
-- 1) DROP CỘT CŨ — dang_ky_suat
--    cu/loai bị unique index cũ phụ thuộc → CASCADE bỏ luôn index đó.
-- ════════════════════════════════════════════════════════════

alter table dang_ky_suat
  drop column if exists loai     cascade,
  drop column if exists cu       cascade,
  drop column if exists buoi     cascade,
  drop column if exists khoa     cascade,
  drop column if exists giao_gio cascade;

-- (loai_food GIỮ LẠI: là cột riêng, màn Quản trị/Giao còn dùng; không
--  nằm trong phạm vi chuẩn hóa G1-G4. Bỏ sau nếu muốn, ở bước riêng.)


-- ════════════════════════════════════════════════════════════
-- 2) DROP CỘT CŨ — benh_nhan
-- ════════════════════════════════════════════════════════════

alter table benh_nhan
  drop column if exists khoa     cascade,
  drop column if exists gio_xuat cascade;


-- ════════════════════════════════════════════════════════════
-- 3) HẬU KIỂM
-- ════════════════════════════════════════════════════════════

-- (a) Xác nhận cột cũ đã biến mất
select table_name, column_name
from information_schema.columns
where (table_name='dang_ky_suat' and column_name in ('loai','cu','buoi','khoa','giao_gio'))
   or (table_name='benh_nhan'    and column_name in ('khoa','gio_xuat'))
order by table_name, column_name;
-- Kỳ vọng: 0 dòng.

-- (b) Xác nhận unique index chuẩn còn nguyên (phục vụ onConflict mới)
select indexname from pg_indexes
where tablename='dang_ky_suat' and indexname='uq_dang_ky_suat_chuan';
-- Kỳ vọng: 1 dòng.
