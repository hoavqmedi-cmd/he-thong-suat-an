-- ============================================================
--  FIX BƯỚC 2 — Sửa khóa upsert để KHÔNG mất món trong cùng cữ
--  ĐÃ XÁC ĐỊNH (29/06): khóa sai hiện tại = uq_dks_bn_ngay_cu
--  trên (ma_bn, ngay, cu) → ép mỗi cữ chỉ 1 dòng → mất sữa/cơm/súp.
--  File này: gỡ khóa sai, tạo khóa đúng (ma_bn, ngay, cu, loai).
--  Không cần dọn trùng (khóa cũ đã đảm bảo không trùng 4 cột).
--
--  THỨ TỰ: chạy file này TRƯỚC, rồi deploy lại thư mục public/.
--  (Code trong public/he-thong-suat-an.html đã đổi onConflict sang
--   "ma_bn,ngay,cu,loai" cho khớp khóa mới.)
-- ============================================================

-- 1) Gỡ khóa SAI (ma_bn, ngay, cu) — đây là CONSTRAINT nên dùng drop constraint
alter table dang_ky_suat drop constraint if exists uq_dks_bn_ngay_cu;

-- 2) Tạo khóa ĐÚNG (ma_bn, ngay, cu, loai)
create unique index if not exists uq_dks_bn_ngay_cu_loai
  on dang_ky_suat (ma_bn, ngay, cu, loai);

-- 3) Kiểm tra lại — phải thấy uq_dks_bn_ngay_cu_loai, KHÔNG còn uq_dks_bn_ngay_cu
select i.relname as ten_index,
       pg_get_indexdef(idx.indexrelid) as dinh_nghia
from pg_index idx
join pg_class t on t.oid = idx.indrelid
join pg_class i on i.oid = idx.indexrelid
where t.relname = 'dang_ky_suat' and idx.indisunique;
