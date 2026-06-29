# Logic màn hình Khoa Dinh Dưỡng (KDD)

> Hệ thống nhận thông tin suất ăn — Căn tin Nhi Đồng 1
> Cấu trúc: 4 tab, đơn vị xử lý = **CỮ**. Logic đã chốt với chủ DN.

## 1. Vị trí của KDD trong luồng

```
Khoa lâm sàng  →  [ KDD duyệt theo cữ ]  →  (khi gửi tự tách 3 bộ phận)
(điều dưỡng,                                  ├─ Bếp phòng dịch vụ
 bác sĩ)                                       ├─ Bếp cơm bệnh lý
                                               └─ Phòng sữa - soup
```

KDD duyệt **một lần cho cả cữ**. Khi gửi, hệ thống **tự tách** suất về đúng 3 bộ phận. KDD không phải duyệt 3 lần cho 3 bếp.

## 2. Đơn vị xử lý: CỮ

Mọi loại suất được quy về **cữ (mốc giờ cung cấp)**. Các loại trùng giờ sẽ gom chung vào một cữ.

| Loại suất | Số cữ | Giờ cữ trong ngày |
|---|---|---|
| Sữa (BT + ĐB) | 8 | 03:00 · 06:00 · 09:00 · 12:00 · 15:00 · 18:00 · 21:00 · 00:00 |
| Soup sonde | 4 | 06:00 · 11:00 · 16:00 · 21:00 |
| Cơm/Cháo (DV + bệnh lý) | 3 | 06:00 · 11:00 · 17:00 |

Ví dụ: cữ 06:00 gom cả cơm/cháo + sữa + sonde; cữ 03:00 chỉ có sữa; cữ 17:00 chỉ có cơm/cháo.

**Giờ khóa** vẫn theo **buổi** (Sáng/Trưa/Chiều-Tối) — là hạn khoa lâm sàng gửi. Trong giờ khóa, KDD chủ động duyệt & gửi từng cữ.

## 3. Cấu trúc 4 tab

- **Tab 1 — Cữ chờ xử lý:** màn hình chính, các thẻ cữ đang chờ duyệt/gửi.
- **Tab 2 — Đã gửi sản xuất:** các cữ đã chuyển, để theo dõi và gửi bổ sung.
- **Tab 3 — Tra cứu bệnh nhân:** tìm 1 BN, xem chế độ ăn cả ngày + lịch sử.
- **Tab 4 — Danh mục sữa:** KDD quản lý quy định mã sữa, công thức pha sữa, mã soup sonde (xem mục 12).

## 4. Tab 1 — Cữ chờ xử lý

**Sắp xếp:** cữ **gần giờ cung cấp nhất & chưa xử lý lên đầu**; cữ đã xử lý/đã qua thu gọn xuống dưới. Cữ chéo ngày (00:00, 03:00) gắn mốc ngày để sắp đúng.

**Mỗi thẻ cữ** hiện tổng hợp số liệu, tách 7 nhóm (ẩn nhóm rỗng):

| Dịch vụ | Bệnh lý |
|---|---|
| Cơm · Cháo | Cơm · Cháo · Sữa BT · Sữa ĐB · Soup sonde |

**Hai nút trên thẻ (duyệt xong mới gửi):**

- **Duyệt tất cả** — duyệt (tick) toàn bộ BN đủ điều kiện, **chưa gửi**. Vẫn mở chi tiết chỉnh lại được.
- **Duyệt tất cả và gửi** — duyệt + chuyển luôn trong 1 chạm (đường tắt cho cữ sạch).

Hoặc **mở chi tiết** (cửa sổ riêng) để xử lý từng BN rồi nhấn **Chuyển**.

## 5. Cơ chế duyệt / gửi — bảng chi tiết

Mỗi BN đủ điều kiện có **ô tick "Duyệt"**, **mặc định tick sẵn** (vì đa số hợp lệ — chỉ bỏ tick ca có vấn đề, tránh quên tick).

Khi nhấn **Chuyển**, xử lý theo 3 tình trạng:

| Tình trạng | Điều kiện | Khi Chuyển |
|---|---|---|
| **1 — Duyệt** | Đã tick | Gửi cho sản xuất (tự tách 3 bộ phận) |
| **2 — Từ chối** | Bỏ tick + có lý do | Trả về khoa lâm sàng |
| **3 — Chưa gửi** | Khoa chưa xác nhận (mờ) | Không tác động |

**Ràng buộc:** BN bỏ tick mà **chưa nhập lý do** thì **chặn Chuyển** — bảo đảm từ chối là có chủ ý, không phải quên tick.

## 6. Phân tuyến & báo cáo

Khi gửi, hệ thống tự tách:

| Loại suất | Bộ phận nhận |
|---|---|
| Cơm/Cháo dịch vụ | Bếp phòng dịch vụ |
| Cơm/Cháo bệnh lý | Bếp cơm bệnh lý |
| Sữa (BT + ĐB) + Soup sonde | Phòng sữa - soup |

**Báo cáo tách 2 bên:** *Cơm-Cháo* (Bếp DV + Bếp cơm bệnh lý) · *Sữa-Soup* (Phòng sữa-soup). Tách ở tầng dữ liệu nên KDD chỉ thao tác 1 lần vẫn ra 2 báo cáo riêng.

## 7. Vòng đời cữ & gửi bổ sung

```
Cữ ở Tab 1 (chờ xử lý)
   → Duyệt → Gửi → chuyển sang Tab 2 (đã gửi)

[ TRƯỚC giờ khóa buổi ] Khoa cập nhật cữ đã gửi
   → Phần thay đổi hiện lại ở Tab 1 dạng "Bổ sung — cữ HH:MM"
   → KDD duyệt phần bổ sung → Gửi bổ sung (chỉ phần thay đổi) → về Tab 2

[ ĐẾN giờ khóa buổi ] → khóa hẳn, không cập nhật/gửi bổ sung
```

Gửi bổ sung **chỉ chứa phần thay đổi** (BN mới / đổi chế độ / huỷ), gắn nhãn "Bổ sung lúc HH:MM" để bếp phân biệt. Sau giờ khóa, thay đổi xử lý ngoài hệ thống.

## 8. BN bị KDD trả về (tình trạng 2)

BN bị từ chối quay về **đúng luồng (DV/Bệnh lý) của khoa lâm sàng đã gửi**, vào nhóm riêng **"Bị KDD trả về"** (badge đỏ + lý do), tách khỏi nhóm BN mới. Điều dưỡng sửa → xác nhận lại → gửi lại → cữ tương ứng hiện lại ở Tab 1 của KDD. Chỉ làm được trước giờ khóa. **Báo trên màn hình khoa là đủ** — không cần thông báo đẩy.

## 9. Tab 2 — Đã gửi & Tab 3 — Tra cứu

**Tab 2 — Đã gửi sản xuất:** danh sách cữ đã chuyển, kèm giờ gửi. Mỗi thẻ cữ:

- **Breakdown theo từng bộ phận + từng loại food** (không chỉ tổng):
  - Bếp phòng dịch vụ: Cơm × n · Cháo × n
  - Bếp cơm bệnh lý: Cơm × n · Cháo × n
  - Phòng sữa-soup: Sữa BT × n · Sữa ĐB × n · Soup sonde × n

  → mỗi bếp/phòng biết chính xác số suất mỗi món, khớp số cho báo cáo 2 bên.
- Nút **Xem chi tiết** → mở panel/modal liệt kê **danh sách BN thực tế đã gửi**, nhóm theo 3 bộ phận, kèm BN bị **trả về + lý do**. Phục vụ đối chiếu và gửi bổ sung.

**Tab 3 — Tra cứu bệnh nhân:** ô tìm theo tên/mã BN → hiện **chế độ ăn cả ngày** của BN đó (mọi cữ, mọi loại suất, theo khoa) + lịch sử duyệt/gửi/trả về. Đây là chỗ xem trọn lịch của 1 BN mà Tab 1 (chia theo cữ) không thể hiện gộp.

## 10. Hiển thị desktop & quy mô toàn viện (25 khoa · ~400 BN/cữ)

**Bố cục desktop — 2 khung master–detail** (màn ≥ 1024px):

- **Khung trái (~360px):** hàng cữ (queue) dạng thẻ gọn, cữ gần giờ cấp & chưa xử lý lên đầu.
- **Khung phải:** chi tiết cữ đang chọn — **không dùng modal**. KDD vừa thấy hàng chờ vừa xử lý, đúng nhịp "chọn cữ → duyệt → cữ kế tiếp".
- Màn hẹp (< 1024px): tự rớt về dạng thẻ 1 cột + chi tiết mở **modal** như bản gốc.

**Chi tiết cữ ở quy mô lớn — gộp 2 cấp Khoa → Bệnh nhân:**

- Mặc định hiện **25 dòng khoa** (accordion, đóng sẵn). Mỗi dòng khoa: tên · số BN · breakdown nhỏ (DV/BL) · tiến độ duyệt (vd 18/18) · nút **Duyệt cả khoa**. Mở khoa mới hiện BN dạng **bảng dày** (tick · tên/mã · P/G · loại suất · lý do nếu từ chối).
- **Thanh lọc + tìm:** lọc theo khoa, theo loại suất (cơm/cháo/sữa BT/ĐB/sonde), tìm theo tên/mã.
- **Bộ lọc "chỉ hiện cần chú ý":** vì mặc định tick-duyệt hết, KDD chủ yếu soi ngoại lệ — BN **mới / đổi chế độ / có cảnh báo** (dị ứng, tạm ngưng). Lọc về nhóm này để duyệt nhanh phần còn lại.
- **Nút "Duyệt tất cả cữ"** ở đầu (có xác nhận số lượng) cho cữ sạch.
- Hiệu năng: 400 BN thu thành 25 dòng khoa; chỉ khoa được mở mới render BN nên nhẹ.

## 11. Thẻ bệnh nhân & chi tiết bệnh nhân (modal)

**Thẻ BN trong chi tiết cữ hiện đầy đủ thông tin của cữ đó:**

- **Mã BN · Ngày sinh · Phòng/Giường**
- **Loại thực phẩm + Mã chế độ ăn:** vd `Cơm DV` · `5BT·CPDV`; `Cháo BL` · `3TH·ChBL`; sữa `SUA023`; sonde `BN-SS05`
- **Ghi chú theo loại:**
  - Cháo: Xay/Không xay · Nêm/Không nêm
  - Bệnh lý: **L / P / G** (Lipid/Protein/Glucid, g) + **Năng lượng** (kcal) + ghi chú bệnh lý
  - Ghi chú chung (dị ứng…)

Mã chế độ, L/P/G, kcal là dữ liệu từ hệ thống khoa lâm sàng (mockup mock giá trị, nối thật sẽ lấy từ đó).

**Nhấn vào thẻ BN → mở modal chi tiết (chỉ đọc, phương án A):**

- **Đăng ký cả ngày hôm nay:** mọi cữ, mọi loại, kèm mã + ghi chú + L/P/G — giống thẻ chi tiết bên Dịch vụ/Bệnh lý của khoa lâm sàng.
- **Lịch sử các ngày trước** (mock vài ngày gần nhất).
- **Duyệt/từ chối ngay** cho cữ đang xét trong modal.
- **Tách thao tác:** ô tick = duyệt/từ chối; bấm phần còn lại của thẻ = mở chi tiết BN.

---

## 12. Tab 4 — Danh mục sữa (quy định do KDD quản lý)

> Nơi KDD cập nhật **quy định** làm cơ sở để: (1) khoa lâm sàng **chọn đúng mã** sữa/soup khi đăng ký; (2) phòng sữa-soup **tính lượng nguyên liệu tiêu thụ**. Logic đã chốt với chủ DN. Trạng thái: **chưa dựng UI** — phần này mới ở mức đặc tả.

### 12.1 Dữ liệu nền tái sử dụng (đã có sẵn trong project)

Tab 4 **không tạo mới** các danh mục dưới đây mà dùng lại từ luồng bệnh lý hiện có:

| Danh mục | Giá trị đang có trong code |
|---|---|
| **5 nhóm tuổi** | `<6 tháng` · `6–12 tháng` · `1–3 tuổi` · `4–6 tuổi` · `7–15 tuổi` |
| **8 mã bệnh** | `BT` Bình thường · `TH` Tiêu hoá · `GM` Gan mật · `TN` Thận niệu · `SD` Suy dinh dưỡng · `DD` Đái tháo đường · `NK` Nhiễm khuẩn · `TM` Tim mạch |
| **Mã sữa BT hiện dùng** | SUA006 · SUA007 · SUA009 · SUA011 · SUA013 · SUA014 |
| **Mã sữa ĐB hiện map (chỉ theo bệnh)** | TH→SUA023 · GM→SUA021 · TN→SUA020/024 · SD→SUA010/015 · DD→SUA019/025 · BT/NK/TM→SUA022 |
| **ml/suất sữa** | Khoa lâm sàng **đã nhập** khi đăng ký (ô ml trong form bệnh lý) |

**Thay đổi so với hiện trạng:** map sữa ĐB hiện chỉ theo *bệnh* → nâng lên **ma trận Tuổi × Bệnh** (mục 12.3).

### 12.2 Cấu trúc Tab 4: 2 bảng

Tab 4 gồm 2 bảng quản lý (thêm / sửa / ngừng dùng):

- **Bảng 1 — Mã sữa** (gộp luôn công thức pha vào mỗi dòng).
- **Bảng 2 — Soup sonde** (4 loại + công thức nguyên liệu).

### 12.3 Bảng 1 — Mã sữa

Mỗi dòng = 1 mã sữa, gồm rule chọn + công thức pha:

| Cột | Ý nghĩa |
|---|---|
| Mã sữa | vd `SUA023` |
| Tên sữa | tên thương mại |
| Loại | **BT** (bình thường) / **ĐB** (đặc biệt) |
| Nhóm tuổi áp dụng | 1 hoặc nhiều nhóm trong 5 nhóm tuổi |
| Mã bệnh áp dụng | **chỉ với ĐB**; BT để trống (không xét bệnh) |
| Bột (g) | khối lượng sữa bột — công thức pha |
| Nước (ml) | lượng nước — công thức pha |
| Thành phẩm (ml) | thể tích sau pha — công thức pha |
| Trạng thái | Đang dùng / Ngừng |

**Rule chọn mã (đã chốt):**

- **Sữa BT** → lọc theo **NHÓM TUỔI** của BN (không xét bệnh).
- **Sữa ĐB** → lọc theo **NHÓM TUỔI × MÃ BỆNH** (ma trận 2 chiều).

**Công thức pha:** do **KDD tự nhập và điều chỉnh** khi cần (Bột g + Nước ml → Thành phẩm ml).

### 12.4 Bảng 2 — Soup sonde (4 loại)

4 loại cố định, khoa lâm sàng chọn 1 khi đăng ký cữ sonde:

| Mã (đề xuất) | Tên | Công thức nguyên liệu/suất |
|---|---|---|
| SS-GA | Soup gà | (số liệu mock — KDD sửa) |
| SS-HEO | Soup heo | (số liệu mock — KDD sửa) |
| SS-BO | Soup bò | (số liệu mock — KDD sửa) |
| SS-BS | Soup bột sữa | (số liệu mock — KDD sửa) |

Mỗi dòng có: Mã · Tên · danh sách nguyên liệu kèm định lượng/suất · Thành phẩm (ml) · Trạng thái. **Số liệu công thức để mock, KDD chỉnh trong màn.**

### 12.5 Nối ra tính nguyên liệu tiêu thụ

```
Khoa lâm sàng chọn suất cho BN
   ├─ Sữa BT : lọc mã theo NHÓM TUỔI → nhập ml/suất
   ├─ Sữa ĐB : lọc mã theo NHÓM TUỔI × MÃ BỆNH → nhập ml/suất
   └─ Sonde  : chọn 1 trong 4 mã soup

Phòng sữa-soup (màn dựng sau) tự tính:
   • Sữa : tổng ml/suất (gom theo mã) ÷ Thành phẩm(ml) × Bột(g) = tổng sữa bột cần
   • Soup: tổng suất (gom theo mã) × định lượng nguyên liệu/suất = tổng nguyên liệu cần
   → nguồn số liệu công thức = Tab 4.
```

### 12.6 Điểm đã chốt

1. Sữa BT lọc **theo nhóm tuổi**, không xét bệnh. ✔
2. Sữa ĐB lọc **theo cả nhóm tuổi + mã bệnh** (ma trận). ✔
3. Công thức pha sữa: **KDD nhập & điều chỉnh**. ✔
4. Soup sonde: 4 loại = **gà · heo · bò · bột sữa**; công thức để mock, KDD sửa sau. ✔
5. Mã bệnh & nhóm tuổi: **dùng lại** danh mục sẵn có của luồng bệnh lý. ✔
