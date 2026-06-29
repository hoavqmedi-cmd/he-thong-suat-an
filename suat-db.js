// ============================================================
//  LỚP TRUY CẬP SUPABASE DÙNG CHUNG (Giai đoạn 1 — cơm/cháo)
//  Dùng cho cả màn Khoa (he-thong-suat-an.html) và màn KDD
//  (man-hinh-kdd.html). KHÔNG cần sửa file này.
// ============================================================
(function () {
  "use strict";
  var CONFIG = window.SUPABASE_CONFIG || {};
  var URL = CONFIG.url, KEY = CONFIG.anonKey;
  var TABLE = "dang_ky_suat";
  var client = null;

  function configured() {
    return !!(URL && KEY &&
      URL.indexOf("http") === 0 &&
      URL.indexOf("DAN_") < 0 &&
      KEY.indexOf("DAN_") < 0);
  }

  function getClient() {
    if (client) return client;
    if (!configured()) return null;
    if (!window.supabase || !window.supabase.createClient) {
      console.error("[suat-db] Chưa nạp thư viện supabase-js (kiểm tra thẻ <script> CDN).");
      return null;
    }
    client = window.supabase.createClient(URL, KEY);
    return client;
  }

  window.SUAT_DB = {
    configured: configured,

    // Ghi 1 mảng suất (mỗi phần tử = 1 dòng dang_ky_suat)
    insert: function (rows) {
      var c = getClient();
      if (!c) return Promise.resolve({ error: { message: "Chưa cấu hình Supabase" } });
      // upsert + ngay để mỗi (ma_bn, ngay, cu) chỉ 1 dòng (gửi lại = ghi đè, không tạo trùng)
      var t = new Date().toISOString().slice(0, 10);
      var r = (rows || []).map(function (x) { return Object.assign({ ngay: x.ngay || t }, x); });
      return c.from(TABLE).upsert(r, { onConflict: "ma_bn,ngay,cu,loai" });
    },

    // Đọc các suất đang chờ KDD xử lý (trạng thái khoa_gui)
    fetchChoXuLy: function () {
      var c = getClient();
      if (!c) return Promise.resolve({ data: [], error: { message: "Chưa cấu hình Supabase" } });
      return c.from(TABLE).select("*")
        .eq("trang_thai", "khoa_gui")
        .order("created_at", { ascending: true });
    },

    // Cập nhật trạng thái cho 1 mảng id (duyệt / từ chối)
    updateTrangThai: function (ids, trangThai, lyDo) {
      var c = getClient();
      if (!c || !ids || !ids.length) return Promise.resolve({ error: null });
      var patch = { trang_thai: trangThai };
      if (lyDo != null) patch.ly_do_tu_choi = lyDo;
      return c.from(TABLE).update(patch).in("id", ids);
    },

    // Đọc danh sách bệnh nhân (lọc theo loai_bn: 'DV' | 'BL')
    fetchBenhNhan: function (loai) {
      var c = getClient();
      if (!c) return Promise.resolve({ data: [], error: { message: "Chưa cấu hình Supabase" } });
      var q = c.from("benh_nhan").select("*");
      if (loai) q = q.eq("loai_bn", loai);
      return q.order("ma_bn", { ascending: true });
    },

    // Cập nhật 1 bệnh nhân trong benh_nhan (theo ma_bn + loai_bn)
    updateBenhNhan: function (maBn, loai, patch) {
      var c = getClient();
      if (!c || !maBn) return Promise.resolve({ error: null });
      var q = c.from("benh_nhan").update(patch).eq("ma_bn", maBn);
      if (loai) q = q.eq("loai_bn", loai);
      // .then() để KÍCH HOẠT request ngay (builder của supabase-js là "lười",
      // không await/.then thì request không được gửi → ghi không lưu).
      return q.then(function (r) { return r; });
    }
  };
})();
