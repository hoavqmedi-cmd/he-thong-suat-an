-- ============================================================
--  DATA TEST — Sữa & Soup (Sonde) cho màn Sản xuất
--  Dán vào: Supabase → SQL Editor → Run
--  Ghi thẳng trạng thái 'da_gui_sx' để hiện ngay trên màn Sản xuất
--  (bếp Sữa - soup). Tất cả ma_bn có tiền tố TEST- để dễ xoá.
--  Ngày = hôm nay (current_date). Rải nhiều cữ để có ở cả
--  "Cữ cần sản xuất" lẫn "Đã sản xuất" tuỳ giờ mở màn hình.
-- ============================================================

-- (Chạy lại nhiều lần được: xoá data test cũ trước khi nạp mới)
delete from dang_ky_suat where ma_bn like 'TEST-%';

insert into dang_ky_suat
  (ma_bn, ho_ten, khoa, phong, giuong, ngay_sinh, nhom_tuoi,
   ngay, cu, buoi, loai, loai_food, loai_suat, ma_che_do, bo_phan,
   xay, nem, ghi_chu, trang_thai)
values
-- ── SỮA THƯỜNG (BT) ───────────────────────────────────────
('TEST-SUA-01','Bé Test Sữa A','Sơ sinh','215','1','2025-12-01',1,
  current_date,'09:00','Sáng','sua_bt',null,'BL','SUA006','sua_soup',
  false,false,'','da_gui_sx'),
('TEST-SUA-02','Bé Test Sữa B','Sơ sinh','215','2','2025-06-10',1,
  current_date,'09:00','Sáng','sua_bt',null,'BL','SUA007','sua_soup',
  false,false,'','da_gui_sx'),
('TEST-SUA-03','Bé Test Sữa C','Nhi Tổng hợp','203','1','2024-03-15',2,
  current_date,'12:00','Trưa','sua_bt',null,'BL','SUA011','sua_soup',
  false,false,'','da_gui_sx'),

-- ── SỮA ĐẶC BIỆT (ĐB) ─────────────────────────────────────
('TEST-SUA-04','Bé Test Sữa ĐB D','Thận - Nội tiết','401','1','2023-08-20',3,
  current_date,'12:00','Trưa','sua_db',null,'BL','SUA020','sua_soup',
  false,false,'Dị ứng đạm bò','da_gui_sx'),
('TEST-SUA-05','Bé Test Sữa ĐB E','Hồi sức tích cực','ICU','3','2025-01-05',1,
  current_date,'15:00','Chiều','sua_db',null,'BL','SUA022','sua_soup',
  false,false,'','da_gui_sx'),
('TEST-SUA-06','Bé Test Sữa ĐB F','Tiêu hoá Nhi','301','2','2024-11-11',2,
  current_date,'15:00','Chiều','sua_db',null,'BL','SUA024','sua_soup',
  false,false,'','da_gui_sx'),

-- ── SONDE / SOUP ──────────────────────────────────────────
('TEST-SON-01','Bé Test Sonde G','Hồi sức tích cực','ICU','1','2014-02-02',5,
  current_date,'11:00','Trưa','sonde',null,'BL','SS-GA','sua_soup',
  false,false,'','da_gui_sx'),
('TEST-SON-02','Bé Test Sonde H','Thần kinh Nhi','305','2','2016-07-07',5,
  current_date,'16:00','Chiều','sonde',null,'BL','SS-HEO','sua_soup',
  false,false,'Ăn chậm, theo dõi sặc','da_gui_sx'),
('TEST-SON-03','Bé Test Sonde I','Hô hấp Nhi','210','4','2018-09-09',5,
  current_date,'21:00','Chiều','sonde',null,'BL','SS-BO','sua_soup',
  false,false,'','da_gui_sx'),

-- ── BN COMBO: vừa Sữa ĐB vừa Sonde (test in nhiều tem/1 BN) ─
('TEST-COMBO-01','Bé Test Combo K','Hồi sức tích cực','ICU','2','2025-02-02',1,
  current_date,'09:00','Sáng','sua_db',null,'BL','SUA022','sua_soup',
  false,false,'','da_gui_sx'),
('TEST-COMBO-01','Bé Test Combo K','Hồi sức tích cực','ICU','2','2025-02-02',1,
  current_date,'09:00','Sáng','sonde',null,'BL','SS-GA','sua_soup',
  false,false,'','da_gui_sx');

-- Kiểm tra nhanh sau khi chạy:
-- select cu, loai, ma_che_do, ho_ten from dang_ky_suat
--   where ma_bn like 'TEST-%' order by cu, loai;
