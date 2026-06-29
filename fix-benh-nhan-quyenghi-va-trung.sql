-- ============================================================
--  VÁ BẢNG benh_nhan — Giai đoạn 1
--  Dán toàn bộ file này vào: Supabase → SQL Editor → New query → Run
--  Sửa 2 việc:
--    1) Cho phép GHI (đang chỉ đọc được, ghi bị RLS chặn → chuyển DV→BL không lưu)
--    2) Dọn dữ liệu trùng (1 BN đang có cả dòng DV lẫn BL) + chặn trùng về sau
-- ============================================================

-- ── 1. QUYỀN GHI ──
-- Tắt RLS cho giống bảng dang_ky_suat (mức demo, dùng anon/publishable key).
-- LƯU Ý BẢO MẬT: ai có URL + key đều đọc/ghi được. Khi chạy thật với dữ liệu
-- bệnh nhân thật, hãy bật lại RLS + policy theo vai trò (báo để soạn policy).
alter table benh_nhan disable row level security;

-- QUAN TRỌNG: tắt RLS thôi CHƯA đủ — phải cấp quyền ghi cho vai trò anon
-- (key trên trình duyệt chạy bằng role anon). Thiếu bước này thì đọc được
-- nhưng GHI sẽ thất bại âm thầm → chuyển DV→BL không lưu, bị "trả về".
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table benh_nhan to anon, authenticated;

-- ── 2A. XEM CÁC MÃ ĐANG TRÙNG (chạy riêng nếu muốn kiểm tra trước) ──
-- select ma_bn, count(*) so_dong, array_agg(loai_bn) cac_loai
-- from benh_nhan group by ma_bn having count(*) > 1;

-- ── 2B. DỌN TRÙNG: với mã có cả DV và BL → BỎ dòng BL, GIỮ dòng DV ──
-- (giữ DV để còn test nút "Chuyển sang bệnh lý"; nếu muốn giữ BL thì đảo lại
--  điều kiện: xoá loai_bn='DV' khi tồn tại dòng 'BL')
delete from benh_nhan b
where b.loai_bn = 'BL'
  and exists (
    select 1 from benh_nhan d
    where d.ma_bn = b.ma_bn and d.loai_bn = 'DV'
  );

-- ── 2C. CHẶN TRÙNG VỀ SAU: mỗi BN chỉ 1 dòng ──
-- (Bỏ qua bước này nếu đã có ràng buộc unique trên ma_bn)
alter table benh_nhan
  add constraint uq_benh_nhan_ma_bn unique (ma_bn);

-- ── 3. KIỂM TRA LẠI ──
select loai_bn, count(*) so_bn from benh_nhan group by loai_bn;
-- Kỳ vọng: không còn mã nào nằm cả 2 bên; chuyển DV→BL sẽ lưu được.
