# Kế hoạch: Chuẩn hóa cấu trúc dữ liệu — Hệ thống suất ăn nội viện

## Context (vì sao làm)

App đặt suất ăn nội viện (BV Nhi Đồng 1, React CDN + Supabase) hiện có **3 "thế hệ" trường dữ liệu lệch nhau**: bảng dữ liệu (`benh_nhan`, `dang_ky_suat`) lưu text tự do / mã tự chế / giờ dạng text, trong khi 8 bảng danh mục `dm_*` đã chuẩn hóa (mã khoa K01–K21, mã món, khung 11 cữ, mã sữa) nhưng **bảng dữ liệu không tham chiếu tới**. Hệ quả: không join được danh mục, dễ sai mã, khó báo cáo, và sẽ vênh khi nối API HIS.

Mục tiêu: đưa `benh_nhan` + `dang_ky_suat` về tham chiếu danh mục bằng **khóa ngoại (FK)**, thống nhất "một khái niệm — một cột — một kiểu", theo lộ trình **không gây gián đoạn app đang chạy**.

Tài liệu gốc: `PHUONG-AN-TONG-THE-chuan-hoa-truong-DB.md`. **4 quyết định nghiệp vụ đã chốt** (29/06/2026):
1. **Khoa** → lưu mã `ma_khoa` (FK `dm_khoa`).
2. **Sữa** → 1 món `"Sữa"`; phân thường/đặc trị ở **mức mã sữa** (`dm_ma_sua.loai`). Thống nhất tên `"Súp Sonde" = sonde = sup`.
3. **Cữ** → dùng khung **11 cữ** (`dm_cu_an`); cữ dịch vụ là tập con (02=06:00, 04=11:00, 08=17:00).
4. **Giao hàng** → giữ **inline** trên `dang_ky_suat` (cột `giao_*`), không tách bảng.

## Từ điển ánh xạ chuẩn (cột cũ → cột chuẩn)

| Khái niệm | Cột cũ | Cột chuẩn (mới) | FK / Ánh xạ |
|---|---|---|---|
| Khoa | `khoa` (text tên) | `ma_khoa` text | → `dm_khoa.ma`; cần bảng ánh xạ tên→mã |
| Mã món | `loai` (`com_dv`…) | `ma_mon` text | → `dm_ma_mon.ma`: `com_dv→CPDV`, `chao_dv→ChPDV`, `com_bl→Cơm`, `chao_bl→Cháo` |
| Cữ | `cu`(text giờ)+`buoi` | `cu_so` text | → `dm_cu_an.so`; `06:00→02`, `11:00→04`, `17:00→08`; `buoi` suy ra từ cữ |
| Số lượng | (thiếu) | `so_luong` numeric | đơn vị lấy `dm_ma_mon.don_vi` (suất/ml) |
| Loại suất | `loai_suat` | `loai_suat` (giữ) | suy ra từ `dm_ma_mon.loai_suat` để khỏi lệch |
| Giờ xuất viện | `benh_nhan.gio_xuat` text | `gio_xuat_vien` timestamptz | bỏ cột text sau backfill |
| Giờ giao | `dang_ky_suat.giao_gio` text | `giao_gio_ts` timestamptz | bỏ cột text sau backfill |
| Giới tính | (thiếu) | `benh_nhan.gioi_tinh` text | phục vụ nối HIS |

**Hệ quả danh mục (quyết định #2):** gộp 2 món `"Sữa thường"`/`"Sữa đặc trị"` → 1 món `"Sữa"`; đổi `"Sonde"` → `"Súp Sonde"`. Việc này đụng `dm_ma_mon`, `dm_cu_mon`, và `danh-muc.js` (`MON_LOAI`, `cuChoMon`, logic chọn món ở màn Khoa/KDD).

## Lộ trình thực thi (theo giai đoạn, mỗi giai đoạn là 1 checkpoint duyệt)

Mỗi file SQL chạy thủ công trong **Supabase → SQL Editor → Run** (như CHECKLIST hiện có). App vẫn chạy bình thường qua G1–G2 vì chỉ **thêm** cột, chưa bỏ gì.

### Giai đoạn 1 — Thêm cột chuẩn song song (additive, an toàn)
**File mới:** `migrate-chuanhoa-g1-them-cot.sql`
- `alter table benh_nhan add column if not exists ma_khoa text, add column if not exists gioi_tinh text, add column if not exists gio_xuat_vien timestamptz;`
- `alter table dang_ky_suat add column if not exists ma_khoa text, add column if not exists ma_mon text, add column if not exists cu_so text, add column if not exists so_luong numeric, add column if not exists giao_gio_ts timestamptz;`
- Chưa thêm FK constraint (để backfill trước, tránh chặn ghi). Không sửa app.

### Giai đoạn 2 — Backfill dữ liệu cũ sang cột chuẩn
**File mới:** `migrate-chuanhoa-g2-backfill.sql`
- Tạo bảng ánh xạ tạm `map_khoa_ten(ten_cu text, ma text)` cho các tên khoa cũ không khớp `dm_khoa.ten` (vd "Nhi Tổng hợp"); `update ... set ma_khoa = ...` theo map + theo `dm_khoa.ten`.
- `update dang_ky_suat set ma_mon = case loai when 'com_dv' then 'CPDV' when 'chao_dv' then 'ChPDV' when 'com_bl' then 'Cơm' when 'chao_bl' then 'Cháo' end ...`
- `update dang_ky_suat set cu_so = case cu when '06:00' then '02' when '11:00' then '04' when '17:00' then '08' end ...`
- `so_luong`: mặc định 1 cho món `suất`; để NULL cho `ml` (KDD/sản xuất nhập sau). `giao_gio_ts`/`gio_xuat_vien`: parse từ text nếu có.
- **Query kiểm tra** cuối file: đếm dòng còn `ma_khoa/ma_mon/cu_so IS NULL` để soát sót trước khi qua G3.

### Giai đoạn 3 — Chuyển app đọc/ghi cột chuẩn + thêm FK
Sau khi G2 sạch (0 dòng sót). **Sửa code:**
- `suat-db.js`:
  - `insert()`: đổi `onConflict: "ma_bn,ngay,cu,loai"` → `"ma_bn,ngay,cu_so,ma_mon"`; ghi kèm `ma_mon`, `cu_so`, `so_luong`, `ma_khoa`.
  - Bổ sung helper đọc danh mục FK nếu cần.
- `danh-muc.js`: gộp món Sữa (`MON_LOAI`), đổi `"Sonde"→"Súp Sonde"`; cập nhật `cuChoMon`/`MEAL_SESSIONS` cho khớp; thêm helper map `loai↔ma_mon`, `cu↔cu_so` để các màn dùng chung khi chuyển đổi.
- **Màn Khoa** `public/he-thong-suat-an.html`: khi tạo dòng suất, ghi `ma_mon`/`cu_so`/`so_luong`/`ma_khoa` (thay vì `loai`/`cu`/`buoi`); dropdown khoa lưu mã; dropdown món theo món gộp.
- **Màn KDD** `public/man-hinh-kdd.html`: đọc/hiển thị theo `ma_mon`/`cu_so` (join danh mục để ra tên); nhập `so_luong` (ml) cho sữa/súp.
- **Màn Sản xuất / Giao** `public/man-san-xuat.html`, `public/giao-hang-bep-dich-vu.html`, `public/quan-ly-phan-cong-giam-sat.html`: hiển thị theo cột chuẩn; ghi `giao_gio_ts` (timestamptz). Giao hàng vẫn inline.
- **Màn Quản trị** `public/man-hinh-quan-tri.html`: báo cáo join `dm_*` theo mã.
- **File SQL** `migrate-chuanhoa-g3-fk.sql`: thêm `foreign key` từ `dang_ky_suat.ma_khoa/ma_mon/cu_so` và `benh_nhan.ma_khoa` về `dm_*` (sau khi app đã ghi đúng).

*Pattern lặp lại ở 5 màn:* ở đâu đang đọc `row.loai`/`row.cu`/`row.buoi`/`row.khoa` để hiển thị → chuyển sang `row.ma_mon`/`row.cu_so`/`row.ma_khoa` + tra danh mục lấy tên. Đại diện: `he-thong-suat-an.html`, `man-hinh-kdd.html`, `man-san-xuat.html`.

### Giai đoạn 4 — Dọn cột cũ (sau khi G3 chạy ổn ≥ 1 chu kỳ)
**File mới:** `migrate-chuanhoa-g4-dondep.sql`
- `alter table dang_ky_suat drop column loai, drop column cu, drop column buoi, drop column khoa, drop column giao_gio;`
- `alter table benh_nhan drop column khoa, drop column gio_xuat;`
- Chỉ chạy sau khi xác nhận không còn code nào tham chiếu cột cũ.

### Giai đoạn 5 — (Tùy chọn, nền tảng HIS) bảng sự kiện + RLS
- **File mới** `migrate-chuanhoa-g5-sukien.sql`: tạo `su_kien_bn` (`event_id` unique, `event_type`, `gio_*` timestamptz, `ma_bn`, `loai_phong`, `payload jsonb`, kết quả áp dụng) — tầng nối HIS.
- **RLS:** soạn policy theo vai trò trước khi có dữ liệu bệnh nhân thật. *(Hiện toàn bộ TẮT RLS — đây là việc bảo mật bắt buộc, làm riêng khi sẵn sàng.)*

## Files sẽ tạo / sửa
- **Tạo (SQL):** `migrate-chuanhoa-g1-them-cot.sql`, `g2-backfill.sql`, `g3-fk.sql`, `g4-dondep.sql`, `g5-sukien.sql` (đặt ở thư mục gốc dự án cạnh các `migrate-*.sql` hiện có).
- **Sửa (code, ở G3):** `suat-db.js`, `danh-muc.js`, `public/he-thong-suat-an.html`, `public/man-hinh-kdd.html`, `public/man-san-xuat.html`, `public/giao-hang-bep-dich-vu.html`, `public/quan-ly-phan-cong-giam-sat.html`, `public/man-hinh-quan-tri.html`.
- **Cập nhật tài liệu:** đánh dấu 4 quyết định đã chốt trong `PHUONG-AN-TONG-THE-chuan-hoa-truong-DB.md`; cập nhật `YEU-CAU-API-*.md` cho khớp cột chuẩn.

## Kiểm thử (verify)
1. **Sau G1:** chạy SQL, mở app — phải chạy y như cũ (cột mới rỗng, không ảnh hưởng).
2. **Sau G2:** chạy query kiểm tra trong file → `ma_khoa/ma_mon/cu_so` không còn NULL; spot-check vài bệnh nhân thật khớp danh mục.
3. **Sau G3:** mở từng màn (Khoa → KDD → Sản xuất → Giao → Quản trị):
   - Khoa đăng ký 1 suất cơm DV + 1 suất sữa BL → kiểm tra dòng ghi xuống `dang_ky_suat` có `ma_mon`/`cu_so`/`so_luong` đúng.
   - KDD thấy đúng tên chế độ (join danh mục), duyệt → trạng thái chuyển.
   - Báo cáo Quản trị join `dm_*` ra đúng tên khoa/món.
   - Test upsert: gửi lại cùng suất → ghi đè, không tạo trùng (onConflict mới).
4. **Sau G4:** app vẫn chạy đủ luồng end-to-end; không lỗi "column does not exist".

## Rủi ro & lưu ý
- **Migration đụng dữ liệu thật + RLS đang TẮT** → chạy từng giai đoạn, duyệt trước mỗi bước; backup (export) bảng trước G2/G4.
- Tên khoa cũ có thể không khớp `dm_khoa.ten` → cần bảng ánh xạ thủ công ở G2 (rà soát danh sách tên khoa thực tế trong DB trước).
- Gộp món Sữa (#2) đụng nhiều nơi trong `danh-muc.js` và 2 màn → test kỹ phần chọn món sữa & sonde.
- Không có công cụ chạy SQL tự động ở đây → các file SQL do bạn dán chạy trong Supabase SQL Editor; chuẩn bị sẵn nội dung + query kiểm tra.
