-- ============================================================
--  CHUẨN HÓA DỮ LIỆU — GIAI ĐOẠN 4: DỌN CỘT CŨ (DROP)
--  Theo KE-HOACH-chuan-hoa-du-lieu.md (G4). Chạy CUỐI CÙNG.
--
--  PHẠM VI ĐỢT NÀY (an toàn, đã có code G4-prep): drop các cột mà client
--  ĐÃ NGỪNG ghi và readers đã tự bù bằng _denorm:
--    dang_ky_suat: loai, cu, buoi
--    benh_nhan:    gio_xuat  (không có writer nào ghi → an toàn)
--
--  HOÃN sang đợt sau (cần thêm việc):
--    dang_ky_suat.khoa     → giữ tên denormalized; bỏ sau khi có trigger
--                            điền ma_khoa cho dòng mới + readers join dm_khoa.
--    dang_ky_suat.giao_gio → màn Giao còn ghi; cần đổi sang giao_gio_ts trước.
--    benh_nhan.khoa        → giữ cho tới khi readers dùng ma_khoa.
--
--  ⚠️ ĐIỀU KIỆN: đã deploy bản G4-prep (màn Khoa NGỪNG gửi loai/cu/buoi).
--     Xác minh: đăng ký thử 1 suất → dòng mới có ma_mon/cu_so nhưng KHÔNG
--     còn loai/cu/buoi (test E2E đã xác nhận).
--
--  An toàn & lặp được: drop column IF EXISTS + CASCADE (bỏ unique index cũ
--  trên (ma_bn,ngay,cu,loai) phụ thuộc cu/loai).
--  Dán vào: Supabase → SQL Editor → Run.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 0) TIỀN KIỂM — cột chuẩn đã đầy đủ trước khi bỏ cột cũ
--    Kỳ vọng: cu_so_null = 0, ma_mon_null = 0.
-- ════════════════════════════════════════════════════════════

select
  count(*)                                  tong,
  count(*) filter (where cu_so  is null)    cu_so_null,
  count(*) filter (where ma_mon is null)    ma_mon_null
from dang_ky_suat;


-- ════════════════════════════════════════════════════════════
-- 1) DROP cột cũ — dang_ky_suat (loai, cu, buoi)
--    cu/loai bị unique index cũ phụ thuộc → CASCADE bỏ luôn index đó.
-- ════════════════════════════════════════════════════════════

alter table dang_ky_suat
  drop column if exists loai cascade,
  drop column if exists cu   cascade,
  drop column if exists buoi cascade;


-- ════════════════════════════════════════════════════════════
-- 2) DROP cột cũ — benh_nhan (gio_xuat: không có writer)
-- ════════════════════════════════════════════════════════════

alter table benh_nhan
  drop column if exists gio_xuat cascade;


-- ════════════════════════════════════════════════════════════
-- 3) HẬU KIỂM
-- ════════════════════════════════════════════════════════════

-- (a) Cột cũ đã biến mất (kỳ vọng 0 dòng)
select table_name, column_name
from information_schema.columns
where (table_name='dang_ky_suat' and column_name in ('loai','cu','buoi'))
   or (table_name='benh_nhan'    and column_name in ('gio_xuat'))
order by table_name, column_name;

-- (b) Unique index chuẩn còn nguyên (phục vụ onConflict mới) — kỳ vọng 1 dòng
select indexname from pg_indexes
where tablename='dang_ky_suat' and indexname='uq_dang_ky_suat_chuan';
