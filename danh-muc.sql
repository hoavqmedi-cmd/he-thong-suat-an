-- ============================================================
--  DANH MỤC — Nhóm tuổi · Mã bệnh · Khoa · Mức độ bệnh · Món · Sữa · Sonde
--  Dán vào: Supabase → SQL Editor → Run. An toàn chạy lại.
--  Mã chế độ: {Nhóm}{Bệnh}{Mức độ}·{Món}  (vd 4TH01·Sữa thường)
-- ============================================================

-- 1) NHÓM TUỔI ------------------------------------------------
create table if not exists dm_nhom_tuoi (
  ma         text primary key,
  ten        text not null,
  mo_ta      text,
  min_thang  int,
  max_thang  int
);
insert into dm_nhom_tuoi (ma, ten, mo_ta, min_thang, max_thang) values
  ('1','Nhóm 1','< 6 tháng',   0,   6),
  ('2','Nhóm 2','6–12 tháng',  6,  12),
  ('3','Nhóm 3','1–3 tuổi',   12,  36),
  ('4','Nhóm 4','4–6 tuổi',   36,  72),
  ('5','Nhóm 5','7–15 tuổi',  72, 180)
on conflict (ma) do update
  set ten=excluded.ten, mo_ta=excluded.mo_ta,
      min_thang=excluded.min_thang, max_thang=excluded.max_thang;

-- 2) MÃ BỆNH --------------------------------------------------
create table if not exists dm_ma_benh (
  ma         text primary key,
  ten        text,
  mo_ta      text,
  la_dich_vu boolean default false
);
insert into dm_ma_benh (ma, ten, mo_ta, la_dich_vu) values
  ('BT','BT','Bình thường',     true),
  ('TH','TH','Tiêu hoá',        false),
  ('GM','GM','Gan mật',         false),
  ('TN','TN','Thận niệu',       false),
  ('SD','SD','Suy dinh dưỡng',  false),
  ('DD','DD','Đái tháo đường',  false),
  ('NK','NK','Nhiễm khuẩn',     false),
  ('TM','TM','Tim mạch',        false)
on conflict (ma) do update
  set ten=excluded.ten, mo_ta=excluded.mo_ta, la_dich_vu=excluded.la_dich_vu;

-- 3) KHOA LÂM SÀNG -------------------------------------------
create table if not exists dm_khoa (
  ma      text primary key,
  ten     text not null,
  thu_tu  int
);
insert into dm_khoa (ma, ten, thu_tu) values
  ('K01','KHOA NỘI TỔNG QUÁT 1',          1),
  ('K02','KHOA NỘI TỔNG QUÁT 2',          2),
  ('K03','KHOA SỐT XUẤT HUYẾT',           3),
  ('K04','KHOA THẬN - NỘI TIẾT',          4),
  ('K05','KHOA PHỎNG',                    5),
  ('K06','KHOA NGOẠI THẬN - TIẾT NIỆU',   6),
  ('K07','KHOA NGOẠI TỔNG HỢP',           7),
  ('K08','KHOA NGOẠI CHỈNH HÌNH',         8),
  ('K09','KHOA NGOẠI THẦN KINH',          9),
  ('K10','KHOA HÔ HẤP',                  10),
  ('K11','KHOA TIÊU HÓA',                11),
  ('K12','KHOA NHIỄM - THẦN KINH',       12),
  ('K13','KHOA TIM MẠCH',                13),
  ('K14','KHOA NGOẠI TIM MẠCH',          14),
  ('K15','KHOA RĂNG HÀM MẶT',            15),
  ('K16','KHOA TAI MŨI HỌNG',            16),
  ('K17','KHOA HỒI SỨC NHIỄM',           17),
  ('K18','KHOA TIM MẠCH CAN THIỆP',      18),
  ('K19','KHOA SƠ SINH',                 19),
  ('K20','KHOA SƠ SINH 2',               20),
  ('K21','KHOA HỒI SỨC TÍCH CỰC',        21)
on conflict (ma) do update set ten=excluded.ten, thu_tu=excluded.thu_tu;

-- 4) MỨC ĐỘ BỆNH (số phụ trong mã) ---------------------------
--    Do KHOA LÂM SÀNG gửi lên KHOA DINH DƯỠNG. Tên bổ sung sau.
drop table if exists dm_mon_so;            -- bảng cũ (đổi tên)
create table if not exists dm_muc_do_benh (
  ma     text primary key,                 -- '', '01'..'04'
  ten    text,                             -- TODO: tên mức độ (bổ sung sau)
  mo_ta  text
);
insert into dm_muc_do_benh (ma, ten, mo_ta) values
  ('',  null, 'Không có mức độ'),
  ('01',null, null),
  ('02',null, null),
  ('03',null, null),
  ('04',null, null)
on conflict (ma) do nothing;

-- 5) MÃ MÓN (token trong mã chế độ) --------------------------
--    DV: CPDV/ChPDV. BL: Cơm, Cháo, Sữa thường, Sữa đặc trị, Sonde.
drop table if exists dm_ma_mon;
create table dm_ma_mon (
  ma         text primary key,
  ten        text,
  loai_suat  text not null,                -- 'DV' | 'BL'
  don_vi     text not null                 -- 'suất' | 'ml'
);
insert into dm_ma_mon (ma, ten, loai_suat, don_vi) values
  ('CPDV',        'Cơm phòng dịch vụ',  'DV', 'suất'),
  ('ChPDV',       'Cháo phòng dịch vụ', 'DV', 'suất'),
  ('Cơm',         'Cơm',            'BL', 'suất'),
  ('Cháo',        'Cháo',           'BL', 'suất'),
  ('Sữa thường',  'Sữa thường',     'BL', 'ml'),
  ('Sữa đặc trị', 'Sữa đặc trị',    'BL', 'ml'),
  ('Sonde',       'Sonde',          'BL', 'ml');

-- 6) DANH MỤC SỮA (lấy từ màn KDD) ---------------------------
--    loai: 'BT' (thường) | 'ĐB' (đặc trị). bot=bột(g), nuoc=nước(ml), tp=thành phẩm(ml).
create table if not exists dm_ma_sua (
  ma       text primary key,
  ten      text not null,
  loai     text not null,                  -- 'BT' | 'ĐB'
  bot_g    numeric,
  nuoc_ml  numeric,
  tp_ml    numeric
);
insert into dm_ma_sua (ma, ten, loai, bot_g, nuoc_ml, tp_ml) values
  ('SUA006','Sữa công thức số 1','BT',13, 90,100),
  ('SUA007','Sữa công thức số 2','BT',14, 90,100),
  ('SUA009','Sữa tăng trưởng',    'BT',15, 90,100),
  ('SUA011','Sữa trẻ nhỏ',        'BT',20,180,200),
  ('SUA013','Sữa học đường',      'BT',22,180,200),
  ('SUA014','Sữa cao tuổi nhi',   'BT',24,180,200),
  ('SUA023','Sữa tiêu hoá',       'ĐB',18,170,200),
  ('SUA021','Sữa gan mật',        'ĐB',18,170,200),
  ('SUA020','Sữa thận niệu A',    'ĐB',17,170,200),
  ('SUA024','Sữa thận niệu B',    'ĐB',15, 90,100),
  ('SUA010','Sữa suy dinh dưỡng A','ĐB',16, 90,100),
  ('SUA015','Sữa suy dinh dưỡng B','ĐB',25,180,200),
  ('SUA019','Sữa đái tháo đường A','ĐB',22,180,200),
  ('SUA025','Sữa đái tháo đường B','ĐB',16,120,130),
  ('SUA022','Sữa cao năng lượng', 'ĐB',20,150,170)
on conflict (ma) do update
  set ten=excluded.ten, loai=excluded.loai,
      bot_g=excluded.bot_g, nuoc_ml=excluded.nuoc_ml, tp_ml=excluded.tp_ml;

-- 7) GIỚI HẠN SỮA ĐẶC TRỊ THEO MÃ BỆNH -----------------------
--    (sữa thường BT áp dụng chung, giới hạn theo tuổi — xem dm_sua_tuoi)
drop table if exists dm_benh_sua;
create table dm_benh_sua (
  ma_benh text not null,
  ma_sua  text not null,
  primary key (ma_benh, ma_sua)
);
insert into dm_benh_sua (ma_benh, ma_sua) values
  ('TH','SUA023'),
  ('GM','SUA021'),
  ('TN','SUA020'),('TN','SUA024'),
  ('SD','SUA010'),('SD','SUA015'),
  ('DD','SUA019'),('DD','SUA025'),
  ('BT','SUA022'),('NK','SUA022'),('TM','SUA022')
on conflict do nothing;

-- 8) ÁP DỤNG SỮA THEO NHÓM TUỔI ------------------------------
drop table if exists dm_sua_tuoi;
create table dm_sua_tuoi (
  ma_sua text not null,
  nhom   text not null,                    -- '1'..'5'
  primary key (ma_sua, nhom)
);
insert into dm_sua_tuoi (ma_sua, nhom) values
  ('SUA006','1'),
  ('SUA007','1'),('SUA007','2'),
  ('SUA009','2'),('SUA009','3'),
  ('SUA011','3'),('SUA011','4'),
  ('SUA013','4'),('SUA013','5'),
  ('SUA014','5'),
  ('SUA023','3'),('SUA023','4'),('SUA023','5'),
  ('SUA021','2'),('SUA021','3'),('SUA021','4'),('SUA021','5'),
  ('SUA020','3'),('SUA020','4'),('SUA020','5'),
  ('SUA024','1'),('SUA024','2'),
  ('SUA010','1'),('SUA010','2'),('SUA010','3'),
  ('SUA015','4'),('SUA015','5'),
  ('SUA019','4'),('SUA019','5'),
  ('SUA025','2'),('SUA025','3'),
  ('SUA022','1'),('SUA022','2'),('SUA022','3'),('SUA022','4'),('SUA022','5')
on conflict do nothing;

-- 9) MÃ SONDE ------------------------------------------------
create table if not exists dm_ma_sonde (
  ma   text primary key,                   -- 'BN-SS04'..'BN-SS06'
  ten  text                                -- TODO: tên (chưa có trong code)
);
insert into dm_ma_sonde (ma, ten) values
  ('BN-SS04', null),
  ('BN-SS05', null),
  ('BN-SS06', null)
on conflict (ma) do nothing;

-- 10) KHUNG CỮ ĂN BỆNH LÝ — 11 cữ/ngày -----------------------
create table if not exists dm_cu_an (
  so      text primary key,
  gio     text not null,
  ghi_chu text
);
insert into dm_cu_an (so, gio, ghi_chu) values
  ('01','03:00','Nhũ nhi / trẻ bệnh nặng'),
  ('02','06:00',null),
  ('03','09:00',null),
  ('04','11:00',null),
  ('05','12:00',null),
  ('06','15:00',null),
  ('07','16:00',null),
  ('08','17:00',null),
  ('09','18:00',null),
  ('10','21:00',null),
  ('11','00:00','Nhũ nhi / trẻ bệnh nặng')
on conflict (so) do update set gio=excluded.gio, ghi_chu=excluded.ghi_chu;

-- 11) MA TRẬN CỮ × MÓN (5 món BL) ----------------------------
drop table if exists dm_mon_benh_ly;       -- bảng cũ bỏ hẳn
drop table if exists dm_cu_mon;
create table dm_cu_mon (
  cu_so text not null,                      -- FK dm_cu_an.so
  mon   text not null,                      -- FK dm_ma_mon.ma (BL)
  primary key (cu_so, mon)
);
insert into dm_cu_mon (cu_so, mon) values
  -- Cơm: 06:00, 11:00, 17:00
  ('02','Cơm'),('04','Cơm'),('08','Cơm'),
  -- Cháo: 06:00, 11:00, 17:00
  ('02','Cháo'),('04','Cháo'),('08','Cháo'),
  -- Sữa thường: 8 cữ
  ('01','Sữa thường'),('02','Sữa thường'),('03','Sữa thường'),('05','Sữa thường'),
  ('06','Sữa thường'),('09','Sữa thường'),('10','Sữa thường'),('11','Sữa thường'),
  -- Sữa đặc trị: 8 cữ
  ('01','Sữa đặc trị'),('02','Sữa đặc trị'),('03','Sữa đặc trị'),('05','Sữa đặc trị'),
  ('06','Sữa đặc trị'),('09','Sữa đặc trị'),('10','Sữa đặc trị'),('11','Sữa đặc trị'),
  -- Sonde: 06:00, 11:00, 16:00, 21:00
  ('02','Sonde'),('04','Sonde'),('07','Sonde'),('10','Sonde');

-- 12) HÀM DỰNG MÃ:  {Nhóm}{Bệnh}{Mức độ}·{Món} --------------
--    select fn_tao_ma('1','BT','','CPDV');          -> '1BT·CPDV'
--    select fn_tao_ma('4','TH','01','Sữa thường');  -> '4TH01·Sữa thường'
drop function if exists fn_tao_ma(text,text,text,text);
create or replace function fn_tao_ma(p_nhom text, p_benh text, p_muc_do text, p_mon text)
returns text language sql immutable as $$
  select p_nhom || coalesce(p_benh,'BT') || coalesce(p_muc_do,'') || '·' || p_mon;
$$;

-- 13) HÀM SINH TÊN CHẾ ĐỘ ĂN TỪ MÃ -------------------------
--    Tiền tố = Nhóm(1) + Bệnh(2) + Mức độ(0–2 số).  Phần sau '·' = Món.
--    DV (CPDV/ChPDV): "{Món} – Nhóm n (độ tuổi)"
--    BL:              "{Món} – {Bệnh} {mức} – Nhóm n (độ tuổi)"
--    select fn_ten_che_do('5BT·CPDV');         -> 'Cơm phòng dịch vụ – Nhóm 5 (7–15 tuổi)'
--    select fn_ten_che_do('4TH01·Sữa thường'); -> 'Sữa thường – Tiêu hoá 01 – Nhóm 4 (4–6 tuổi)'
drop function if exists fn_ten_che_do(text);
create or replace function fn_ten_che_do(p_ma text)
returns text language plpgsql immutable as $$
declare
  v_tien_to text;
  v_nhom    text;
  v_benh    text;
  v_muc_do  text;
  v_mon     text;
  v_ten_mon text;
  v_loai    text;
  v_tuoi    text;
  v_benh_tn text;
  v_phan_tuoi text;
  v_phan_benh text;
begin
  if p_ma is null or position('·' in p_ma) = 0 then
    return null;
  end if;
  v_tien_to := split_part(p_ma, '·', 1);
  v_mon     := substring(p_ma from position('·' in p_ma) + 1);
  v_nhom    := substring(v_tien_to from 1 for 1);
  v_benh    := upper(substring(v_tien_to from 2 for 2));
  v_muc_do  := substring(v_tien_to from 4);          -- '' nếu không có

  select ten, loai_suat into v_ten_mon, v_loai from dm_ma_mon where ma = v_mon;
  v_ten_mon := coalesce(v_ten_mon, v_mon);

  select mo_ta into v_tuoi   from dm_nhom_tuoi where ma = v_nhom;
  select mo_ta into v_benh_tn from dm_ma_benh  where ma = v_benh;

  v_phan_tuoi := 'Nhóm ' || v_nhom || coalesce(' (' || v_tuoi || ')', '');

  if v_loai = 'DV' then
    return v_ten_mon || ' – ' || v_phan_tuoi;
  end if;

  v_phan_benh := coalesce(v_benh_tn, v_benh);
  if v_muc_do is not null and v_muc_do <> '' then
    v_phan_benh := v_phan_benh || ' ' || v_muc_do;
  end if;
  return v_ten_mon || ' – ' || v_phan_benh || ' – ' || v_phan_tuoi;
end;
$$;
