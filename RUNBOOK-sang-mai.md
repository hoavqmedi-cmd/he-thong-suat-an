# RUNBOOK — Sáng mai làm lần lượt (~5–10 phút)

> Chị làm theo đúng thứ tự. Mỗi bước xong báo Claude một tiếng để Claude làm phần của mình rồi mới qua bước sau. Không nhảy bước (code và DB phải khớp).

## Việc 1 — Sửa khóa upsert (chống mất món trong cùng cữ)

**Bước 1.1 — Chẩn đoán (chị làm).**
Mở **Supabase → SQL Editor → New query**, dán toàn bộ file `chan-doan-01-khoa-upsert.sql`, bấm **Run**. Gửi Claude kết quả 3 phần A/B/C (chụp màn hình là được).

**Bước 1.2 — Claude đọc kết quả**, xác định khóa thật rồi báo chị có cần dọn trùng không.

**Bước 1.3 — Sửa khóa DB (chị làm).**
Mở `fix-02-khoa-upsert.sql`, chạy theo hướng dẫn trong file (2.1 kiểm tra → 2.4 tạo khóa; chỉ chạy 2.2/2.3 nếu Claude báo cần).

**Bước 1.4 — Đổi code (Claude làm).**
Claude đổi 1 dòng `onConflict` trong `suat-db.js` cho khớp khóa mới `(ma_bn,ngay,cu,loai)`.

**Bước 1.5 — Deploy + test (chị làm).**
Deploy Firebase, mở màn Khoa → đăng ký 1 BN bệnh lý có nhiều món/cữ → kiểm tra KDD nhận đủ món. ⚠️ Phải chạy xong Bước 1.3 TRƯỚC khi deploy, nếu không ghi sẽ lỗi.

## Việc 2 — Chống reset trạng thái khi gửi lại / gửi bổ sung
Sau khi Việc 1 xong, Claude đọc kỹ logic ghi trong `he-thong-suat-an.html`, đề xuất cách sửa (dạng text) để chị duyệt trước khi sửa.

## Việc 3 — Dọn trùng file gốc vs public/
Gom 1 nguồn, deploy từ đúng 1 thư mục. Claude liệt kê file nào giữ/bỏ để chị xác nhận trước khi xóa.

## Việc 4 (Giai đoạn 2) — Bảo mật + realtime
Bật RLS + policy theo 7 vai trò, nối đăng nhập Google, thêm realtime (bỏ F5). Làm sau cùng, trước khi chạy dữ liệu bệnh nhân thật.

---
**Tóm tắt thứ tự:** 1.1 chẩn đoán → 1.3 sửa khóa DB → 1.4 sửa code → 1.5 deploy/test → Việc 2 → Việc 3 → Việc 4.
