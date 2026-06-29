# Hướng dẫn chạy thật & test — Giai đoạn 1 (cơm/cháo)

> Nối thật 2 màn có sẵn vào Supabase: **Khoa đăng ký → KDD duyệt**.
> Phạm vi: cơm/cháo (DV). Sữa/sonde để Giai đoạn 2.

## File liên quan (đặt CHUNG 1 thư mục)

| File | Vai trò |
|---|---|
| `supabase-config.js` | **Chỉ sửa file này** — dán URL + key |
| `suat-db.js` | Lớp kết nối dùng chung (không sửa) |
| `supabase-schema-giaidoan1.sql` | SQL tạo bảng — dán vào Supabase |
| `he-thong-suat-an.html` | Màn Khoa lâm sàng (đã nối ghi DB) |
| `man-hinh-kdd.html` | Màn KDD (đã nối đọc/duyệt DB) |

## Các bước test (làm 1 lần)

**B1. Tạo project & bảng**
1. Tạo project Supabase (xem `CHECKLIST-chay-Supabase.md` phần A).
2. Vào **SQL Editor** → dán toàn bộ `supabase-schema-giaidoan1.sql` → **Run**.

**B2. Dán khóa kết nối**
1. Supabase → **Project Settings → API**, copy **Project URL** và **anon public** key.
2. Mở `supabase-config.js`, thay 2 dòng `DAN_..._VAO_DAY` bằng giá trị thật. Lưu lại.

**B3. Test ghi (màn Khoa)**
1. Mở `he-thong-suat-an.html` bằng trình duyệt.
2. Tab **Dịch vụ** → đảm bảo có vài BN trạng thái "Đã xác nhận".
3. Vào tab **Dịch vụ**, bấm nút **Gửi** một buổi (hoặc tab Gửi dinh dưỡng). Sẽ hiện toast `✓ Đã ghi N suất lên hệ thống`.
4. Kiểm tra: Supabase → **Table Editor → dang_ky_suat** → thấy các dòng mới, `trang_thai = khoa_gui`.

**B4. Test đọc & duyệt (màn KDD)**
1. Mở `man-hinh-kdd.html`. Góc trên hiện **🟢 SUPABASE (chạy thật)** (nếu hiện ⚪ DEMO → chưa cấu hình đúng config).
2. Tab **Cữ chờ xử lý** → thấy các cữ chứa suất vừa gửi từ màn Khoa.
3. Bấm **Duyệt & gửi nhanh** (hoặc mở chi tiết → Gửi).
4. Kiểm tra: trong Supabase, các dòng đó đổi `trang_thai = da_gui_sx`. Nếu từ chối 1 BN (bỏ tick + nhập lý do) → dòng đó `trang_thai = kdd_tu_choi`, có `ly_do_tu_choi`.

→ Khoa nhập máy này, KDD máy khác mở thấy ngay = **chạy thật end-to-end**. ✅

## Chế độ DEMO (khi chưa cấu hình)

Khi `supabase-config.js` còn để nguyên `DAN_..._VAO_DAY`, cả 2 màn **tự chạy dữ liệu mẫu như cũ**, không cần internet DB. Tiện để xem giao diện mà không cần Supabase.

## Giới hạn đã biết của Giai đoạn 1 (cần lưu ý)

1. **Chỉ cơm/cháo.** Sữa BT/ĐB và soup sonde chưa ghi DB (Giai đoạn 2). Trong màn KDD chế độ thật sẽ chỉ thấy cơm/cháo.
2. **Gửi lại buổi = tạo dòng mới** (chưa chống trùng). Test xong nên xóa dữ liệu thử trong Table Editor.
3. **RLS đang TẮT** để chạy ngay. Trước khi dùng dữ liệu bệnh nhân thật phải bật RLS + policy (báo em khi tới bước này).
4. **Mở bằng file://** đôi khi bị chặn nạp `suat-db.js`. Nếu gặp lỗi, chạy qua máy chủ tĩnh đơn giản (Netlify Drop, hoặc `python -m http.server` trong thư mục) rồi mở qua `http://`.

## Khi cần em làm tiếp
- Bật RLS + policy theo 7 vai trò.
- Giai đoạn 2: thêm sữa/sonde vào màn Khoa + nối DB.
- Chống trùng khi gửi lại; thêm bảng bệnh nhân/người dùng chuẩn hóa.
