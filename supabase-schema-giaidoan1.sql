-- ============================================================
--  SCHEMA GIAI ĐOẠN 1 — Hệ thống suất ăn (cơm/cháo)
--  Dán toàn bộ file này vào: Supabase → SQL Editor → Run
--  Bảng denormalized (gộp thông tin BN vào luôn) cho gọn,
--  đủ để demo end-to-end: Khoa đăng ký -> KDD duyệt.
-- ============================================================

create table if not exists dang_ky_suat (
  id            bigint generated always as identity primary key,

  -- Thông tin bệnh nhân (gộp luôn để Khoa ghi 1 lần)
  ma_bn         text,
  ho_ten        text,
  khoa          text,
  phong         text,
  giuong        text,
  ngay_sinh     date,
  nhom_tuoi     int,                    -- 1..5

  -- Thông tin cữ / suất
  ngay          date default current_date,
  cu            text,                   -- '06:00' | '11:00' | '17:00'
  buoi          text,                   -- 'Sáng' | 'Trưa' | 'Chiều'
  loai          text,                   -- 'com_dv' | 'chao_dv' | 'com_bl' | 'chao_bl'
  loai_food     text,                   -- 'com' | 'chao'
  loai_suat     text,                   -- 'DV' | 'BL'
  ma_che_do     text,
  bo_phan       text,                   -- 'bep_dv' | 'bep_benh_ly'

  -- Bệnh lý (để trống với dịch vụ)
  dis           text,
  kcal          numeric,
  protein_g     numeric,
  lipid_g       numeric,
  glucid_g      numeric,

  -- Ghi chú cháo
  xay           boolean default false,
  nem           boolean default false,
  ghi_chu       text,

  -- Vòng đời: khoa_gui -> da_gui_sx (KDD duyệt) | kdd_tu_choi (trả về)
  trang_thai    text default 'khoa_gui',
  ly_do_tu_choi text,

  created_at    timestamptz default now()
);

create index if not exists idx_dks_trangthai on dang_ky_suat(trang_thai);
create index if not exists idx_dks_ngay_cu   on dang_ky_suat(ngay, cu);

-- ------------------------------------------------------------
--  LƯU Ý BẢO MẬT (đọc kỹ trước khi dùng thật)
-- ------------------------------------------------------------
-- Bảng này để RLS TẮT để demo chạy ngay bằng anon key.
-- => Bất kỳ ai có anon key + URL đều đọc/ghi được.
-- Khi chạy thật với dữ liệu bệnh nhân: BẬT RLS và thêm policy
-- theo vai trò. Ví dụ bật RLS (sẽ chặn hết tới khi có policy):
--   alter table dang_ky_suat enable row level security;
-- (Khi tới bước này hãy báo để được soạn policy mẫu phù hợp.)
