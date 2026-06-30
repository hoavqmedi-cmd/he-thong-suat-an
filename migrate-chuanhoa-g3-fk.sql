-- ============================================================
--  CHUẨN HÓA DỮ LIỆU — GIAI ĐOẠN 3 (phần DB): UNIQUE INDEX + FK
--  Theo KE-HOACH-chuan-hoa-du-lieu.md (G3). Chạy SAU khi G2 sạch
--  (query kiểm tra G2: ma_khoa/ma_mon/cu_so không còn NULL).
--
--  ⚠️ Chỉ chạy KHI app đã deploy bản G3 (màn Khoa ghi ma_mon/cu_so/
--     so_luong + onConflict mới). Nếu chạy trước, app cũ vẫn ghi theo
--     khóa cũ — không hỏng, nhưng unique index mới có thể chặn vài ca.
--
--  An toàn & lặp được: dùng IF NOT EXISTS + DO-block kiểm tra trước khi
--  thêm constraint. KHÔNG xóa cột cũ (để G4).
--  Dán vào: Supabase → SQL Editor → Run.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 0) (Tùy chọn) BACKFILL LẠI ma_khoa cho dòng MỚI app ghi sau G2
--    Màn Khoa (client) ghi `khoa` (text) nhưng CHƯA suy ra ma_khoa
--    (map tên→mã nằm ở DB). Chạy lại đoạn map của G2 để vá dòng mới.
--    Bỏ qua nếu vừa chạy G2 xong và chưa có dòng mới.
-- ════════════════════════════════════════════════════════════

update dang_ky_suat d set ma_khoa = k.ma
  from dm_khoa k
  where d.ma_khoa is null and d.khoa is not null
    and upper(trim(d.khoa)) = k.ten;
update dang_ky_suat d set ma_khoa = m.ma
  from map_khoa_ten m
  where d.ma_khoa is null and trim(d.khoa) = m.ten_cu;


-- ════════════════════════════════════════════════════════════
-- 1) UNIQUE INDEX cho onConflict MỚI: (ma_bn, ngay, cu_so, ma_mon, ma_che_do)
--    PostgREST upsert cần unique index khớp ĐÚNG bộ cột onConflict.
--    ma_che_do giữ phân biệt mã sữa thường/đặc trị ở cùng cữ (quyết định #1
--    của G3 — bệnh nhân CÓ thể có >1 loại sữa/cữ).
--    ⚠️ Cả 5 cột cần KHÁC NULL để khóa hiệu lực (NULL bị Postgres coi là
--       phân biệt → có thể lọt trùng). App G3 đã đảm bảo điều này.
-- ════════════════════════════════════════════════════════════

create unique index if not exists uq_dang_ky_suat_chuan
  on dang_ky_suat (ma_bn, ngay, cu_so, ma_mon, ma_che_do);

-- (Giữ NGUYÊN unique index cũ trên (ma_bn,ngay,cu,loai) — app vẫn ghi
--  song song cột cũ; bỏ ở G4 cùng lúc drop cột.)


-- ════════════════════════════════════════════════════════════
-- 2) FK từ cột chuẩn về danh mục (chỉ thêm nếu CHƯA có).
--    ma_khoa cho phép NULL (dòng mới có thể chưa map) → FK vẫn hợp lệ.
-- ════════════════════════════════════════════════════════════

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'fk_dks_ma_mon') then
    alter table dang_ky_suat
      add constraint fk_dks_ma_mon foreign key (ma_mon) references dm_ma_mon(ma);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'fk_dks_cu_so') then
    alter table dang_ky_suat
      add constraint fk_dks_cu_so foreign key (cu_so) references dm_cu_an(so);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'fk_dks_ma_khoa') then
    alter table dang_ky_suat
      add constraint fk_dks_ma_khoa foreign key (ma_khoa) references dm_khoa(ma);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'fk_bn_ma_khoa') then
    alter table benh_nhan
      add constraint fk_bn_ma_khoa foreign key (ma_khoa) references dm_khoa(ma);
  end if;
end $$;


-- ════════════════════════════════════════════════════════════
-- 3) QUERY KIỂM TRA
-- ════════════════════════════════════════════════════════════

-- (a) Còn dòng nào cột chuẩn NULL (sẽ làm hổng unique index / FK)?
select
  count(*)                                    tong,
  count(*) filter (where cu_so is null)       cu_so_null,
  count(*) filter (where ma_mon is null)      ma_mon_null,
  count(*) filter (where ma_che_do is null)   ma_che_do_null,
  count(*) filter (where ma_khoa is null)     ma_khoa_null
from dang_ky_suat;

-- (b) Có dòng nào ma_mon/cu_so KHÔNG khớp danh mục (sẽ chặn FK)?
select 'ma_mon' cot, ma_mon gia_tri from dang_ky_suat d
  where ma_mon is not null and not exists (select 1 from dm_ma_mon m where m.ma = d.ma_mon)
union
select 'cu_so', cu_so from dang_ky_suat d
  where cu_so is not null and not exists (select 1 from dm_cu_an c where c.so = d.cu_so)
group by 1,2;

-- (c) Liệt kê các constraint/index đã tạo
select conname from pg_constraint
  where conname in ('fk_dks_ma_mon','fk_dks_cu_so','fk_dks_ma_khoa','fk_bn_ma_khoa')
  order by conname;
