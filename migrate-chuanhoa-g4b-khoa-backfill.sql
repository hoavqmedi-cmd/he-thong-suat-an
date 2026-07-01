-- ============================================================
--  CHUẨN HÓA — G4b: BACKFILL ma_khoa (vá sót ở G2) + kiểm
--  Chạy TRƯỚC khi deploy code bỏ khoa và TRƯỚC g4c-drop.
--  An toàn, lặp được. Dùng map_khoa_ten (đã điền ở G2) + dm_khoa.
-- ============================================================

-- benh_nhan: khớp trực tiếp tên HOA, rồi map thủ công
update benh_nhan b set ma_khoa = k.ma
  from dm_khoa k
  where b.ma_khoa is null and b.khoa is not null and upper(trim(b.khoa)) = k.ten;
update benh_nhan b set ma_khoa = m.ma
  from map_khoa_ten m
  where b.ma_khoa is null and trim(b.khoa) = m.ten_cu;

-- dang_ky_suat: vá nốt dòng còn thiếu (dòng mới ghi sau G4-prep có khoa tên)
update dang_ky_suat d set ma_khoa = k.ma
  from dm_khoa k
  where d.ma_khoa is null and d.khoa is not null and upper(trim(d.khoa)) = k.ten;
update dang_ky_suat d set ma_khoa = m.ma
  from map_khoa_ten m
  where d.ma_khoa is null and trim(d.khoa) = m.ten_cu;

-- KIỂM: cả 2 bảng phải hết NULL ma_khoa (với dòng có khoa)
select 'benh_nhan' bang,
  count(*) tong,
  count(*) filter (where ma_khoa is null) ma_khoa_null,
  count(*) filter (where ma_khoa is null and khoa is not null) null_ma_con_ten
from benh_nhan
union all
select 'dang_ky_suat',
  count(*),
  count(*) filter (where ma_khoa is null),
  count(*) filter (where ma_khoa is null and khoa is not null)
from dang_ky_suat;

-- Nếu null_ma_con_ten > 0 → có tên khoa chưa map. Liệt kê để thêm map_khoa_ten:
select distinct khoa from benh_nhan where ma_khoa is null and khoa is not null
union
select distinct khoa from dang_ky_suat where ma_khoa is null and khoa is not null;
