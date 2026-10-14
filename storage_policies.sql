-- ============================================================
-- PasoSeguro EBM — almacenamiento de fotos (apoderados, cédulas)
-- ============================================================
-- Ejecuta esto en el SQL Editor DESPUÉS de schema.sql.
-- Crea un bucket público llamado "fotos" (público para que las
-- imágenes se puedan mostrar directamente en <img src="...">;
-- solo usuarios con sesión iniciada pueden subir archivos).
-- ============================================================

insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do nothing;

drop policy if exists "fotos_lectura_publica" on storage.objects;
create policy "fotos_lectura_publica"
  on storage.objects for select
  using (bucket_id = 'fotos');

drop policy if exists "fotos_subida_autenticados" on storage.objects;
create policy "fotos_subida_autenticados"
  on storage.objects for insert
  with check (bucket_id = 'fotos' and auth.role() = 'authenticated');

drop policy if exists "fotos_actualizacion_autenticados" on storage.objects;
create policy "fotos_actualizacion_autenticados"
  on storage.objects for update
  using (bucket_id = 'fotos' and auth.role() = 'authenticated');
