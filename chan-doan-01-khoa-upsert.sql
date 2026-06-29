-- ============================================================
--  CHẨN ĐOÁN BƯỚC 1 — Kiểm tra khóa upsert của bảng dang_ky_suat
--  CHỈ ĐỌC, KHÔNG SỬA GÌ. An toàn chạy nhiều lần.
--  Cách dùng: Supabase → SQL Editor → New query → dán hết → Run.
--  Sau khi chạy, gửi lại kết quả 3 phần (A, B, C) cho Claude.
-- ============================================================

-- ── A. Liệt kê các UNIQUE constraint & INDEX đang có trên bảng ──
--    Mục tiêu: xem khóa upsert thực tế là (ma_bn,ngay,cu) hay
--    (ma_bn,ngay,cu,loai) hay chưa có gì.
select
  i.relname              as ten_index,
  idx.indisunique        as la_unique,
  idx.indisprimary       as la_primary,
  pg_get_indexdef(idx.indexrelid) as dinh_nghia
from pg_index idx
join pg_class t on t.oid = idx.indrelid
join pg_class i on i.oid = idx.indexrelid
where t.relname = 'dang_ky_suat'
order by idx.indisprimary desc, idx.indisunique desc, i.relname;

-- ── B. Có đang gộp mất món trong cùng cữ không? ──
--    Đếm số dòng / số tổ hợp (ma_bn,ngay,cu) / số tổ hợp (ma_bn,ngay,cu,loai).
--    Nếu khóa upsert là (ma_bn,ngay,cu) thì so_to_hop_3 == so_dong,
--    và nếu so_to_hop_4 > so_to_hop_3 nghĩa là ĐÁNG LẼ phải có nhiều
--    món/cữ nhưng đã bị ghi đè mất.
select
  count(*)                                                   as so_dong,
  count(distinct (ma_bn, ngay, cu))                          as so_to_hop_3,   -- (ma_bn,ngay,cu)
  count(distinct (ma_bn, ngay, cu, loai))                    as so_to_hop_4    -- (ma_bn,ngay,cu,loai)
from dang_ky_suat
where ma_bn is not null;

-- ── C. Soi 1 BN bệnh lý có nhiều món trong 1 cữ ──
--    Bệnh lý cữ 06:00 đáng lẽ có cả sữa + cơm/cháo + súp.
--    Nếu mỗi (ma_bn,ngay,cu) chỉ còn 1 dòng -> nghi đã bị gộp mất.
select ma_bn, ngay, cu, count(*) as so_mon, array_agg(loai order by loai) as cac_loai
from dang_ky_suat
where loai_suat = 'BL'
group by ma_bn, ngay, cu
order by so_mon desc, ma_bn, ngay, cu
limit 20;
