# Platanitos · Backend (NestJS + Prisma + PostgreSQL)

API REST de la app Platanitos. La guía completa de instalación (herramientas,
base de datos, `.env`, ejecución de la app y solución de problemas) está en el
[README general](../README.md#10-guía-de-instalación-paso-a-paso).

## Inicio rápido

Desde esta carpeta (`backend/`):

```powershell
npm install                     # 1. dependencias
Copy-Item .env.example .env     # 2. configuración: completa DATABASE_URL y JWT_ACCESS_SECRET
npm run db:setup                # 3. crea la base, aplica migraciones, genera Prisma y carga datos
npm run start:dev               # 4. API en http://localhost:3000 (prueba /health)
```

Como alternativa al paso 3, puedes crear una base vacía `platanitos` y ejecutar
[`database/platanitos.sql`](database/platanitos.sql) en pgAdmin o `psql`, y
luego `npx prisma generate`.

La explicación de cada variable de `.env` está en el
[paso 5 del README general](../README.md#paso-5-configurar-backendenv).
Nunca subas `.env` ni pongas credenciales reales en `.env.example`.

## Scripts

| Comando | Descripción |
| :--- | :--- |
| `npm run start:dev` | API con recarga automática |
| `npm run build` | Compila a `dist/` |
| `npm run start:prod` | Ejecuta la versión compilada |
| `npm run db:setup` | Crea la base si no existe, `prisma migrate deploy`, `prisma generate` y seed |
| `npm run db:seed` | Carga los datos de demostración (idempotente) |
| `npm run db:sql` | Regenera `database/platanitos.sql` a partir de las migraciones y `database/seed.sql` |
| `npm run test` | Pruebas unitarias |
| `npm run test:e2e -- --run` | Pruebas e2e contra la base configurada en `.env` |
| `npm run lint` | Análisis estático con oxlint |

## Base de datos

| Archivo | Uso |
| :--- | :--- |
| `prisma/schema.prisma` | Modelo de datos |
| `prisma/migrations/` | Migraciones versionadas (se aplican con `npx prisma migrate deploy`, que no borra datos) |
| `prisma/seed.ts` | Datos de demostración usados por `npm run db:seed` |
| `database/seed.sql` | Los mismos datos de demostración en SQL |
| `database/platanitos.sql` | Script completo generado: tablas, registro `_prisma_migrations` y datos |

Para cambiar el modelo durante el desarrollo:

```powershell
npx prisma migrate dev --name descripcion_del_cambio
npm run db:sql
```

Si agregas datos de demostración, actualiza `prisma/seed.ts` y `database/seed.sql`.

## Configuración en producción

La API no contiene URLs de producción en el código; todo se define con variables de entorno:

```env
NODE_ENV=production
HOST=0.0.0.0
CORS_ORIGINS=https://app.ejemplo.com
CORS_ALLOW_LOCALHOST=false
```

En producción usa un usuario de PostgreSQL propio para la aplicación (no el
superusuario `postgres`) y un `JWT_ACCESS_SECRET` distinto al de desarrollo.
La app Flutter recibe la URL del backend al compilar:

```powershell
flutter build web --dart-define=API_BASE_URL=https://api.ejemplo.com
```

Más detalles de la arquitectura en [`ARCHITECTURE.md`](ARCHITECTURE.md).
