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
| `npm run db:catalog` | Carga o actualiza el catálogo ampliado de 500 productos (idempotente, en una transacción) |
| `npm run db:catalog:sql` | Genera `database/catalog.sql`, el mismo catálogo en SQL para pgAdmin o `psql` |
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
| `database/catalog/platanitos-catalog.mjs` | Modelo del catálogo ampliado: plantillas por tipo de producto con categoría, marcas, modelos, rango de precio, tallas, colores e imágenes |
| `database/catalog/generate-catalog.mjs` | Generador determinista (semilla fija) y constructor del SQL idempotente |
| `database/catalog.sql` | Catálogo ampliado generado; se ejecuta después de `platanitos.sql` |

El catálogo ampliado se modeló con información pública de platanitos.com
(sitemaps de categorías, marcas y productos, y precios de las fichas): no copia
fichas reales, sino que combina tipo, público, modelo y color con el estilo de
nombre de la tienda. Sus variantes usan el prefijo de SKU `PLT-` (el seed
original usa `PLAT-`); al recargarlo se desactivan las variantes `PLT-` que el
modelo ya no genere. Tallas: calzado `EUR`, ropa `ALPHA` y accesorios/hogar
`ONE_SIZE` ("Única").

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
