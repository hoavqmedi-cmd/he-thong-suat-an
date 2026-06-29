# Tổng hợp vai trò & file mockup

> Hệ thống nhận thông tin suất ăn — Căn tin Bệnh viện Nhi Đồng 1
> Bản đồ tham chiếu: 7 vai trò → 5 khung màn → file đã tạo. Cập nhật: 28/06/2026.

## 1. Luồng tổng thể

```
Khoa lâm sàng → KDD duyệt/gửi → Bếp & Phòng sản xuất → Người giao → Giường bệnh
                                                         (Admin giám sát toàn bộ)
```

Nguyên tắc: đơn vị xử lý = **CỮ**; KDD duyệt 1 lần, hệ thống **tự tách 3 bộ phận** (Bếp dịch vụ · Bếp cơm bệnh lý · Phòng sữa-soup).

## 2. Bản đồ vai trò ↔ file mockup

| # | Vai trò | Khung màn | File mockup đã tạo | Trạng thái |
|---|---|---|---|---|
| 1 | **Khoa lâm sàng** | Đăng ký suất ăn (DV + bệnh lý) | `he-thong-suat-an.html` · `unified-app.jsx` (nguồn React) | ✅ Có mockup |
| 2 | **KDD** | Duyệt & chuyển SX + Danh mục sữa | `man-hinh-kdd.html` · `man-hinh-kdd.jsx` (nguồn) | ✅ Có mockup *(nghiệp vụ xử lý ở hội thoại riêng)* |
| 3 | **Bếp dịch vụ** | Sản xuất (dùng chung) | `man-san-xuat.html` (popup in tem: `tem-k80.html`) | ✅ Có mockup |
| 4 | **Bếp cơm bệnh lý** | Sản xuất (dùng chung) | (cùng `man-san-xuat.html` — chọn bộ phận) | ✅ Dùng chung |
| 5 | **Phòng sữa-soup** | Sản xuất + tính nguyên liệu | (cùng `man-san-xuat.html`) | ✅ Dùng chung |
| 6 | **Người giao** | Giao suất tới giường — **CHỈ Bếp dịch vụ** | `giao-hang-bep-dich-vu.html` (+ data `_c.js`) | ✅ Có mockup |
| — | **Phân công & giám sát giao** | Lớp quản lý người giao — **CHỈ Bếp dịch vụ** | `quan-ly-phan-cong-giam-sat.html` (+ data `_q.js`) | ✅ Có mockup |

> **Lưu ý phạm vi giao hàng:** chỉ **Bếp dịch vụ** có người giao & theo dõi quá trình giao. **Bếp cơm bệnh lý** và **Phòng sữa-soup** KHÔNG có người giao — kết thúc luồng ở bước "đã nấu xong", không theo dõi giao.
| 7 | **Admin tổng** | Dashboard · Báo cáo · Phân quyền · Dữ liệu nền · Nhật ký | `man-hinh-quan-tri.html` | ✅ Có mockup |

## 3. Tài liệu đặc tả (logic / yêu cầu)

| File | Nội dung |
|---|---|
| `LOGIC-man-hinh-KDD.md` | Đặc tả màn KDD (4 tab) + mục 12 Danh mục sữa |
| `YEU-CAU-man-hinh-quan-tri.md` | Yêu cầu màn Admin (2 cấp, 5 module, xuất Excel) |
| `Meeting_Note_Kickoff.docx` | Biên bản kickoff |
| `Cau_hoi_phong_van_quy_trinh_suat_an.docx` | Bộ câu hỏi phỏng vấn quy trình |
| `TONG-HOP-vai-tro-va-mockup.md` | (File này) bản đồ vai trò ↔ file |

## 4. Điểm cần lưu ý / dọn dẹp

- **`tem-k80.html` là popup in tem K80** (mở khi bếp bấm "in tem" trong `man-san-xuat.html`) — không phải màn sản xuất riêng.
- **Người giao chỉ áp dụng cho Bếp dịch vụ.** Bếp cơm bệnh lý & Phòng sữa-soup **không có người giao / không theo dõi quá trình giao** → cần **bỏ tab "theo dõi giao"** cho 2 bộ phận này trong `man-san-xuat.html` (luồng kết thúc ở "đã nấu xong").
- **KDD & Khoa lâm sàng** đang có cả `.jsx` (nguồn) lẫn `.html` (đóng gói) — dễ lệch; nên chốt 1 dạng nguồn.
- **File dữ liệu phụ:** `_c.js` (data màn giao) · `_q.js` (data màn phân công) — là seed mẫu, không phải màn độc lập.

## 5. Trạng thái theo vai trò

| Vai trò | Mockup | Đặc tả logic | Ghi chú |
|---|---|---|---|
| Khoa lâm sàng | ✅ | — | nghiệp vụ chi tiết: hội thoại riêng |
| KDD | ✅ | ✅ (LOGIC-man-hinh-KDD.md) | nghiệp vụ chi tiết: hội thoại riêng |
| Sản xuất (3 bếp) | ✅ (+ popup in tem K80) | nháp | bỏ "theo dõi giao" ở bếp BL & sữa-soup |
| Người giao | ✅ (chỉ Bếp DV) | nháp (chưa chốt 4 điểm) | chỉ Bếp dịch vụ có giao |
| Admin | ✅ | ✅ (YEU-CAU-man-hinh-quan-tri.md) | đã chốt |

## 6. Quyết định khung chung (đã chốt)

- Chưa có dev → **demo trên cloud trước**.
- **Hoàn thiện mockup** đủ vai trò rồi mới nối backend.
- Phạm vi: **riêng Nhi Đồng 1** (chưa đa điểm bán).
- Báo cáo **xuất Excel**; **có Admin phụ**; nhật ký **chỉ mốc chính**.
