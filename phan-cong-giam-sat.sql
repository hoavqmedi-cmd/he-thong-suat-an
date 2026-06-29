-- ============================================================
--  SCHEMA — MÀN HÌNH PHÂN CÔNG & GIÁM SÁT GIAO SUẤT
--  Dán toàn bộ file này vào: Supabase → SQL Editor → Run
--  Bổ sung cho Giai đoạn 1 (dang_ky_suat đã có sẵn).
--  Gồm: nhân viên giao, khu vực (gom khoa theo tầng),
--       phân công NV theo ngày/cữ, trạng thái giao trên từng suất.
-- ============================================================

-- ------------------------------------------------------------
-- 1) NHÂN VIÊN GIAO SUẤT  (seed vài NV mẫu — chị sửa lại sau)
-- ------------------------------------------------------------
create table if not exists nv_giao (
  ma_nv      text primary key,
  ho_ten     text not null,
  dang_lam   boolean default true,    -- false = nghỉ/ngưng, không hiện ở ô chọn
  thu_tu     int,
  created_at timestamptz default now()
);

insert into nv_giao (ma_nv, ho_ten, thu_tu) values
  ('NV01','Nhân viên giao 1', 1),
  ('NV02','Nhân viên giao 2', 2),
  ('NV03','Nhân viên giao 3', 3)
on conflict (ma_nv) do nothing;

-- ------------------------------------------------------------
-- 2) KHU VỰC GIAO  (gom nhiều khoa theo tầng)
--    mo_ta = nhãn tầng/phạm vi hiện trên thẻ.
-- ------------------------------------------------------------
create table if not exists khu_vuc (
  ma_kv  text primary key,            -- 'KV1','KV2',...
  ten    text not null,               -- 'Khu 1'
  mo_ta  text,                        -- 'Tầng 2 · Khoa Khám'
  thu_tu int,
  dang_dung boolean default true
);

-- ------------------------------------------------------------
-- 3) BẢN ĐỒ KHU VỰC ↔ KHOA
--    Lưu ý: dang_ky_suat.khoa lưu TÊN KHOA (vd 'Nhi Tổng hợp'),
--    không phải mã K01. Nên map ở đây dùng ĐÚNG TÊN KHOA như
--    trong dữ liệu thật. Khoa nào chưa map sẽ hiện ở nhóm
--    "Chưa xếp khu" trên màn hình để chị bổ sung.
-- ------------------------------------------------------------
create table if not exists khu_vuc_khoa (
  ma_kv    text not null,             -- FK khu_vuc.ma_kv
  ten_khoa text not null,             -- = dang_ky_suat.khoa
  primary key (ma_kv, ten_khoa)
);

-- --- SEED MẶC ĐỊNH (TẠM — CHỊ SỬA LẠI THEO TẦNG THẬT) -------
-- Dựa trên các tên khoa đang thấy trong dữ liệu demo. Khi có
-- danh sách tầng→khoa chính thức, chỉ cần sửa 2 khối insert dưới.
insert into khu_vuc (ma_kv, ten, mo_ta, thu_tu) values
  ('KV1','Khu 1','Tầng 2 · Nội Nhi',    1),
  ('KV2','Khu 2','Tầng 3 · Hô hấp/Tiêu hoá', 2),
  ('KV3','Khu 3','Tầng 4 · Ngoại',      3),
  ('KV4','Khu 4','Tầng 5 · Sơ sinh',    4)
on conflict (ma_kv) do update
  set ten=excluded.ten, mo_ta=excluded.mo_ta, thu_tu=excluded.thu_tu;

insert into khu_vuc_khoa (ma_kv, ten_khoa) values
  ('KV1','Nhi Tổng hợp'),
  ('KV2','Tiêu hoá Nhi'),
  ('KV3','Ngoại Nhi'),
  ('KV3','Chấn thương Nhi'),
  ('KV4','Sơ sinh')
on conflict (ma_kv, ten_khoa) do nothing;

-- ------------------------------------------------------------
-- 4) PHÂN CÔNG  (1 NV / khu / ngày / cữ)
--    unique (ngay, buoi, ma_kv) → lưu lại = ghi đè, không trùng.
-- ------------------------------------------------------------
create table if not exists phan_cong (
  id         bigint generated always as identity primary key,
  ngay       date not null,
  buoi       text not null,           -- 'Sáng' | 'Trưa' | 'Chiều'
  ma_kv      text not null,
  ma_nv      text,                    -- null = chưa gán
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (ngay, buoi, ma_kv)
);
create index if not exists idx_pc_ngay_buoi on phan_cong(ngay, buoi);

-- ------------------------------------------------------------
-- 5) TRẠNG THÁI GIAO trên từng suất (thêm cột vào dang_ky_suat)
--    trang_thai_giao: 'cho_giao' | 'da_giao' | 'that_bai' | 'tra_bep'
-- ------------------------------------------------------------
alter table dang_ky_suat add column if not exists trang_thai_giao text default 'cho_giao';
alter table dang_ky_suat add column if not exists nv_giao   text;        -- ai giao (ma_nv)
alter table dang_ky_suat add column if not exists gio_giao  timestamptz; -- thời điểm giao

create index if not exists idx_dks_giao on dang_ky_suat(ngay, buoi, trang_thai_giao);

-- ------------------------------------------------------------
-- GHI CHÚ
-- ------------------------------------------------------------
-- • "Tổng suất cữ" mỗi khu = số suất trong dang_ky_suat theo
--   (ngay, buoi) có khoa thuộc khu, KHÔNG tính suất bị từ chối.
--   Màn hình dùng hằng REJECTED_STATUSES để loại các trạng thái
--   như 'kdd_tu_choi'. Nếu BV chốt 1 trạng thái "đã duyệt" cụ thể,
--   đổi sang đếm theo trạng thái đó cho chuẩn.
-- • RLS đang TẮT để demo. Khi chạy thật với dữ liệu bệnh nhân:
--   bật RLS + policy theo vai trò (báo để soạn policy mẫu).
