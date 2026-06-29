# RULES NGHIỆP VỤ SUẤT ĂN — Căn tin BV Nhi Đồng 1 (luồng dịch vụ)

> Tài liệu quy tắc nghiệp vụ chuẩn cho việc tạo/cắt suất ăn dịch vụ.
> Cập nhật: 28/06/2026. Liên quan: `YEU-CAU-API-nhan-thong-tin-suat-an.md`, `LOGIC-man-hinh-KDD.md`.

---

## 1. Phạm vi & nguyên tắc chung

Bệnh viện (HIS) **chỉ gửi qua API** đúng các thông tin sau:

- Định danh bệnh nhân (mã BN / thông tin định danh).
- Vị trí: **khoa / phòng / giường**.
- **Loại phòng: thường hoặc dịch vụ** — yếu tố quyết định tạo/cắt suất.
- **Sự kiện** (xem mục 2).
- **Giờ chính xác** của sự kiện.

Mọi chi tiết suất ăn — **cơm/cháo, số lượng, chế độ ăn, người đặt, SĐT** — do **nội bộ căn tin nhập**, không lấy từ bệnh viện.

Nguyên tắc gốc: **Loại phòng quyết định có suất hay không. Giờ sự kiện quyết định cữ nào còn kịp cắt.**

---

## 2. Ba sự kiện & quy tắc tạo / cắt suất

Bệnh viện gửi 3 loại sự kiện: `them_moi`, `chuyen_phong`, `xuat_vien`.

| Tình huống | Hành động với suất |
|---|---|
| Thêm mới vào phòng **dịch vụ** | **Tạo** suất |
| Chuyển **Thường → Dịch vụ** | **Tạo** suất |
| Rời phòng **dịch vụ** (xuất viện / chuyển đi) | **Cắt** suất (theo hạn cữ — mục 4, 5) |
| Chuyển **Dịch vụ → Dịch vụ** | **Giữ** suất, chỉ **đổi điểm giao** |
| Chuyển **Thường → Thường** | **Bỏ qua** (không liên quan suất dịch vụ) |

---

## 3. Xuất viện

Áp dụng cho **ngày xuất viện**:

- **Cơm sáng:** tính bình thường.
- **Cơm trưa:** **vẫn giao & vẫn tính** — vì BN thường còn ở lại làm thủ tục / chờ xe.
- **Cơm chiều:** **cắt**.
- **Từ ngày hôm sau:** không còn suất.

> Đây là quy tắc đơn giản hóa, ưu tiên không thất thoát suất trưa đã chuẩn bị.

---

## 4. Chuyển Dịch vụ → Thường

Cắt suất **theo hạn từng cữ** trong ngày chuyển:

| Cữ | Hạn cắt |
|---|---|
| Sáng | **15:00 hôm trước** |
| Trưa | **09:00 cùng ngày** |
| Chiều | **15:00 cùng ngày** |

**Quá hạn → vẫn nấu, vẫn tính** (suất đã vào kế hoạch bếp, không hủy được).

---

## 5. Chốt cứng (rule ưu tiên cao nhất)

> **Mọi cữ thuộc ngày SAU ngày xuất viện / ngày chuyển phòng đều bị HỦY** — kể cả cữ sáng đã khóa từ 15:00 hôm trước.

Hạn cắt ở mục 4 **chỉ điều chỉnh các cữ TRONG NGÀY** diễn ra sự kiện. Không có suất nào được phép kéo sang ngày hôm sau khi BN đã rời phòng dịch vụ.

---

## 6. Đổi loại món (KHÔNG qua API)

Đổi cơm ↔ cháo, sữa, sonde… là thao tác **nội bộ: khoa → KDD**, thực hiện theo **giờ khóa buổi**:

| Cữ | Giờ khóa |
|---|---|
| Sáng | **15:00 hôm trước** |
| Trưa | **09:00 cùng ngày** |
| Chiều | **15:00 cùng ngày** |

Quá giờ khóa thì không đổi được cho cữ đó. **Việc đổi món không đi qua API bệnh viện.**

---

## 7. Bảng giờ khóa từng cữ (tra nhanh)

| Cữ | Giờ khóa cắt / đổi |
|---|---|
| **Sáng** | 15:00 ngày hôm trước |
| **Trưa** | 09:00 cùng ngày |
| **Chiều** | 15:00 cùng ngày |

Áp dụng cho: cắt suất khi chuyển DV→Thường (mục 4) và đổi loại món nội bộ (mục 6).
**Lưu ý:** rule chốt cứng (mục 5) **luôn thắng** bảng giờ khóa này khi sự kiện rơi vào ngày trước đó.

---

## 8. Đang chờ bệnh viện xác nhận

Các điểm chưa chốt với HIS, cần làm rõ trước khi dựng endpoint thật:

- **Cơ chế truyền tin:** webhook push hay polling.
- **Cơ chế xác thực** API (key / token / chữ ký…).
- **Danh mục mã khoa / phòng** chuẩn để map loại phòng (thường/dịch vụ).

> Khi dựng endpoint thật, schema `dang_ky_suat` cần bổ sung cột: `gioi_tinh`, `gio_nhap_vien`, `so_luong`, `nguoi_dat`/`sdt`.
