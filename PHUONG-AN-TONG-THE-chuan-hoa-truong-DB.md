# Phương án tổng thể — Chuẩn hóa trường dữ liệu & schema

> Hệ thống suất ăn — Căn tin BV Nhi Đồng 1 (Supabase project `ND1 Suat an noi vien`)
> Tổng hợp từ: hội thoại *System structure review*, *Database structure review*, tài liệu API, và **DB thật đọc trực tiếp ngày 29/06/2026**.
> Mục tiêu: thống nhất định nghĩa trường giữa 3 "thế hệ" bảng đang lệch nhau, đưa ra schema đích + lộ trình migration an toàn.

---

## 1. Hiện trạng DB thật (đã kiểm tra trực tiếp)

DB hiện **chỉ có 10 bảng**:

- **2 bảng dữ liệu:** `benh_nhan`, `dang_ky_suat`.
- **8 bảng danh mục:** `dm_nhom_tuoi`, `dm_ma_benh`, `dm_khoa`, `dm_mon_so`, `dm_ma_mon`, `dm_mon_benh_ly`, `dm_cu_an`, `dm_cu_mon` (+ hàm `fn_tao_ma`).

**Cột thật `benh_nhan` (15):** `id, ma_bn, ho_ten, ngay_sinh, khoa, phong, giuong, loai_bn, trang_thai, nguon, ma_benh_ly, chinh_sua(jsonb), gio_xuat(text), ghi_chu, created_at`.

**Cột thật `dang_ky_suat` (34):** `id, ma_bn, ho_ten, khoa, phong, giuong, ngay_sinh, nhom_tuoi(int), ngay, cu(text), buoi, loai, loai_food, loai_suat, ma_che_do, bo_phan, dis, kcal, protein_g, lipid_g, glucid_g, xay, nem, ghi_chu, trang_thai, ly_do_tu_choi, created_at, giao_trang_thai, giao_ly_do, giao_cach_xu_ly, giao_ghi_chu, giao_gio(text), giao_nguoi, giao_cap_nhat`.

> **Lưu ý quan trọng:** các bảng `su_kien_bn` (sự kiện API), `nguoi_dung`, `phan_cong_*`, `giao_*` (bảng riêng) **được thiết kế trong file SQL nhưng CHƯA tạo trên DB**. Giao hàng hiện đang là **cột inline trên `dang_ky_suat`** (`giao_*`), không phải bảng riêng — đây là một điểm lệch giữa file SQL và DB thật.

## 2. Vấn đề cốt lõi

Trường dữ liệu đang định nghĩa theo **3 thế hệ chưa nối khóa với nhau**:

1. **Bảng cũ** (`benh_nhan`, `dang_ky_suat`): text tự do, mã tự chế (`com_dv`), giờ dạng text, khoa lưu tên.
2. **Bảng sự kiện** (`su_kien_bn` — mới thiết kế, chưa tạo): chuẩn hơn, `timestamptz`.
3. **Danh mục mới** (`dm_*`): mã chuẩn hóa (K01, CPDV, '01'..'11') — nhưng bảng dữ liệu **không tham chiếu** tới.

Hệ quả: không join được danh mục với dữ liệu, dễ sai mã, khó báo cáo, và khi nối API HIS sẽ vênh.

## 3. Nguyên tắc thiết kế thống nhất (đề xuất)

1. **Mọi trường phân loại → tham chiếu danh mục `dm_*` bằng mã** (FK), không lưu text tự do.
2. **Một khái niệm — một tên cột — một kiểu** trên toàn hệ thống.
3. **DV/BL gán ở mức SUẤT** (`dang_ky_suat`), không ở mức bệnh nhân; `benh_nhan.loai_bn` chỉ là ảnh chụp loại phòng hiện tại.
4. **Mọi mốc thời gian → `timestamptz`** (bỏ giờ dạng text).
5. **Suất ăn tham chiếu khung cữ chuẩn 11 cữ** (`dm_cu_an`); cữ dịch vụ là tập con (06:00=`02`, 11:00=`04`, 17:00=`08`).
6. **Số lượng + đơn vị** lấy đơn vị từ danh mục (`suất`/`ml`), không tạo cột rời rạc cho từng đơn vị.

## 4. Từ điển trường chuẩn (canonical)

| Khái niệm | Tên cột chuẩn | Kiểu | Giá trị / FK | Dùng ở bảng |
|---|---|---|---|---|
| Mã bệnh nhân | `ma_bn` | text | duy nhất | benh_nhan, dang_ky_suat, su_kien_bn |
| Khoa | `ma_khoa` | text | FK → `dm_khoa.ma` (K01–K21) | benh_nhan, dang_ky_suat |
| Loại phòng / loại suất | `loai_suat` | text | `DV` \| `BL` | dang_ky_suat (mức suất) |
| Nhóm tuổi | `nhom_tuoi` | smallint | 1–5, khớp `dm_nhom_tuoi` | dang_ky_suat |
| Mã món | `ma_mon` | text | FK → `dm_ma_mon.ma` | dang_ky_suat |
| Cữ | `cu_so` | text | FK → `dm_cu_an.so` ('01'–'11') | dang_ky_suat |
| Số lượng | `so_luong` | numeric | đơn vị lấy từ `dm_ma_mon.don_vi` | dang_ky_suat |
| Mã chế độ ăn | `ma_che_do` | text | quy tắc `fn_tao_ma` | dang_ky_suat |
| Mã bệnh lý | `ma_benh_ly` | text | FK → `dm_ma_benh.ma`; **do khoa nhập, không từ API** | benh_nhan |
| Mốc giờ sự kiện | `gio_nhap_vien` / `gio_chuyen_phong` / `gio_xuat_vien` | timestamptz | — | su_kien_bn |

## 5. Quyết định cho 8 điểm lệch

Ký hiệu: ✅ = em đề xuất rõ · ❓ = **cần chị chốt nghiệp vụ**.

**① Khoa — mã vs tên.** ✅ Chuyển sang lưu `ma_khoa` (FK `dm_khoa`). Thêm cột `ma_khoa`, backfill từ tên hiện có (cần bảng ánh xạ tên→mã vì tên cũ như "Nhi Tổng hợp" không khớp tên chuẩn HIS). Giữ cột `khoa` text tới khi backfill xong rồi bỏ.

**② Nhóm tuổi — kiểu.** ✅ Chuẩn `nhom_tuoi smallint` (1–5). Bổ sung cột số vào `dm_nhom_tuoi` (hoặc ép kiểu khi join) để khớp.

**③ Mã món — 2 hệ ký hiệu.** ✅ Lấy `dm_ma_mon` làm chuẩn. Thay `dang_ky_suat.loai` (`com_dv`…) bằng `ma_mon` (FK). Ánh xạ: `com_dv→CPDV`, `chao_dv→ChPDV`, `com_bl→Cơm`, `chao_bl→Cháo`. `loai_food`/`loai_suat` suy ra từ `dm_ma_mon`.

**④ Món bệnh lý — 5 vs 4 món.** ❓ App cũ tách `sua_bt`/`sua_db`/`sonde`; danh mục có `sua`/`sup`. Đề xuất: **sữa để 1 món, phân thường/đặc biệt ở mức MÃ SỮA** (SUA0xx — đúng logic Tab 4 KDD); thống nhất tên **"Súp Sonde" = sonde = sup**. → Cần chị xác nhận: tách sữa ở mức món hay mức mã?

**⑤ Cữ — 3 cữ vs 11 cữ.** ✅ Chuẩn hóa về **11 cữ** (`dm_cu_an`); cữ dịch vụ là tập con. Thay `cu(text giờ)+buoi` bằng `cu_so` (FK). `buoi` suy ra từ cữ.

**⑥ DV/BL đặt sai tầng.** ✅ `loai_suat` (mức suất) là chuẩn; `benh_nhan.loai_bn` chỉ là ảnh chụp loại phòng hiện tại. Suy `loai_suat` từ `dm_ma_mon` để khỏi lệch.

**⑦ Giờ text vs timestamptz.** ✅ Mọi giờ → `timestamptz`. `benh_nhan.gio_xuat(text)` và `dang_ky_suat.giao_gio(text)` → chuyển sang timestamptz (hoặc đưa giờ sự kiện về bảng `su_kien_bn`), rồi bỏ cột text cũ.

**⑧ Thiếu cột `ml`.** ✅ Thêm `so_luong numeric` vào `dang_ky_suat` (đơn vị lấy theo `dm_ma_mon.don_vi` = suất/ml) — phục vụ cả sữa/súp (ml) lẫn cơm/cháo (suất). Đồng thời giải quyết trường `so_luong` mà tài liệu API đang thiếu.

## 6. Hai việc cấu trúc cần chốt thêm

**A. Giao hàng — cột inline hay bảng riêng?** ❓ DB thật đang để `giao_*` **inline trên `dang_ky_suat`**, nhưng file SQL lại thiết kế bảng `phan_cong_*`/`giao_*` riêng (màn phân-công-giám-sát). Cần chốt một hướng để không vênh (bộ nhớ dự án đã cảnh báo màn này từng dùng tên bảng sai).

**B. Lớp API/sự kiện.** ✅ Tạo bảng `su_kien_bn` (event log: `event_id` duy nhất, `event_type`, `gio_*` timestamptz, `ma_bn`, `loai_phong`, `payload jsonb`, kết quả áp dụng) + thêm `gioi_tinh` vào `benh_nhan`. Đây là tầng nối HIS (theo tài liệu API).

## 7. Lộ trình migration an toàn (đề xuất, chưa thực thi)

1. **Giai đoạn 0 — chốt nghiệp vụ:** trả lời ④, ⑤(xác nhận), ⑥, và A (giao hàng). 
2. **Giai đoạn 1 — thêm cột mới song song** (không xóa cột cũ): `ma_khoa`, `ma_mon`, `cu_so`, `so_luong`, `gioi_tinh`, các cột `timestamptz`. App vẫn chạy bình thường.
3. **Giai đoạn 2 — backfill dữ liệu** từ cột cũ sang cột chuẩn (ánh xạ khoa, mã món, cữ, giờ).
4. **Giai đoạn 3 — chuyển app** đọc/ghi theo cột chuẩn + thêm **khóa ngoại** về `dm_*`.
5. **Giai đoạn 4 — dọn cột cũ** (`loai`, `cu`, `buoi`, `gio_xuat`, `giao_gio` text…) sau khi xác nhận ổn.
6. **Giai đoạn 5 — bật RLS + policy** theo vai trò (bắt buộc trước khi có dữ liệu bệnh nhân thật + nối API HIS). *Hiện toàn bộ đang TẮT RLS.*

> **Em chưa thực thi thay đổi nào trên DB.** Migration đụng dữ liệu thật và RLS đang tắt → cần chị duyệt từng giai đoạn trước khi chạy.

## 8. Việc cần chị quyết (tổng hợp các ❓)

1. **Khoa:** đồng ý chuyển sang lưu mã `ma_khoa` (FK `dm_khoa`)? HIS có gửi mã khoa chuẩn không?
2. **Sữa:** tách thường/đặc biệt ở **mức món** hay **mức mã sữa** (SUA0xx)? "Súp Sonde" = "sonde" = "sup" — đúng không?
3. **Cữ:** thống nhất dùng khung **11 cữ** (`dm_cu_an`) cho cả dịch vụ lẫn bệnh lý?
4. **Giao hàng:** giữ `giao_*` **inline trên `dang_ky_suat`**, hay tách **bảng riêng**?

Chị trả lời 4 điểm này là em viết được **migration SQL từng giai đoạn** + cập nhật tài liệu API cho khớp schema chuẩn.
