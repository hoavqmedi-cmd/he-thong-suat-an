# Checklist chạy hệ thống suất ăn trên Supabase

> Hệ thống nhận thông tin suất ăn — Căn tin Nhi Đồng 1
> Tài liệu tự làm: từ tạo tài khoản → tạo CSDL → nối mockup → test. Cập nhật 28/06/2026.

---

## PHẦN A — Tạo tài khoản & project (≈15 phút)

- [ ] **A1.** Vào `https://supabase.com` → bấm **Start your project** → đăng nhập bằng Google (email `hoavq.medi@gmail.com`).
- [ ] **A2.** Bấm **New project**:
  - Name: `suat-an-nhi-dong-1`
  - Database Password: đặt mật khẩu mạnh → **lưu lại nơi an toàn** (cần khi backup/khôi phục).
  - Region: **Southeast Asia (Singapore)** — gần VN nhất, chạy nhanh.
- [ ] **A3.** Đợi ~2 phút project khởi tạo xong.
- [ ] **A4.** Vào **Project Settings (bánh răng) → API**, copy & lưu lại 2 giá trị:
  - **Project URL** (dạng `https://xxxx.supabase.co`)
  - **anon public** key (chuỗi dài) — đây là chìa khóa cho mockup kết nối.
  - ⚠️ Đừng dùng `service_role` key trên trình duyệt (key đó toàn quyền, chỉ dùng phía server).

---

## PHẦN B — Tạo cấu trúc dữ liệu (dán SQL)

- [ ] **B1.** Vào **SQL Editor** (menu trái) → **New query**.
- [ ] **B2.** Dán **toàn bộ** đoạn SQL ở Mục B5 bên dưới → bấm **Run**. Nếu báo "Success" là xong.
- [ ] **B3.** Vào **Table Editor** kiểm tra đã thấy đủ 7 bảng: `khoa`, `benh_nhan`, `danh_muc_sua`, `soup_sonde`, `dang_ky_suat`, `nguoi_dung`, `nhat_ky`.
- [ ] **B4.** (Tùy chọn) Dán tiếp đoạn **dữ liệu mẫu** ở Mục B6 để có vài dòng test.

### B5. SQL tạo bảng — dán nguyên khối

```sql
-- ====== 1. KHOA (25 khoa lâm sàng) ======
create table khoa (
  id          bigint generated always as identity primary key,
  ma_khoa     text unique not null,
  ten_khoa    text not null,
  trang_thai  text default 'dang_dung'
);

-- ====== 2. BỆNH NHÂN ======
create table benh_nhan (
  id          bigint generated always as identity primary key,
  ma_bn       text unique not null,
  ho_ten      text,
  ngay_sinh   date,
  phong       text,
  giuong      text,
  khoa_id     bigint references khoa(id),
  nhom_tuoi   text,                 -- '<6 thang' | '6-12 thang' | '1-3 tuoi' | '4-6 tuoi' | '7-15 tuoi'
  created_at  timestamptz default now()
);

-- ====== 3. DANH MỤC SỮA (do KDD quản lý) ======
create table danh_muc_sua (
  id            bigint generated always as identity primary key,
  ma_sua        text unique not null,
  ten_sua       text,
  loai          text not null,      -- 'BT' | 'DB'
  nhom_tuoi     text[],             -- 1 hoặc nhiều nhóm tuổi áp dụng
  ma_benh       text[],             -- chỉ với 'DB'; BT để rỗng
  bot_g         numeric,            -- công thức pha
  nuoc_ml       numeric,
  thanh_pham_ml numeric,
  trang_thai    text default 'dang_dung'
);

-- ====== 4. SOUP SONDE (4 loại) ======
create table soup_sonde (
  id            bigint generated always as identity primary key,
  ma_soup       text unique not null,   -- SS-GA | SS-HEO | SS-BO | SS-BS
  ten_soup      text,
  nguyen_lieu   jsonb,                  -- [{ten, dinh_luong, don_vi}, ...]
  thanh_pham_ml numeric,
  trang_thai    text default 'dang_dung'
);

-- ====== 5. ĐĂNG KÝ SUẤT (bảng chính — mỗi dòng 1 suất) ======
create table dang_ky_suat (
  id            bigint generated always as identity primary key,
  benh_nhan_id  bigint references benh_nhan(id),
  ngay          date not null,
  cu            text not null,      -- '06:00' | '11:00' | '17:00' | '03:00' ...
  buoi          text,               -- 'Sang' | 'Trua' | 'Chieu-Toi'
  loai          text not null,      -- 'DV' | 'BL'
  loai_food     text not null,      -- 'com' | 'chao' | 'sua_bt' | 'sua_db' | 'sonde'
  ma_che_do     text,               -- vd '5BT-CPDV'
  ma_sua_id     bigint references danh_muc_sua(id),
  ma_soup_id    bigint references soup_sonde(id),
  ml            numeric,            -- ml/suất (sữa, sonde)
  lipid_g       numeric,
  protein_g     numeric,
  glucid_g      numeric,
  kcal          numeric,
  xay           boolean,            -- cháo: xay/không
  nem           boolean,            -- cháo: nêm/không
  ghi_chu       text,
  bo_phan       text,               -- tự suy ra: 'bep_dv' | 'bep_benh_ly' | 'phong_sua_soup'
  trang_thai    text default 'khoa_gui',
                -- khoa_gui -> kdd_duyet / kdd_tu_choi -> da_gui_sx -> da_nau -> da_giao
  ly_do_tu_choi text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);
create index idx_dks_ngay_cu on dang_ky_suat(ngay, cu);
create index idx_dks_trangthai on dang_ky_suat(trang_thai);

-- ====== 6. NGƯỜI DÙNG & VAI TRÒ (7 vai trò) ======
create table nguoi_dung (
  id          bigint generated always as identity primary key,
  email       text unique,
  ho_ten      text,
  vai_tro     text not null,        -- 'khoa' | 'kdd' | 'bep_dv' | 'bep_benh_ly' | 'phong_sua_soup' | 'nguoi_giao' | 'admin'
  khoa_id     bigint references khoa(id),  -- chỉ với vai trò 'khoa'
  trang_thai  text default 'dang_dung'
);

-- ====== 7. NHẬT KÝ (mốc chính) ======
create table nhat_ky (
  id            bigint generated always as identity primary key,
  dang_ky_id    bigint references dang_ky_suat(id),
  hanh_dong     text,               -- 'gui' | 'duyet' | 'tu_choi' | 'gui_sx' | 'nau_xong' | 'giao_xong'
  nguoi_dung_id bigint references nguoi_dung(id),
  ghi_chu       text,
  thoi_diem     timestamptz default now()
);
```

### B6. (Tùy chọn) Dữ liệu mẫu để test

```sql
insert into khoa (ma_khoa, ten_khoa) values
  ('SS1','Sơ sinh 1'), ('TH','Tiêu hóa'), ('HHS','Hô hấp');

insert into benh_nhan (ma_bn, ho_ten, ngay_sinh, phong, giuong, khoa_id, nhom_tuoi) values
  ('BN001','Nguyễn Văn A','2024-01-10','P201','G05',1,'<6 thang'),
  ('BN002','Trần Thị B','2022-05-02','P210','G12',2,'1-3 tuoi');

insert into dang_ky_suat (benh_nhan_id, ngay, cu, buoi, loai, loai_food, ma_che_do, trang_thai)
values
  (1, current_date, '06:00','Sang','BL','chao','3TH-ChBL','khoa_gui'),
  (2, current_date, '11:00','Trua','DV','com','CPDV','khoa_gui');
```

---

## PHẦN C — Bật bảo mật (RLS) — làm trước khi chạy thật

Mặc định bảng để "mở" cho dễ test. Khi chạy thật **bắt buộc** bật Row Level Security để dữ liệu bệnh nhân không bị lộ.

- [ ] **C1.** Giai đoạn test nội bộ: có thể để tạm mở. **Không dán key lên web công khai.**
- [ ] **C2.** Trước khi dùng thật: vào **Authentication → Policies**, bật RLS cho từng bảng và đặt rule theo vai trò (vd khoa chỉ thấy BN khoa mình; KDD thấy tất cả). Phần này nên có người biết kỹ thuật làm cùng — em có thể soạn policy mẫu khi tới bước đó.

---

## PHẦN D — Nối mockup vào Supabase

Cách đơn giản nhất, không cần cài đặt gì, chỉ thêm 2 đoạn vào file HTML mockup:

- [ ] **D1.** Trong file mockup (vd `man-hinh-kdd.html`), thêm vào trước thẻ `</head>`:
  ```html
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  ```
- [ ] **D2.** Thêm đoạn khởi tạo (thay URL + KEY bằng giá trị ở bước A4):
  ```html
  <script>
    const supabase = window.supabase.createClient(
      'https://XXXX.supabase.co',   // Project URL
      'anon-public-key-cua-ban'     // anon public key
    );
  </script>
  ```
- [ ] **D3.** Thay chỗ đọc dữ liệu mẫu (`_c.js`, `_q.js`) bằng truy vấn thật. Ví dụ lấy các cữ chờ duyệt:
  ```js
  const { data, error } = await supabase
    .from('dang_ky_suat')
    .select('*, benh_nhan(*)')
    .eq('trang_thai', 'khoa_gui');
  ```
- [ ] **D4.** Ví dụ KDD duyệt 1 suất (đổi trạng thái):
  ```js
  await supabase
    .from('dang_ky_suat')
    .update({ trang_thai: 'da_gui_sx' })
    .eq('id', suatId);
  ```

> 💡 Đây là phần cần người biết JavaScript chỉnh từng màn. Nếu chị muốn, em làm sẵn 1 màn mẫu (Giai đoạn 1) để đội IT theo đó nhân ra các màn còn lại.

---

## PHẦN E — Đưa lên mạng (hosting) để dùng bằng điện thoại

- [ ] **E1.** Cách miễn phí, nhanh: kéo–thả thư mục mockup vào `https://app.netlify.com/drop` → có ngay link công khai.
- [ ] **E2.** Hoặc dùng **Vercel** / **Cloudflare Pages** (đều có gói free) nếu cần tên miền riêng.
- [ ] **E3.** Test mở link bằng điện thoại trong mạng bệnh viện, nhập thử 1 suất → kiểm tra dữ liệu vào Supabase.

---

## PHẦN F — Thứ tự triển khai đề xuất (làm theo giai đoạn)

| Giai đoạn | Nội dung | Mục tiêu |
|---|---|---|
| **1** | Nối màn **Khoa đăng ký → KDD duyệt** | Trục xương sống — chạy được là cả hệ thống chạy được |
| **2** | Nối **Sản xuất (3 bếp)** + **Danh mục sữa** | Bếp thấy đơn, tính nguyên liệu |
| **3** | Nối **Giao hàng** + **Admin/Báo cáo** + **Đăng nhập phân quyền** | Hoàn chỉnh & bảo mật |

> Khuyến nghị: làm xong và chạy ổn Giai đoạn 1 (1–2 tuần dùng thử thật) rồi mới mở rộng. Tránh nối hết một lúc gây rối, khó tìm lỗi.

---

## Tóm tắt việc cần người kỹ thuật
- Phần **A, B, E** chị/trợ lý tự làm được (bấm nút + dán SQL + kéo thả).
- Phần **C (RLS)** và **D (nối code từng màn)** nên có người biết JavaScript. Em có thể soạn policy mẫu + làm 1 màn mẫu khi chị cần.
```
