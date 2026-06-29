// ============================================================
//  DANH MUC DUNG CHUNG — Nhom tuoi · Ma benh · Khoa · Muc do · Mon · Sua · Sonde
//  Mot nguon duy nhat cho moi man. Nap TRUOC cac man:
//    <script src="danh-muc.js"></script>
//  Ma che do: {Nhom}{Benh}{MucDo}·{Mon}  (vd 4TH01·Sữa thường)
// ============================================================
(function (global) {
  "use strict";

  // 1) NHOM TUOI ('1'..'5')
  var AGE_GROUPS = [
    { value: "1", label: "Nhóm 1", sub: "< 6 tháng",   min_thang: 0,  max_thang: 6   },
    { value: "2", label: "Nhóm 2", sub: "6–12 tháng",  min_thang: 6,  max_thang: 12  },
    { value: "3", label: "Nhóm 3", sub: "1–3 tuổi",    min_thang: 12, max_thang: 36  },
    { value: "4", label: "Nhóm 4", sub: "4–6 tuổi",    min_thang: 36, max_thang: 72  },
    { value: "5", label: "Nhóm 5", sub: "7–15 tuổi",   min_thang: 72, max_thang: 180 }
  ];

  // 2) MA BENH (BT = dich vu; con lai = benh ly)
  var DISEASE_CODES = [
    { value: "BT", label: "BT", desc: "Bình thường",      dich_vu: true  },
    { value: "TH", label: "TH", desc: "Tiêu hoá",          dich_vu: false },
    { value: "GM", label: "GM", desc: "Gan mật",           dich_vu: false },
    { value: "TN", label: "TN", desc: "Thận niệu",         dich_vu: false },
    { value: "SD", label: "SD", desc: "Suy dinh dưỡng",    dich_vu: false },
    { value: "DD", label: "DD", desc: "Đái tháo đường",    dich_vu: false },
    { value: "NK", label: "NK", desc: "Nhiễm khuẩn",       dich_vu: false },
    { value: "TM", label: "TM", desc: "Tim mạch",          dich_vu: false }
  ];

  // 3) KHOA LAM SANG (ma tam K01..K21)
  var CLINICAL_DEPTS = [
    { value: "K01", label: "KHOA NỘI TỔNG QUÁT 1" },
    { value: "K02", label: "KHOA NỘI TỔNG QUÁT 2" },
    { value: "K03", label: "KHOA SỐT XUẤT HUYẾT" },
    { value: "K04", label: "KHOA THẬN - NỘI TIẾT" },
    { value: "K05", label: "KHOA PHỎNG" },
    { value: "K06", label: "KHOA NGOẠI THẬN - TIẾT NIỆU" },
    { value: "K07", label: "KHOA NGOẠI TỔNG HỢP" },
    { value: "K08", label: "KHOA NGOẠI CHỈNH HÌNH" },
    { value: "K09", label: "KHOA NGOẠI THẦN KINH" },
    { value: "K10", label: "KHOA HÔ HẤP" },
    { value: "K11", label: "KHOA TIÊU HÓA" },
    { value: "K12", label: "KHOA NHIỄM - THẦN KINH" },
    { value: "K13", label: "KHOA TIM MẠCH" },
    { value: "K14", label: "KHOA NGOẠI TIM MẠCH" },
    { value: "K15", label: "KHOA RĂNG HÀM MẶT" },
    { value: "K16", label: "KHOA TAI MŨI HỌNG" },
    { value: "K17", label: "KHOA HỒI SỨC NHIỄM" },
    { value: "K18", label: "KHOA TIM MẠCH CAN THIỆP" },
    { value: "K19", label: "KHOA SƠ SINH" },
    { value: "K20", label: "KHOA SƠ SINH 2" },
    { value: "K21", label: "KHOA HỒI SỨC TÍCH CỰC" }
  ];

  // 4) MUC DO BENH — so phu trong ma, do khoa lam sang gui len dinh duong.
  //    Ten bo sung sau (TODO).
  var MUC_DO_BENH = [
    { ma: "",   ten: null, mo_ta: "Không có mức độ" },
    { ma: "01", ten: null, mo_ta: null },
    { ma: "02", ten: null, mo_ta: null },
    { ma: "03", ten: null, mo_ta: null },
    { ma: "04", ten: null, mo_ta: null }
  ];

  // 5) MA MON (token trong ma che do)
  var MON_LOAI = [
    { ma: "CPDV",        ten: "Cơm phòng dịch vụ",  loai_suat: "DV", don_vi: "suất" },
    { ma: "ChPDV",       ten: "Cháo phòng dịch vụ", loai_suat: "DV", don_vi: "suất" },
    { ma: "Cơm",         ten: "Cơm",            loai_suat: "BL", don_vi: "suất" },
    { ma: "Cháo",        ten: "Cháo",           loai_suat: "BL", don_vi: "suất" },
    { ma: "Sữa thường",  ten: "Sữa thường",     loai_suat: "BL", don_vi: "ml"   },
    { ma: "Sữa đặc trị", ten: "Sữa đặc trị",    loai_suat: "BL", don_vi: "ml"   },
    { ma: "Sonde",       ten: "Sonde",          loai_suat: "BL", don_vi: "ml"   }
  ];

  // 6) DANH MUC SUA (loai: 'BT' thuong | 'ĐB' dac tri)
  var MA_SUA = [
    { ma: "SUA006", ten: "Sữa công thức số 1",    loai: "BT", bot_g: 13, nuoc_ml: 90,  tp_ml: 100 },
    { ma: "SUA007", ten: "Sữa công thức số 2",    loai: "BT", bot_g: 14, nuoc_ml: 90,  tp_ml: 100 },
    { ma: "SUA009", ten: "Sữa tăng trưởng",        loai: "BT", bot_g: 15, nuoc_ml: 90,  tp_ml: 100 },
    { ma: "SUA011", ten: "Sữa trẻ nhỏ",            loai: "BT", bot_g: 20, nuoc_ml: 180, tp_ml: 200 },
    { ma: "SUA013", ten: "Sữa học đường",          loai: "BT", bot_g: 22, nuoc_ml: 180, tp_ml: 200 },
    { ma: "SUA014", ten: "Sữa cao tuổi nhi",       loai: "BT", bot_g: 24, nuoc_ml: 180, tp_ml: 200 },
    { ma: "SUA023", ten: "Sữa tiêu hoá",           loai: "ĐB", bot_g: 18, nuoc_ml: 170, tp_ml: 200 },
    { ma: "SUA021", ten: "Sữa gan mật",            loai: "ĐB", bot_g: 18, nuoc_ml: 170, tp_ml: 200 },
    { ma: "SUA020", ten: "Sữa thận niệu A",        loai: "ĐB", bot_g: 17, nuoc_ml: 170, tp_ml: 200 },
    { ma: "SUA024", ten: "Sữa thận niệu B",        loai: "ĐB", bot_g: 15, nuoc_ml: 90,  tp_ml: 100 },
    { ma: "SUA010", ten: "Sữa suy dinh dưỡng A",   loai: "ĐB", bot_g: 16, nuoc_ml: 90,  tp_ml: 100 },
    { ma: "SUA015", ten: "Sữa suy dinh dưỡng B",   loai: "ĐB", bot_g: 25, nuoc_ml: 180, tp_ml: 200 },
    { ma: "SUA019", ten: "Sữa đái tháo đường A",   loai: "ĐB", bot_g: 22, nuoc_ml: 180, tp_ml: 200 },
    { ma: "SUA025", ten: "Sữa đái tháo đường B",   loai: "ĐB", bot_g: 16, nuoc_ml: 120, tp_ml: 130 },
    { ma: "SUA022", ten: "Sữa cao năng lượng",     loai: "ĐB", bot_g: 20, nuoc_ml: 150, tp_ml: 170 }
  ];

  // 7) GIOI HAN SUA DAC TRI THEO MA BENH
  var BENH_SUA = {
    BT: ["SUA022"],
    TH: ["SUA023"],
    GM: ["SUA021"],
    TN: ["SUA020", "SUA024"],
    SD: ["SUA010", "SUA015"],
    DD: ["SUA019", "SUA025"],
    NK: ["SUA022"],
    TM: ["SUA022"]
  };

  // 8) AP DUNG SUA THEO NHOM TUOI
  var SUA_TUOI = {
    SUA006: ["1"], SUA007: ["1","2"], SUA009: ["2","3"], SUA011: ["3","4"],
    SUA013: ["4","5"], SUA014: ["5"],
    SUA023: ["3","4","5"], SUA021: ["2","3","4","5"], SUA020: ["3","4","5"],
    SUA024: ["1","2"], SUA010: ["1","2","3"], SUA015: ["4","5"],
    SUA019: ["4","5"], SUA025: ["2","3"], SUA022: ["1","2","3","4","5"]
  };

  // 9) MA SONDE (ten chua co trong code — TODO)
  var MA_SONDE = [
    { ma: "BN-SS04", ten: null },
    { ma: "BN-SS05", ten: null },
    { ma: "BN-SS06", ten: null }
  ];

  // 10) KHUNG CU AN BENH LY — 11 cu/ngay, mon CO phuc vu moi cu
  var MEAL_SESSIONS = [
    { so: "01", gio: "03:00", mon: ["Sữa thường","Sữa đặc trị"],                        ghi_chu: "Nhũ nhi / trẻ bệnh nặng" },
    { so: "02", gio: "06:00", mon: ["Sữa thường","Sữa đặc trị","Cơm","Cháo","Sonde"],   ghi_chu: "" },
    { so: "03", gio: "09:00", mon: ["Sữa thường","Sữa đặc trị"],                        ghi_chu: "" },
    { so: "04", gio: "11:00", mon: ["Cơm","Cháo","Sonde"],                              ghi_chu: "" },
    { so: "05", gio: "12:00", mon: ["Sữa thường","Sữa đặc trị"],                        ghi_chu: "" },
    { so: "06", gio: "15:00", mon: ["Sữa thường","Sữa đặc trị"],                        ghi_chu: "" },
    { so: "07", gio: "16:00", mon: ["Sonde"],                                           ghi_chu: "" },
    { so: "08", gio: "17:00", mon: ["Cơm","Cháo"],                                      ghi_chu: "" },
    { so: "09", gio: "18:00", mon: ["Sữa thường","Sữa đặc trị"],                        ghi_chu: "" },
    { so: "10", gio: "21:00", mon: ["Sữa thường","Sữa đặc trị","Sonde"],                ghi_chu: "" },
    { so: "11", gio: "00:00", mon: ["Sữa thường","Sữa đặc trị"],                        ghi_chu: "Nhũ nhi / trẻ bệnh nặng" }
  ];

  var GHI_CHU_BENH_LY = [
    "Tất cả món ăn ít muối, ít đường, không gia vị cay.",
    "Điều chỉnh theo chỉ định dinh dưỡng của bác sĩ từng ca bệnh.",
    "Cữ 01 (03:00) và cữ 11 (00:00) chủ yếu dành cho nhũ nhi và trẻ bệnh nặng."
  ];

  // ── Helpers ──
  function getAge(v)     { for (var i=0;i<AGE_GROUPS.length;i++)     if (AGE_GROUPS[i].value===String(v))     return AGE_GROUPS[i];     return null; }
  function getDisease(v) { for (var i=0;i<DISEASE_CODES.length;i++)  if (DISEASE_CODES[i].value===String(v))  return DISEASE_CODES[i];  return null; }
  function getDept(v)    { for (var i=0;i<CLINICAL_DEPTS.length;i++) if (CLINICAL_DEPTS[i].value===String(v)) return CLINICAL_DEPTS[i]; return null; }
  function getMon(ma)    { for (var i=0;i<MON_LOAI.length;i++)       if (MON_LOAI[i].ma===ma)                 return MON_LOAI[i];       return null; }
  function getSua(ma)    { for (var i=0;i<MA_SUA.length;i++)         if (MA_SUA[i].ma===ma)                   return MA_SUA[i];         return null; }
  function getCu(so)     { for (var i=0;i<MEAL_SESSIONS.length;i++)  if (MEAL_SESSIONS[i].so===String(so))    return MEAL_SESSIONS[i];  return null; }

  // Sua dac tri duoc phep theo ma benh
  function suaDacTriChoBenh(maBenh) { return (BENH_SUA[maBenh] || []).slice(); }
  // Sua thuong (BT) loc theo nhom tuoi
  function suaThuongChoTuoi(nhom) {
    return MA_SUA.filter(function(s){ return s.loai==="BT" && (SUA_TUOI[s.ma]||[]).indexOf(String(nhom))>=0; }).map(function(s){return s.ma;});
  }
  // Cac cu CO phuc vu mot mon
  function cuChoMon(monMa) { return MEAL_SESSIONS.filter(function(c){return c.mon.indexOf(monMa)>=0;}).map(function(c){return c.so;}); }

  function nhomTuoiTuNgaySinh(ngaySinh) {
    if (!ngaySinh) return "5";
    var now = new Date(), ns = new Date(ngaySinh);
    var months = (now.getFullYear()-ns.getFullYear())*12 + (now.getMonth()-ns.getMonth()) - (now.getDate()<ns.getDate()?1:0);
    for (var i=0;i<AGE_GROUPS.length;i++) if (months < AGE_GROUPS[i].max_thang) return AGE_GROUPS[i].value;
    return "5";
  }

  // 11) DUNG MA:  {Nhom}{Benh}{MucDo}·{Mon}
  //    taoMa("1","BT","","CPDV")          -> "1BT·CPDV"
  //    taoMa("4","TH","01","Sữa thường")  -> "4TH01·Sữa thường"
  function taoMa(nhom, benh, mucDo, mon) {
    return "" + nhom + (benh || "BT") + (mucDo || "") + "·" + mon;
  }

  // 12) TACH MA:  "4TH01·Sữa thường" -> {nhom:"4", benh:"TH", mucDo:"01", mon:"Sữa thường"}
  //    Tien to = Nhom(1 ky tu) + Benh(2 ky tu) + Muc do(0-2 chu so).
  function tachMa(ma) {
    if (!ma) return null;
    var phan = String(ma).split("·");
    if (phan.length < 2) return null;
    var tienTo = phan[0], mon = phan.slice(1).join("·");
    var m = tienTo.match(/^(\d)([A-Za-zĐđ]{2})(\d{0,2})$/);
    if (!m) return null;
    return { nhom: m[1], benh: m[2].toUpperCase(), mucDo: m[3] || "", mon: mon };
  }

  // 13) TEN CHE DO AN TU THANH PHAN
  //    DV (CPDV/ChPDV): "{Mon} – Nhom n (do tuoi)"
  //    BL:              "{Mon} – {Benh} {muc} – Nhom n (do tuoi)"
  function tenTuThanhPhan(nhom, benh, mucDo, mon) {
    var monObj  = getMon(mon);
    var ageObj  = getAge(nhom);
    var benhObj = getDisease(benh);
    var tenMon  = monObj ? monObj.ten : mon;
    var phanTuoi = ageObj ? ("Nhóm " + nhom + " (" + ageObj.sub + ")") : ("Nhóm " + nhom);
    // Mon dich vu: khong gan benh/muc do
    if (monObj && monObj.loai_suat === "DV") {
      return tenMon + " – " + phanTuoi;
    }
    // Mon benh ly: gan ten benh + muc do (so tran)
    var phanBenh = benhObj ? benhObj.desc : (benh || "");
    if (mucDo) phanBenh += " " + mucDo;
    return tenMon + " – " + phanBenh + " – " + phanTuoi;
  }

  // 14) TEN CHE DO AN TU MA:  tenCheDoAn("4TH01·Sữa thường")
  //    -> "Sữa thường – Tiêu hoá 01 – Nhóm 4 (4–6 tuổi)"
  function tenCheDoAn(ma) {
    var p = tachMa(ma);
    if (!p) return null;
    return tenTuThanhPhan(p.nhom, p.benh, p.mucDo, p.mon);
  }

  var DANH_MUC = {
    AGE_GROUPS: AGE_GROUPS,
    DISEASE_CODES: DISEASE_CODES,
    CLINICAL_DEPTS: CLINICAL_DEPTS,
    MUC_DO_BENH: MUC_DO_BENH,
    MON_LOAI: MON_LOAI,
    MA_SUA: MA_SUA,
    BENH_SUA: BENH_SUA,
    SUA_TUOI: SUA_TUOI,
    MA_SONDE: MA_SONDE,
    MEAL_SESSIONS: MEAL_SESSIONS,
    GHI_CHU_BENH_LY: GHI_CHU_BENH_LY,
    getAge: getAge,
    getDisease: getDisease,
    getDept: getDept,
    getMon: getMon,
    getSua: getSua,
    getCu: getCu,
    suaDacTriChoBenh: suaDacTriChoBenh,
    suaThuongChoTuoi: suaThuongChoTuoi,
    cuChoMon: cuChoMon,
    nhomTuoiTuNgaySinh: nhomTuoiTuNgaySinh,
    taoMa: taoMa,
    tachMa: tachMa,
    tenTuThanhPhan: tenTuThanhPhan,
    tenCheDoAn: tenCheDoAn
  };

  global.DANH_MUC = DANH_MUC;
  if (typeof module !== "undefined" && module.exports) module.exports = DANH_MUC;
})(typeof window !== "undefined" ? window : this);
