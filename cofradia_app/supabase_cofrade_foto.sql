-- Foto de cofrade: columna + bucket público de Storage
-- Ejecutar en el SQL Editor de Supabase (proyecto Cofradía).

-- 1) Columna en cofrades
alter table public.cofrades
  add column if not exists foto_url text;

comment on column public.cofrades.foto_url is 'URL pública en Storage (bucket cofrade-fotos)';

-- 2) Bucket (público para que el PDF y listas carguen la imagen sin JWT)
insert into storage.buckets (id, name, public)
values ('cofrade-fotos', 'cofrade-fotos', true)
on conflict (id) do update set public = excluded.public;

-- 3) Políticas Storage: lectura pública, escritura solo usuarios autenticados
-- (ajusta si usas otro rol; anon no podrá subir)

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
