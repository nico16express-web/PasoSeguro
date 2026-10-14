-- ============================================================
-- PasoSeguro EBM — esquema de base de datos para Supabase
-- ============================================================
-- Cómo usarlo:
-- 1. Entra a tu proyecto en supabase.com → SQL Editor → New query
-- 2. Pega TODO este archivo y presiona "Run"
-- 3. Ve a Database → Replication y activa Realtime para las tablas:
--    estudiantes, registros, retiros, atrasos, visitas, alertas
--    (o ejecuta los "alter publication" que están al final de este
--    archivo; si alguno falla porque ya estaba agregado, ignóralo)
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- Perfiles: un registro por persona que inicia sesión, con su rol.
-- La primera persona que se registra queda como "direccion".
-- ------------------------------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'recepcion' check (role in ('recepcion','direccion')),
  created_at timestamptz default now()
);

alter table profiles enable row level security;

drop policy if exists "profiles_select" on profiles;
create policy "profiles_select" on profiles for select using (auth.role() = 'authenticated');

drop policy if exists "profiles_insert_propio" on profiles;
create policy "profiles_insert_propio" on profiles for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_propio" on profiles;
create policy "profiles_update_propio" on profiles for update using (auth.uid() = id);

-- Función: si todavía no existe nadie con rol "direccion", asigna ese
-- rol a quien la ejecuta. Se llama automáticamente la primera vez que
-- alguien crea una cuenta en la app.
create or replace function claim_direccion()
returns void
language plpgsql
security definer
as $$
begin
  if not exists (select 1 from profiles where role = 'direccion') then
    update profiles set role = 'direccion' where id = auth.uid();
  end if;
end;
$$;

-- Función auxiliar usada por las políticas de abajo: ¿la persona que
-- hace la consulta tiene rol "direccion"?
create or replace function is_direccion()
returns boolean
language sql
security definer
stable
as $$
  select exists(select 1 from profiles where id = auth.uid() and role = 'direccion');
$$;

-- ------------------------------------------------------------
-- Estudiantes: fichas, apoderados y restricciones de retiro.
-- Solo Dirección puede crear, editar o eliminar fichas.
-- ------------------------------------------------------------
create table if not exists estudiantes (
  id text primary key,
  "nombre" text not null,
  "rut" text not null,
  "curso" text,
  "codigo" text,
  "genero" text,
  "restriccionRetiro" boolean default false,
  "restriccionMotivo" text,
  "apoderados" jsonb default '[]'::jsonb,
  "fotoId" text,
  "matricula" jsonb,
  "creado" timestamptz default now()
);
alter table estudiantes enable row level security;
drop policy if exists "estudiantes_select" on estudiantes;
create policy "estudiantes_select" on estudiantes for select using (auth.role() = 'authenticated');
drop policy if exists "estudiantes_insert" on estudiantes;
create policy "estudiantes_insert" on estudiantes for insert with check (is_direccion());
drop policy if exists "estudiantes_update" on estudiantes;
create policy "estudiantes_update" on estudiantes for update using (is_direccion());
drop policy if exists "estudiantes_delete" on estudiantes;
create policy "estudiantes_delete" on estudiantes for delete using (is_direccion());

-- ------------------------------------------------------------
-- Registros de asistencia (entradas/salidas)
-- ------------------------------------------------------------
create table if not exists registros (
  id uuid primary key default gen_random_uuid(),
  "estudianteId" text,
  "estudianteNombre" text,
  "tipo" text,
  "metodo" text,
  "funcionario" text,
  "timestamp" timestamptz default now(),
  "dateKey" text
);
alter table registros enable row level security;
drop policy if exists "registros_select" on registros;
create policy "registros_select" on registros for select using (auth.role() = 'authenticated');
drop policy if exists "registros_insert" on registros;
create policy "registros_insert" on registros for insert with check (auth.role() = 'authenticated');
drop policy if exists "registros_update" on registros;
create policy "registros_update" on registros for update using (auth.role() = 'authenticated');
drop policy if exists "registros_delete" on registros;
create policy "registros_delete" on registros for delete using (is_direccion());

-- ------------------------------------------------------------
-- Retiros anticipados
-- ------------------------------------------------------------
create table if not exists retiros (
  id uuid primary key default gen_random_uuid(),
  "estudianteId" text,
  "estudianteNombre" text,
  "apoderadoNombre" text,
  "apoderadoRut" text,
  "excepcion" boolean default false,
  "firmaId" text,
  "funcionario" text,
  "timestamp" timestamptz default now(),
  "dateKey" text
);
alter table retiros enable row level security;
drop policy if exists "retiros_select" on retiros;
create policy "retiros_select" on retiros for select using (auth.role() = 'authenticated');
drop policy if exists "retiros_insert" on retiros;
create policy "retiros_insert" on retiros for insert with check (auth.role() = 'authenticated');
drop policy if exists "retiros_update" on retiros;
create policy "retiros_update" on retiros for update using (auth.role() = 'authenticated');
drop policy if exists "retiros_delete" on retiros;
create policy "retiros_delete" on retiros for delete using (is_direccion());

-- ------------------------------------------------------------
-- Atrasos (tickets digitales)
-- ------------------------------------------------------------
create table if not exists atrasos (
  id uuid primary key default gen_random_uuid(),
  "estudianteId" text,
  "estudianteNombre" text,
  "curso" text,
  "motivo" text,
  "origen" text,
  "justificado" boolean,
  "observacion" text,
  "destino" text,
  "folio" text,
  "funcionario" text,
  "timestamp" timestamptz default now(),
  "dateKey" text
);
alter table atrasos enable row level security;
drop policy if exists "atrasos_select" on atrasos;
create policy "atrasos_select" on atrasos for select using (auth.role() = 'authenticated');
drop policy if exists "atrasos_insert" on atrasos;
create policy "atrasos_insert" on atrasos for insert with check (auth.role() = 'authenticated');
drop policy if exists "atrasos_update" on atrasos;
create policy "atrasos_update" on atrasos for update using (auth.role() = 'authenticated');
drop policy if exists "atrasos_delete" on atrasos;
create policy "atrasos_delete" on atrasos for delete using (is_direccion());

-- ------------------------------------------------------------
-- Visitas y proveedores
-- ------------------------------------------------------------
create table if not exists visitas (
  id uuid primary key default gen_random_uuid(),
  "nombre" text,
  "rut" text,
  "motivo" text,
  "destino" text,
  "fotoCedulaId" text,
  "horaEntrada" timestamptz default now(),
  "horaSalida" timestamptz,
  "funcionario" text,
  "dateKey" text
);
alter table visitas enable row level security;
drop policy if exists "visitas_select" on visitas;
create policy "visitas_select" on visitas for select using (auth.role() = 'authenticated');
drop policy if exists "visitas_insert" on visitas;
create policy "visitas_insert" on visitas for insert with check (auth.role() = 'authenticated');
drop policy if exists "visitas_update" on visitas;
create policy "visitas_update" on visitas for update using (auth.role() = 'authenticated');
drop policy if exists "visitas_delete" on visitas;
create policy "visitas_delete" on visitas for delete using (is_direccion());

-- ------------------------------------------------------------
-- Alertas en tiempo real
-- ------------------------------------------------------------
create table if not exists alertas (
  id uuid primary key default gen_random_uuid(),
  "tipo" text,
  "mensaje" text,
  "timestamp" timestamptz default now(),
  "leida" boolean default false,
  "dateKey" text
);
alter table alertas enable row level security;
drop policy if exists "alertas_select" on alertas;
create policy "alertas_select" on alertas for select using (auth.role() = 'authenticated');
drop policy if exists "alertas_insert" on alertas;
create policy "alertas_insert" on alertas for insert with check (auth.role() = 'authenticated');
drop policy if exists "alertas_update" on alertas;
create policy "alertas_update" on alertas for update using (auth.role() = 'authenticated');
drop policy if exists "alertas_delete" on alertas;
create policy "alertas_delete" on alertas for delete using (is_direccion());

-- ------------------------------------------------------------
-- Realtime: para que los cambios se vean al instante en todos los
-- dispositivos conectados. Si alguna línea falla porque la tabla ya
-- estaba agregada, es normal: ignora ese error y sigue con las demás
-- (o hazlo desde Database → Replication en el panel de Supabase).
-- ------------------------------------------------------------
alter publication supabase_realtime add table estudiantes;
alter publication supabase_realtime add table registros;
alter publication supabase_realtime add table retiros;
alter publication supabase_realtime add table atrasos;
alter publication supabase_realtime add table visitas;
alter publication supabase_realtime add table alertas;
