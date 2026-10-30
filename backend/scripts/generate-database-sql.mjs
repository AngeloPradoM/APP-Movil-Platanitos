// Genera database/platanitos.sql: todas las migraciones de Prisma, el registro
// en _prisma_migrations y los datos de demostración de database/seed.sql.
// Ejecutar con `npm run db:sql` cada vez que se agregue una migración.
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const migrationsDir = join(root, 'prisma', 'migrations');
const output = join(root, 'database', 'platanitos.sql');

const migrations = readdirSync(migrationsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort()
  .map((name) => {
    const sql = readFileSync(join(migrationsDir, name, 'migration.sql'), 'utf8');
    // Prisma guarda el SHA-256 del archivo de migración para detectar cambios.
    const checksum = createHash('sha256').update(sql).digest('hex');
    return { name, sql, checksum };
  });

const seed = readFileSync(join(root, 'database', 'seed.sql'), 'utf8');

const script = `-- =====================================================================
-- Platanitos · Script completo de base de datos (PostgreSQL 14 o superior)
-- =====================================================================
-- Archivo GENERADO con \`npm run db:sql\`. No lo edites a mano: modifica
-- prisma/schema.prisma (nueva migración) o database/seed.sql y regenéralo.
--
-- Qué hace:
--   1. Crea todos los tipos, tablas, índices y llaves foráneas.
--   2. Registra las migraciones en "_prisma_migrations" para que
--      \`npx prisma migrate deploy\` las reconozca como ya aplicadas.
--   3. Inserta los datos de demostración (productos, tiendas y blog).
--
-- Cómo usarlo:
--   - Ejecútalo sobre una base de datos VACÍA llamada "platanitos".
--   - pgAdmin: clic derecho en la base "platanitos" > Query Tool >
--     abrir este archivo > Execute (F5).
--   - psql:  psql -U postgres -d platanitos -v ON_ERROR_STOP=1 -f database/platanitos.sql
--
-- Si la base ya tiene las tablas, el script se detiene sin modificar nada.
-- Todo lo demás corre dentro de una transacción: si algo falla, no se
-- aplica ningún cambio.
-- =====================================================================

SET client_encoding = 'UTF8';

DO $$
BEGIN
  IF to_regclass('public."_prisma_migrations"') IS NOT NULL OR to_regclass('public."User"') IS NOT NULL THEN
    RAISE EXCEPTION 'La base de datos ya tiene las tablas de Platanitos. Ejecuta este script sobre una base vacía o usa "npm run db:setup".';
  END IF;
END $$;

BEGIN;

CREATE TABLE "_prisma_migrations" (
    "id" VARCHAR(36) PRIMARY KEY NOT NULL,
    "checksum" VARCHAR(64) NOT NULL,
    "finished_at" TIMESTAMPTZ,
    "migration_name" VARCHAR(255) NOT NULL,
    "logs" TEXT,
    "rolled_back_at" TIMESTAMPTZ,
    "started_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "applied_steps_count" INTEGER NOT NULL DEFAULT 0
);

${migrations
  .map(
    ({ name, sql, checksum }) => `-- ---------------------------------------------------------------------
-- Migración ${name}
-- ---------------------------------------------------------------------
${sql.trim()}

INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "started_at", "applied_steps_count")
VALUES (gen_random_uuid()::text, '${checksum}', now(), '${name}', now(), 1);
`,
  )
  .join('\n')}
-- ---------------------------------------------------------------------
-- Datos de demostración
-- ---------------------------------------------------------------------
${seed.trim()}

COMMIT;
`;

writeFileSync(output, script.replace(/\r\n/g, '\n'), 'utf8');
console.log(`Script generado en database/platanitos.sql (${migrations.length} migraciones).`);
