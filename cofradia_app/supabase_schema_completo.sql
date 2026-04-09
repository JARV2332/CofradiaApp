-- =============================================================================
-- Cofradía App — esquema completo para proyecto Supabase NUEVO
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query → Run
-- Orden: de arriba a abajo (o todo el archivo de una vez).
-- =============================================================================

-- Extensiones habituales en Supabase
create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1) Tabla profiles (roles de usuarios; user_id = auth.users.id)
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'encargado',
  created_at timestamptz not null default now(),
  constraint profiles_role_check check (
    role in ('super_admin', 'admin', 'secretario', 'encargado')
  )
);

create index if not exists profiles_role_idx on public.profiles (role);

-- -----------------------------------------------------------------------------
-- 2) Eventos
-- -----------------------------------------------------------------------------
create table if not exists public.eventos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text not null default '',
  fecha text not null,
  hora text not null,
  lugar text not null default '',
  tipo text not null default 'General',
  estado text not null default 'activo',
  cupo int not null default 0
);

-- -----------------------------------------------------------------------------
-- 3) Cofrades
-- -----------------------------------------------------------------------------
create table if not exists public.cofrades (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  apellidos text not null default '',
  telefono text not null default '',
  email text not null default '',
  categoria text not null default '',
  estado text not null default '',
  agrupacion text not null default '',
  fecha_alta text not null default '',
  foto_url text,
  created_at timestamptz not null default now()
);

create index if not exists cofrades_created_at_idx on public.cofrades (created_at desc);

-- -----------------------------------------------------------------------------
-- 4) Carnets (QR apunta al id del carnet)
-- -----------------------------------------------------------------------------
create table if not exists public.carnets (
  id uuid primary key default gen_random_uuid(),
  cofrade_id uuid not null references public.cofrades (id) on delete cascade,
  active boolean not null default true,
  issued_at timestamptz not null default now()
);

create index if not exists carnets_cofrade_active_idx
  on public.carnets (cofrade_id, active, issued_at desc);

-- -----------------------------------------------------------------------------
-- 5) Asistencias (único por evento + carnet → evita duplicados en QR)
-- -----------------------------------------------------------------------------
create table if not exists public.asistencias (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos (id) on delete cascade,
  carnet_id uuid not null references public.carnets (id) on delete cascade,
  estado text not null default 'PRESENTE',
  created_at timestamptz not null default now(),
  constraint asistencias_evento_carnet_unique unique (evento_id, carnet_id)
);

create index if not exists asistencias_evento_idx on public.asistencias (evento_id);
create index if not exists asistencias_created_at_idx on public.asistencias (created_at desc);

-- -----------------------------------------------------------------------------
-- 6) Catálogo (secciones, divisiones, agrupaciones)
-- -----------------------------------------------------------------------------
create table if not exists public.catalogo_cofradia (
  id uuid primary key default gen_random_uuid(),
  tipo text not null,
  nombre text not null,
  activo boolean not null default true,
  orden int not null default 0
);

create index if not exists catalogo_tipo_activo_idx
  on public.catalogo_cofradia (tipo, activo, orden);

-- Datos mínimos (la app tiene fallback si faltan filas)
insert into public.catalogo_cofradia (tipo, nombre, activo, orden)
select * from (values
  ('agrupacion'::text, 'Rosario Viviente'::text, true, 1),
  ('agrupacion', 'Rosario Perpetuo', true, 2)
) as v(tipo, nombre, activo, orden)
where not exists (
  select 1 from public.catalogo_cofradia c where c.tipo = v.tipo and c.nombre = v.nombre
);

-- -----------------------------------------------------------------------------
-- 7) RLS: usuarios autenticados pueden usar las tablas (app con login)
--    (Ajusta después si quieres políticas más finas por rol.)
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.eventos enable row level security;
alter table public.cofrades enable row level security;
alter table public.carnets enable row level security;
alter table public.asistencias enable row level security;
alter table public.catalogo_cofradia enable row level security;

-- Políticas idempotentes: borrar si existieran nombres viejos
drop policy if exists "profiles_authenticated_all" on public.profiles;
create policy "profiles_authenticated_all" on public.profiles
  for all to authenticated using (true) with check (true);

drop policy if exists "eventos_authenticated_all" on public.eventos;
create policy "eventos_authenticated_all" on public.eventos
  for all to authenticated using (true) with check (true);

drop policy if exists "cofrades_authenticated_all" on public.cofrades;
create policy "cofrades_authenticated_all" on public.cofrades
  for all to authenticated using (true) with check (true);

drop policy if exists "carnets_authenticated_all" on public.carnets;
create policy "carnets_authenticated_all" on public.carnets
  for all to authenticated using (true) with check (true);

drop policy if exists "asistencias_authenticated_all" on public.asistencias;
create policy "asistencias_authenticated_all" on public.asistencias
  for all to authenticated using (true) with check (true);

drop policy if exists "catalogo_authenticated_select" on public.catalogo_cofradia;
create policy "catalogo_authenticated_select" on public.catalogo_cofradia
  for select to authenticated using (true);

drop policy if exists "catalogo_authenticated_write" on public.catalogo_cofradia;
create policy "catalogo_authenticated_write" on public.catalogo_cofradia
  for all to authenticated using (true) with check (true);

-- -----------------------------------------------------------------------------
-- 8) Trigger: al registrarse en Auth, crear fila en profiles
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, role)
  values (new.id, 'encargado')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
-- Si falla aquí, prueba: ... execute procedure public.handle_new_user();
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 9) Storage: bucket público cofrade-fotos + políticas
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('cofrade-fotos', 'cofrade-fotos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "cofrade-fotos public read" on storage.objects;
create policy "cofrade-fotos public read"
on storage.objects for select
to public
using (bucket_id = 'cofrade-fotos');

drop policy if exists "cofrade-fotos authenticated upload" on storage.objects;
create policy "cofrade-fotos authenticated upload"
on storage.objects for insert
to authenticated
with check (bucket_id = 'cofrade-fotos');

drop policy if exists "cofrade-fotos authenticated update" on storage.objects;
create policy "cofrade-fotos authenticated update"
on storage.objects for update
to authenticated
using (bucket_id = 'cofrade-fotos')
with check (bucket_id = 'cofrade-fotos');

drop policy if exists "cofrade-fotos authenticated delete" on storage.objects;
create policy "cofrade-fotos authenticated delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'cofrade-fotos');

-- =============================================================================
-- Listo. Siguiente: crea un usuario en Authentication, luego:
-- update public.profiles set role = 'super_admin' where user_id = 'UUID';
-- =============================================================================
