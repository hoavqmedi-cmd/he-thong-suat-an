# Yêu cầu — Màn hình Quản trị (Admin tổng)

> Hệ thống nhận thông tin suất ăn — Căn tin Nhi Đồng 1
> Vai trò "super user" đứng trên toàn hệ thống. Logic đã chốt với chủ DN.
> Trạng thái: **đặc tả yêu cầu — chưa dựng UI.**

## 0. Phạm vi đã chốt

- **Một cơ sở: Bệnh viện Nhi Đồng 1** (chưa thiết kế đa điểm bán).
- **Xuất báo cáo: Excel.**
- **Có Admin phụ** (phân quyền theo bộ phận).
- **Nhật ký: chỉ ghi mốc chính** (duyệt / gửi / giao), không tới mức từng thao tác BN.

## 1. Mục tiêu

Cho người quản lý: (1) nhìn toàn cảnh vận hành theo ngày; (2) xuất báo cáo sản lượng, nguyên liệu, giao hàng (Excel); (3) quản lý người dùng & phân quyền; (4) quản lý dữ liệu nền.

## 2. Hai cấp quản trị

| Cấp | Phạm vi | Quyền |
|---|---|---|
| **Admin tổng** | Toàn hệ thống | Tất cả module (A–E) |
| **Admin phụ** | 1 bộ phận (vd trưởng bếp DV / bếp bệnh lý / phòng sữa-soup) | Dashboard + Báo cáo + Giám sát **trong bộ phận mình**; quản tài khoản nhân sự thuộc bộ phận. **Không** sửa dữ liệu nền toàn hệ thống, **không** đụng tài khoản ngoài bộ phận. |

## 3. Ranh giới quyền dữ liệu (tránh chồng chéo)

| Loại dữ liệu | Ai quản lý |
|---|---|
| Tài khoản, vai trò, phân quyền | Admin |
| Khoa · phòng/giường · giờ cữ · giờ khóa buổi · bộ phận | Admin |
| Danh mục bệnh · nhóm tuổi | Admin (KDD dùng lại) |
| Danh mục sữa, công thức pha, mã soup | **KDD** (admin chỉ xem/giám sát) |

## 4. Cấu trúc màn: 5 module

```
Admin
├─ A. Dashboard vận hành (real-time theo ngày)
├─ B. Báo cáo & xuất Excel
├─ C. Người dùng & phân quyền
├─ D. Dữ liệu nền (master data)
└─ E. Giám sát & nhật ký (mốc chính)
```

## 5. Module A — Dashboard vận hành

Theo dõi luồng trong ngày dạng phễu:

```
Đăng ký → Đã duyệt/gửi → Đã sản xuất → Đã giao
```

- Tổng suất/ngày · theo **cữ** · theo **bộ phận** · theo **khoa**.
- **Cảnh báo:** cữ sắp/đã quá giờ khóa chưa gửi · suất giao thất bại cao · nhiều BN bị KDD trả về · bổ sung bất thường.
- **KPI nhanh:** tỷ lệ giao thành công · tỷ lệ từ chối/trả về · suất trả về bếp.
- Admin phụ: dashboard chỉ hiển thị số liệu **bộ phận mình**.

## 6. Module B — Báo cáo & xuất Excel

- **Sản lượng** theo ngày/tuần/tháng; lọc theo bộ phận · khoa · món · mã chế độ.
- **Báo cáo tách 2 bên:** *Cơm-Cháo* (bếp DV + bếp bệnh lý) · *Sữa-Soup* (phòng sữa-soup).
- **Nguyên liệu tiêu thụ:** tổng sữa bột mỗi loại + nguyên liệu soup (lấy từ công thức Danh mục sữa của KDD).
- **Giao hàng:** OK/thất bại, theo lý do & cách xử lý (gửi ĐD khoa / đem về bếp).
- **Định dạng xuất: Excel (.xlsx).**

## 7. Module C — Người dùng & phân quyền

- Tạo/sửa tài khoản; gán **vai trò** (7 vai trò: khoa lâm sàng, KDD, bếp DV, bếp bệnh lý, phòng sữa-soup, người giao, admin) + **bộ phận/khoa** phụ trách.
- Bật/tắt tài khoản, đặt lại mật khẩu.
- Tạo **Admin phụ** gắn 1 bộ phận.
- Mỗi vai trò đăng nhập vào đúng màn của mình.

## 8. Module D — Dữ liệu nền

Khoa & phòng/giường · giờ cữ từng loại suất · giờ khóa theo buổi · bộ phận sản xuất · danh mục bệnh · nhóm tuổi. (Danh mục sữa: chỉ xem; KDD sở hữu.) — **Chỉ Admin tổng** thao tác.

## 9. Module E — Giám sát & nhật ký (mốc chính)

- Theo dõi trạng thái **từng cữ xuyên suốt** các bộ phận.
- **Audit log — chỉ mốc chính:** ai **duyệt** · ai **gửi** · ai **giao** + thời gian. Không lưu chi tiết từng thao tác trên từng BN.

## 10. Phi chức năng

- Thiết bị chính: **máy tính để bàn** (bảng số liệu dày, nhiều cột).
- Đọc **một nguồn dữ liệu chung** với mọi màn → số liệu khớp tức thời.

## 11. Tóm tắt điểm đã chốt

1. Phạm vi: **riêng Nhi Đồng 1**, chưa đa điểm. ✔
2. Báo cáo **xuất Excel**. ✔
3. **Có Admin phụ** — phân quyền theo bộ phận. ✔
4. Nhật ký **chỉ mốc chính** (duyệt/gửi/giao). ✔
