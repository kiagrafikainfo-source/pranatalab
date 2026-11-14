-- =============================================================
-- Simple Inventory - Struktur database Supabase
-- =============================================================
-- Cara pakai:
--   1. Buka project Anda di https://supabase.com
--   2. Masuk ke menu SQL Editor -> New query
--   3. Salin seluruh isi file ini, tempel, lalu tekan Run
--
-- Script ini membuat:
--   - tabel profiles (nama dan role tiap akun)
--   - tabel items (data barang)
--   - trigger pembuat profil otomatis saat akun baru mendaftar
--   - Row Level Security (RLS) agar hak akses dijaga database
-- =============================================================

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text,
    role text not null default 'user' check (role in ('admin', 'user')),
    created_at timestamptz not null default now()
);

create table if not exists public.items (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    category text not null,
    stock integer not null default 0 check (stock >= 0),
    unit text not null,
    created_at timestamptz not null default now()
);

/* Profil baru otomatis dibuat ketika akun Auth berhasil mendaftar. */
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    insert into public.profiles (id, full_name, role)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.email),
        'user'
    )
    on conflict (id) do update
        set full_name = excluded.full_name;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

/* Role diperiksa di database; menyembunyikan tombol di UI saja bukan keamanan. */
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select p.role from public.profiles p where p.id = auth.uid()
$$;

revoke all on function public.current_user_role() from public;
grant execute on function public.current_user_role() to authenticated;
grant usage on schema public to authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.items to authenticated;

alter table public.profiles enable row level security;
alter table public.items enable row level security;

drop policy if exists "profiles_read_own" on public.profiles;
create policy "profiles_read_own"
on public.profiles for select to authenticated
using (id = auth.uid());

drop policy if exists "items_read_authenticated" on public.items;
create policy "items_read_authenticated"
on public.items for select to authenticated
using (true);

drop policy if exists "items_insert_admin" on public.items;
create policy "items_insert_admin"
on public.items for insert to authenticated
with check (public.current_user_role() = 'admin');

drop policy if exists "items_update_admin" on public.items;
create policy "items_update_admin"
on public.items for update to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

drop policy if exists "items_delete_admin" on public.items;
create policy "items_delete_admin"
on public.items for delete to authenticated
using (public.current_user_role() = 'admin');
