-- =============================================================
-- Menjadikan sebuah akun sebagai admin
-- =============================================================
-- Semua akun baru otomatis memiliki role 'user' (hanya bisa melihat).
-- Hanya admin yang bisa menambah, mengubah, dan menghapus barang.
--
-- Cara pakai:
--   1. Daftar akun lebih dulu dari halaman aplikasi.
--   2. Ganti email di bawah dengan email akun Anda.
--   3. Jalankan di Supabase SQL Editor.
--   4. Keluar lalu masuk kembali agar role terbaru terbaca aplikasi.
-- =============================================================

update public.profiles
set role = 'admin'
where id = (
    select id
    from auth.users
    where email = 'email-admin-anda@example.com'
);
