-- ============================================================
--  BỔ SUNG LƯU SỰ KIỆN TỪ BỆNH VIỆN (theo YEU-CAU-API mục 4 & 7)
--  Chạy 1 lần: Supabase → SQL Editor → New query → Run.
--  An toàn chạy lại (IF NOT EXISTS). Tách 2 phần:
--   (A) Bảng su_kien_bn  = nhật ký mọi bản tin API (chống trùng + lần vết)
--   (B) benh_nhan        = thêm cột trạng thái hiện tại (loại phòng, giờ...)
--  LƯU Ý BẢO MẬT: để RLS off cho khớp các bảng demo hiện tại. Khi chạy
--  dữ liệu bệnh nhân thật, bật RLS + policy (báo để soạn).
-- ============================================================

-- ── (A) BẢNG NHẬT KÝ SỰ KIỆN ──
create table if not exists su_kien_bn (
  event_id          text primary key,          -- CHỐNG TRÙNG: nhận lại id cũ -> bỏ qua (mục 7)
  event_type        text not null
                    check (event_type in ('them_moi','chuyen_phong','xuat_vien')),
  event_time        timestamptz not null,       -- giờ phát sinh sự kiện (ISO 8601 +07:00)
  ma_bn             text not null,              -- khóa định danh xuyên suốt
  loai_phong        text,                       -- 'thuong' | 'dich_vu' (trường quyết định tạo/cắt)

  -- giờ riêng theo từng loại sự kiện
  gio_nhap_vien     timestamptz,                -- them_moi
  gio_chuyen_phong  timestamptz,                -- chuyen_phong
  gio_xuat_vien     timestamptz,                -- xuat_vien

  -- thông tin chuyển phòng
  phong_cu          text,
  phong_moi         text,
  loai_phong_cu     text,
  loai_phong_moi    text,
  khoa_moi          text,
  giuong_moi        text,
  ly_do             text,                       -- xuất viện: ra viện / chuyển viện...

  -- định danh + vị trí (chủ yếu cho them_moi)
  ho_ten            text,
  ngay_sinh         date,
  gioi_tinh         text,
  khoa              text,
  phong             text,
  giuong            text,

  payload           jsonb,                      -- giữ nguyên bản tin gốc để đối chiếu
  received_at       timestamptz default now(),  -- thời điểm hệ thống nhận
  da_xu_ly          boolean default false,      -- đã áp logic tạo/cắt suất chưa
  ket_qua_xu_ly     text                        -- ghi chú kết quả xử lý
);

create index if not exists idx_skbn_ma_bn  on su_kien_bn(ma_bn);
create index if not exists idx_skbn_time   on su_kien_bn(event_time);
create index if not exists idx_skbn_chuaxu on su_kien_bn(da_xu_ly) where da_xu_ly = false;

-- ── (B) TRẠNG THÁI HIỆN TẠI TRÊN benh_nhan ──
-- Giữ nguyên cột gio_xuat (text) cũ để app hiện tại không vỡ;
-- thêm các cột chuẩn timestamptz cho luồng API.
alter table benh_nhan add column if not exists loai_phong      text;        -- 'thuong' | 'dich_vu' hiện tại
alter table benh_nhan add column if not exists gio_nhap_vien   timestamptz;
alter table benh_nhan add column if not exists gio_xuat_vien   timestamptz; -- bản chuẩn (gio_xuat cũ = text)
alter table benh_nhan add column if not exists gioi_tinh       text;
alter table benh_nhan add column if not exists last_event_id   text;        -- sự kiện gần nhất đã áp
alter table benh_nhan add column if not exists last_event_time timestamptz;

-- ── KIỂM TRA ──
select 'su_kien_bn' as bang, count(*) as so_cot
from information_schema.columns where table_name='su_kien_bn'
union all
select 'benh_nhan (cot moi)', count(*)
from information_schema.columns
where table_name='benh_nhan'
  and column_name in ('loai_phong','gio_nhap_vien','gio_xuat_vien','gioi_tinh','last_event_id','last_event_time');
