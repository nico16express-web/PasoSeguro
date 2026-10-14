# PasoSeguro EBM

Control de acceso y asistencia para la Escuela Básica Mulchén: asistencia con
código QR, retiros anticipados con firma digital, atrasos, visitas, matrícula,
reportes y respaldo en CSV.

Esta versión es un sitio estático (HTML/CSS/JS puro, sin build ni frameworks)
que usa **Supabase** como backend: base de datos en tiempo real, fotos y
autenticación con roles (Dirección / Recepción).

## 1. Crear el proyecto en Supabase (gratis)

1. Entra a [supabase.com](https://supabase.com) y crea una cuenta.
2. Crea un **New project** (elige una contraseña de base de datos y guárdala,
   aunque no la necesitarás para esta app).
3. Espera a que el proyecto termine de aprovisionarse (1-2 minutos).

## 2. Crear las tablas y los permisos

1. En el menú lateral de Supabase, entra a **SQL Editor → New query**.
2. Abre el archivo [`schema.sql`](./schema.sql) de este proyecto, copia todo
   su contenido, pégalo en el editor y presiona **Run**.
3. Repite el mismo paso con [`storage_policies.sql`](./storage_policies.sql)
   (crea el espacio para guardar las fotos de apoderados y cédulas).
4. Ve a **Database → Replication** y activa el interruptor de Realtime para
   las tablas: `estudiantes`, `registros`, `retiros`, `atrasos`, `visitas`,
   `alertas`. (El script ya intenta activarlo solo; si algo falla ahí, hazlo
   manualmente desde esta pantalla.)

## 3. Copiar las credenciales a `config.js`

1. En Supabase, ve a **Configuración del proyecto → API**.
2. Copia el **Project URL** y la clave **anon public**.
3. Abre `config.js` en este proyecto y reemplaza los dos valores:

```js
window.SUPABASE_URL = "https://tu-proyecto.supabase.co";
window.SUPABASE_ANON_KEY = "ey......";
```

La clave `anon` es pública a propósito (así funciona Supabase): la seguridad
real la dan las políticas de acceso (RLS) que ya quedaron definidas en
`schema.sql` — por ejemplo, solo alguien con rol Dirección puede crear,
editar o eliminar fichas de estudiantes.

## 4. Revisar la confirmación de correo (opcional)

Por defecto, Supabase pide confirmar el correo antes de poder iniciar sesión.
Para un colegio con pocos usuarios internos, lo más simple es desactivarlo:

- **Authentication → Providers → Email → "Confirm email"** → apágalo.

Si lo dejas activado, cada persona deberá revisar su correo y confirmar la
cuenta antes de poder ingresar la primera vez.

## 5. Subir el proyecto a GitHub

```bash
git init
git add .
git commit -m "PasoSeguro EBM"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/pasoseguro-ebm.git
git push -u origin main
```

## 6. Desplegar en Vercel

1. Entra a [vercel.com](https://vercel.com) e inicia sesión con tu cuenta de
   GitHub.
2. **Add New → Project**, elige el repositorio que acabas de subir.
3. Vercel detecta que es un sitio estático: no necesitas configurar nada más
   (no hay "Build Command" ni "Output Directory" que cambiar).
4. Presiona **Deploy**. En un minuto tendrás una URL pública, por ejemplo
   `https://pasoseguro-ebm.vercel.app`.

## 7. Primer uso

1. Abre la URL que te dio Vercel.
2. Crea la primera cuenta (botón "¿Primera vez aquí? Crear cuenta"). **Esa
   primera cuenta queda automáticamente con rol Dirección.**
3. El resto del equipo (recepción, inspectoría) crea su propia cuenta y queda
   con rol Recepción por defecto.
4. Si necesitas que alguien más tenga rol Dirección, desde Supabase puedes
   editar manualmente la tabla `profiles` (columna `role`) en
   **Table Editor**, o pedirle a Dirección que en el futuro se agregue un
   panel de gestión de usuarios dentro de la app.

## Qué cambia frente a la versión de Claude

Esta versión funciona igual en el día a día, pero reemplaza las funciones
propias de Claude por sus equivalentes en Supabase:

| Función                          | En Claude                | En esta versión              |
|----------------------------------|---------------------------|-------------------------------|
| Datos compartidos en tiempo real | capacidad `db`            | Tabla en Postgres + Realtime  |
| Fotos de apoderados / cédulas    | capacidad `assets`        | Supabase Storage (bucket `fotos`) |
| Descarga de reportes CSV         | capacidad `downloads`     | Descarga normal del navegador |
| Rol Dirección / Recepción        | permiso "Puede editar"    | Rol guardado en la tabla `profiles`, con inicio de sesión por correo |

## Límites del plan gratuito de Supabase

El plan gratuito de Supabase incluye 500 MB de base de datos, 1 GB de
almacenamiento de archivos y pausa el proyecto tras 7 días sin uso (se
reactiva solo al volver a visitarlo, aunque la primera carga puede tardar
unos segundos más). Para una escuela de tamaño similar a Mulchén esto suele
ser más que suficiente; si crece mucho el historial, conviene exportar y
limpiar periódicamente desde el módulo Reportes.

## Estructura del proyecto

```
index.html            La aplicación completa (HTML + CSS + JS)
config.js             Credenciales de tu proyecto Supabase (edítalo)
schema.sql            Tablas y permisos (ejecutar una vez en Supabase)
storage_policies.sql  Bucket de fotos y sus permisos (ejecutar una vez)
```
