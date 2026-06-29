# Yêu cầu tích hợp API — Nhận thông tin bệnh nhân cho luồng suất ăn dịch vụ

> Hệ thống nhận thông tin suất ăn — Căn tin Bệnh viện Nhi Đồng 1
> Tài liệu gửi: Bộ phận CNTT Bệnh viện & đơn vị phát triển (dev)
> Phiên bản: 1.0 — Ngày: 28/06/2026

---

## 1. Mục đích

Hệ thống suất ăn của căn tin cần **tự động nhận thông tin bệnh nhân từ bệnh viện qua API** để quản lý việc **tạo và cắt suất ăn dịch vụ** mà không phải nhập tay. Việc một bệnh nhân có được phục vụ suất ăn dịch vụ hay không phụ thuộc vào **loại phòng** (thường / dịch vụ) và các sự kiện nhập viện, chuyển phòng, xuất viện.

## 2. Mô hình tích hợp

| Vai trò | Đơn vị | Mô tả |
|---|---|---|
| Bên gửi (sender) | **Bệnh viện** | Phát sinh sự kiện bệnh nhân và đẩy sang hệ thống suất ăn |
| Bên nhận (receiver) | **Hệ thống suất ăn căn tin** | Tiếp nhận, lưu trữ, tự động tạo/cắt suất theo quy tắc |

**Phương thức đề xuất (cần bệnh viện xác nhận khả năng đáp ứng):**

- Giao thức: **REST API qua HTTPS**, dữ liệu định dạng **JSON**.
- Cơ chế: bệnh viện **chủ động đẩy (webhook push)** mỗi khi có sự kiện, gọi tới một địa chỉ (endpoint) do hệ thống suất ăn cung cấp.
- Phương án thay thế nếu bệnh viện không đẩy được: hệ thống suất ăn **gọi sang lấy định kỳ (polling)** — cần bệnh viện mở API truy vấn danh sách sự kiện theo khoảng thời gian.
- Xác thực: **API key / token** đặt trong phần đầu (header) của mỗi yêu cầu.

## 3. Phân định nguồn dữ liệu

Để tránh nhầm lẫn phần nào yêu cầu bệnh viện gửi, phần nào hệ thống tự xử lý:

| Nhóm dữ liệu | Nguồn |
|---|---|
| Định danh bệnh nhân (mã BN, họ tên, ngày sinh) | **Bệnh viện gửi qua API** |
| Vị trí (khoa, phòng, giường) + **loại phòng** | **Bệnh viện gửi qua API** |
| Sự kiện (nhập viện / chuyển phòng / xuất viện) + **giờ chính xác** | **Bệnh viện gửi qua API** |
| Chi tiết suất ăn (cơm/cháo, số lượng, chế độ, ghi chú, người đặt, SĐT) | **Hệ thống nội bộ tự nhập** (khoa / KDD / luồng đặt suất) — *không yêu cầu bệnh viện gửi* |

## 4. Ba sự kiện API

Mỗi sự kiện là một bản tin JSON gồm **trường chung** + **trường riêng theo loại sự kiện**.

### 4.1 Trường chung (mọi sự kiện)

| Trường | Kiểu | Bắt buộc | Ý nghĩa |
|---|---|---|---|
| `event_type` | text | ✔ | `them_moi` \| `chuyen_phong` \| `xuat_vien` |
| `event_id` | text | ✔ | Mã sự kiện duy nhất — dùng để **chống trùng** (gửi lại không tạo 2 lần) |
| `event_time` | datetime (ISO 8601, kèm múi giờ +07:00) | ✔ | Thời điểm phát sinh sự kiện |
| `ma_bn` | text | ✔ | Mã bệnh nhân / mã nhập viện — khóa định danh xuyên suốt |
| `loai_phong` | text | ✔ | `thuong` \| `dich_vu` — **trường quyết định toàn bộ logic tạo/cắt** |

### 4.2 Sự kiện THÊM MỚI (`them_moi`)

| Trường | Bắt buộc | Ý nghĩa |
|---|---|---|
| `ho_ten` | ✔ | Họ tên bệnh nhân |
| `ngay_sinh` | nên có | Để tính nhóm tuổi |
| `gioi_tinh` | tùy chọn | Nam / Nữ |
| `khoa` | ✔ | Khoa điều trị |
| `phong` | ✔ | Phòng |
| `giuong` | ✔ | Giường — để định vị giao tới giường |
| `gio_nhap_vien` | ✔ | Ngày + giờ nhập viện |

### 4.3 Sự kiện CHUYỂN PHÒNG (`chuyen_phong`)

| Trường | Bắt buộc | Ý nghĩa |
|---|---|---|
| `gio_chuyen_phong` | ✔ | Ngày + giờ chuyển (quyết định cữ nào bị ảnh hưởng) |
| `phong_cu` | ✔ | Phòng trước khi chuyển |
| `loai_phong_cu` | ✔ | `thuong` \| `dich_vu` |
| `phong_moi` | ✔ | Phòng sau khi chuyển |
| `loai_phong_moi` | ✔ | `thuong` \| `dich_vu` |
| `khoa_moi` | nên có | Cập nhật nếu đổi khoa |
| `giuong_moi` | nên có | Cập nhật điểm giao mới |

### 4.4 Sự kiện XUẤT VIỆN (`xuat_vien`)

| Trường | Bắt buộc | Ý nghĩa |
|---|---|---|
| `gio_xuat_vien` | ✔ | Ngày + giờ xuất viện |
| `ly_do` | tùy chọn | Ghi nhận (ra viện / chuyển viện…) |

## 5. Logic xử lý tự động (tạo / cắt suất)

### 5.1 Xác định hành động theo loại phòng

| Tình huống | Hành động hệ thống |
|---|---|
| **Thêm mới** vào phòng **dịch vụ** | **TẠO** suất ăn dịch vụ |
| **Thêm mới** vào phòng **thường** | Bỏ qua (chưa phát sinh suất dịch vụ) |
| **Chuyển phòng** Thường → Dịch vụ | **TẠO** suất ăn dịch vụ |
| **Chuyển phòng** Dịch vụ → Thường | **CẮT** suất dịch vụ (mục 5.3) |
| **Chuyển phòng** Dịch vụ → Dịch vụ | **GIỮ** suất, chỉ cập nhật phòng/giường/khoa (đổi điểm giao) |
| **Chuyển phòng** Thường → Thường | Bỏ qua |
| **Xuất viện** (đang ở phòng dịch vụ) | **CẮT** suất theo quy tắc xuất viện (mục 5.2) |

### 5.2 Quy tắc cắt suất khi XUẤT VIỆN

Khi bệnh nhân xuất viện trong ngày, áp dụng cố định cho **ngày xuất viện**:

| Cữ | Giờ cấp | Xử lý khi xuất viện |
|---|---|---|
| Sáng | 06:00 | Đã phục vụ buổi sáng → **tính bình thường** |
| Trưa | 11:00 | **Vẫn giao & tính** — bệnh nhân thường còn ở lại làm thủ tục / chờ xe |
| Chiều | 17:00 | **Cắt** — chiều bệnh nhân đã về |

Từ **ngày hôm sau trở đi: không còn suất nào** (mục 5.4).

> Lý do giữ cữ trưa: xuất viện xong nhiều trường hợp bệnh nhân vẫn ở lại bệnh viện tới trưa nên vẫn dùng suất trưa.

### 5.3 Quy tắc cắt suất khi CHUYỂN Dịch vụ → Thường

Bệnh nhân vẫn ở viện nhưng chuyển sang phòng thường → ngừng suất dịch vụ (chuyển sang suất thường / bệnh lý). Cắt theo việc bếp dịch vụ **đã nấu hay chưa**, dựa trên hạn cắt từng cữ:

| Cữ | Giờ cấp | Hạn cắt | Nếu chuyển sau hạn |
|---|---|---|---|
| Sáng | 06:00 | 15:00 hôm trước | Vẫn nấu — vẫn tính |
| Trưa | 11:00 | 09:00 cùng ngày | Vẫn nấu — vẫn tính |
| Chiều | 17:00 | 15:00 cùng ngày | Vẫn nấu — vẫn tính |

Từ ngày hôm sau: không còn suất dịch vụ (mục 5.4).

### 5.4 Chốt cứng từ ngày hôm sau & nguyên tắc giờ

- **Chốt cứng:** mọi cữ thuộc **ngày sau ngày xuất viện / chuyển phòng** đều **bị hủy, không tính** — kể cả cữ sáng đã "khóa" từ 15:00 hôm trước. Hạn cắt / quy tắc cữ chỉ điều chỉnh các cữ **trong ngày** xảy ra sự kiện.
- **Nguyên tắc giờ:** vì xử lý phụ thuộc mốc giờ, mọi sự kiện bắt buộc kèm **ngày + giờ**, không chỉ ngày.

## 6. Đổi loại món (xử lý nội bộ — NGOÀI phạm vi API)

Việc đổi loại món (cơm ↔ cháo, đổi chế độ ăn) **không đến từ bệnh viện**, mà do khoa lâm sàng chỉnh và gửi danh sách lên Khoa Dinh Dưỡng (KDD) theo **giờ khóa buổi**:

| Cữ | Hạn gửi / đổi món nội bộ |
|---|---|
| Sáng | 15:00 hôm trước |
| Trưa | 09:00 cùng ngày |
| Chiều | 15:00 cùng ngày |

Ghi nhận ở đây để phân biệt rõ với hạn cắt suất (mục 5.2); không cần bệnh viện cung cấp.

## 7. Quy tắc kỹ thuật

- **Chống trùng (idempotency):** mỗi sự kiện có `event_id` duy nhất. Nếu nhận lại `event_id` đã xử lý → trả `200` và **không tạo bản ghi mới**.
- **Định dạng thời gian:** ISO 8601 kèm múi giờ, ví dụ `2026-06-28T09:30:00+07:00`.
- **Kiểm tra dữ liệu (validation):** thiếu trường bắt buộc hoặc `loai_phong` không hợp lệ → trả lỗi `400` kèm mô tả.
- **Bảo mật:** dữ liệu có thông tin bệnh nhân → bắt buộc HTTPS; token/API key bảo mật, có thể thu hồi.
- **Danh mục mã:** khoa / phòng / loại phòng nên dùng **mã thống nhất** giữa hai bên (cần đối chiếu danh mục trước khi chạy thật).

## 8. Mã phản hồi (hệ thống suất ăn trả về cho bệnh viện)

| Mã | Ý nghĩa |
|---|---|
| `200 OK` | Đã nhận & xử lý thành công (hoặc đã nhận trùng, bỏ qua) |
| `400 Bad Request` | Dữ liệu sai / thiếu trường bắt buộc |
| `401 Unauthorized` | Sai hoặc thiếu token / API key |
| `409 Conflict` | Xung đột dữ liệu (ví dụ xuất viện cho BN không tồn tại) |
| `500 Internal Server Error` | Lỗi phía hệ thống nhận — bệnh viện nên gửi lại sau |

## 9. Mẫu JSON

**Thêm mới (vào phòng dịch vụ):**

```json
{
  "event_type": "them_moi",
  "event_id": "EV-2026062800123",
  "event_time": "2026-06-28T08:15:00+07:00",
  "ma_bn": "BN0098765",
  "loai_phong": "dich_vu",
  "ho_ten": "Nguyễn Văn A",
  "ngay_sinh": "2020-05-10",
  "gioi_tinh": "Nam",
  "khoa": "Tiêu hóa",
  "phong": "P305",
  "giuong": "G02",
  "gio_nhap_vien": "2026-06-28T08:00:00+07:00"
}
```

**Chuyển phòng (Dịch vụ → Thường):**

```json
{
  "event_type": "chuyen_phong",
  "event_id": "EV-2026062800456",
  "event_time": "2026-06-28T10:40:00+07:00",
  "ma_bn": "BN0098765",
  "loai_phong": "thuong",
  "gio_chuyen_phong": "2026-06-28T10:30:00+07:00",
  "phong_cu": "P305",
  "loai_phong_cu": "dich_vu",
  "phong_moi": "P210",
  "loai_phong_moi": "thuong",
  "khoa_moi": "Tiêu hóa",
  "giuong_moi": "G05"
}
```

**Xuất viện:**

```json
{
  "event_type": "xuat_vien",
  "event_id": "EV-2026062800789",
  "event_time": "2026-06-28T12:20:00+07:00",
  "ma_bn": "BN0098765",
  "loai_phong": "dich_vu",
  "gio_xuat_vien": "2026-06-28T12:15:00+07:00",
  "ly_do": "Ra viện"
}
```

## 10. Các điểm cần bệnh viện xác nhận

1. Bệnh viện **đẩy webhook** được hay hệ thống suất ăn phải **gọi lấy (polling)**?
2. Cơ chế **xác thực** bệnh viện hỗ trợ (API key / token / khác)?
3. **Loại phòng** (`thuong` / `dich_vu`) có sẵn trong dữ liệu bệnh viện và gửi kèm mọi sự kiện được không?
4. Có cung cấp được **giờ chính xác** cho nhập viện / chuyển phòng / xuất viện không?
5. **Danh mục mã** khoa / phòng — thống nhất mã giữa hai hệ thống.
6. Khi chuyển phòng, bệnh viện gửi được **cả phòng cũ và phòng mới** trong một bản tin không?

---

*Tài liệu này mô tả yêu cầu tích hợp; chi tiết suất ăn (cơm/cháo, số lượng, chế độ, người đặt) do hệ thống căn tin tự quản lý, không thuộc phạm vi dữ liệu yêu cầu bệnh viện cung cấp.*
