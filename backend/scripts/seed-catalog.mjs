// Carga el catálogo ampliado de 500 productos de Platanitos.
//   npm run db:catalog       → inserta/actualiza en la base de DATABASE_URL
//   npm run db:catalog:sql   → genera database/catalog.sql para pgAdmin o psql
// Es idempotente y no borra los productos del seed original.
// Nunca imprime DATABASE_URL ni la contraseña.
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import {
  CATALOG_GUARD_SQL,
  SKU_PREFIX,
  buildCatalogSql,
  buildCatalogSqlFile,
  generateCatalog,
} from '../database/catalog/generate-catalog.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sqlMode = process.argv.includes('--sql');
const totalSteps = sqlMode ? 2 : 4;

function fail(message) {
  console.error(`\n✖ ${message}\n`);
  process.exit(1);
}

function step(number, title) {
  console.log(`\n▶ Paso ${number}/${totalSteps}: ${title}…`);
}

function printTable(title, entries) {
  console.log(`\n  ${title}`);
  const width = Math.max(...entries.map(([label]) => label.length));
  for (const [label, count] of entries) console.log(`    ${label.padEnd(width)}  ${String(count).padStart(4)}`);
}

function countBy(items, key) {
  const counts = new Map();
  for (const item of items) counts.set(key(item), (counts.get(key(item)) ?? 0) + 1);
  return [...counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
}

function explain(error) {
  switch (error?.code) {
    case '28P01':
      return 'Usuario o contraseña de PostgreSQL incorrectos. Revisa DATABASE_URL en backend/.env.';
    case 'ECONNREFUSED':
      return 'No se pudo conectar a PostgreSQL. Verifica que el servicio esté iniciado y que el host y puerto de DATABASE_URL sean correctos.';
    case 'ENOTFOUND':
      return 'No se encontró el host indicado en DATABASE_URL.';
    case '3D000':
      return 'La base de datos de DATABASE_URL no existe. Créala con "npm run db:setup" y vuelve a ejecutar este comando.';
    case '42P01':
      return 'Faltan tablas de Platanitos. Ejecuta "npm run db:setup" y vuelve a intentarlo.';
    case '22P02':
      return 'La base no reconoce los tallajes ALPHA/ONE_SIZE. Ejecuta "npx prisma migrate deploy" y vuelve a intentarlo.';
    case '23505':
      return `Ya existe un registro con el mismo valor único (${error.constraint ?? 'restricción desconocida'}). No se aplicó ningún cambio.`;
    case 'P0001':
      return error.message;
    default:
      return `No se pudo cargar el catálogo (${error?.code ?? 'error desconocido'}). No se aplicó ningún cambio.`;
  }
}

step(1, 'generando el catálogo a partir del modelo de platanitos.com');
let catalog;
try {
  catalog = generateCatalog();
} catch (error) {
  fail(`El modelo del catálogo tiene un error: ${error.message}`);
}
const variantCount = catalog.products.reduce((sum, p) => sum + p.variants.length, 0);
const imageCount = catalog.products.reduce((sum, p) => sum + p.images.length, 0);
console.log(
  `  ${catalog.products.length} productos, ${variantCount} variantes, ${imageCount} imágenes, ` +
    `${catalog.brands.length} marcas y ${catalog.categories.length} categorías.`,
);

if (sqlMode) {
  step(2, 'escribiendo database/catalog.sql');
  writeFileSync(join(root, 'database', 'catalog.sql'), buildCatalogSqlFile(catalog), 'utf8');
  printTable('Productos por categoría', countBy(catalog.products, (p) => p.category.name));
  printTable('Productos por departamento', countBy(catalog.products, (p) => p.department));
  console.log('\n✔ Script generado en database/catalog.sql. Ejecútalo después de database/platanitos.sql.\n');
  process.exit(0);
}

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  fail('Falta DATABASE_URL. Copia .env.example como .env dentro de backend/ y complétalo (ver README, paso 5).');
}
try {
  new URL(databaseUrl);
} catch {
  fail('DATABASE_URL no tiene un formato válido. Debe verse así: postgresql://USUARIO:CONTRASENA@127.0.0.1:5432/platanitos');
}

const client = new pg.Client({ connectionString: databaseUrl });
const countCatalogProducts = async () => {
  const { rows } = await client.query(
    `SELECT count(DISTINCT v."productId")::int AS total
     FROM "ProductVariant" v JOIN "Product" p ON p."id" = v."productId"
     WHERE v."sku" LIKE $1 AND p."isActive"`,
    [`${SKU_PREFIX}%`],
  );
  return rows[0].total;
};

try {
  step(2, 'conectando a PostgreSQL y verificando migraciones');
  await client.connect();
  await client.query(CATALOG_GUARD_SQL);
  const before = await countCatalogProducts();
  console.log(`  Conexión correcta. Productos del catálogo ampliado ya cargados: ${before}.`);

  step(3, 'insertando o actualizando productos en una sola transacción');
  await client.query('BEGIN');
  try {
    await client.query(buildCatalogSql(catalog));
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    throw error;
  }
  const after = await countCatalogProducts();
  console.log(`  Productos nuevos: ${Math.max(after - before, 0)} · actualizados: ${Math.min(before, after)}.`);

  step(4, 'verificando lo cargado');
  const { rows: byCategory } = await client.query(
    `SELECT c."name", count(DISTINCT p."id")::int AS total
     FROM "Product" p
     JOIN "Category" c ON c."id" = p."categoryId"
     JOIN "ProductVariant" v ON v."productId" = p."id" AND v."sku" LIKE $1
     WHERE p."isActive"
     GROUP BY c."name"
     ORDER BY total DESC, c."name"`,
    [`${SKU_PREFIX}%`],
  );
  const { rows: totals } = await client.query(
    `SELECT
       (SELECT count(*)::int FROM "Product" WHERE "isActive") AS products,
       (SELECT count(*)::int FROM "ProductVariant" WHERE "sku" LIKE $1 AND "isActive") AS variants,
       (SELECT count(*)::int FROM "ProductImage" i
          WHERE EXISTS (SELECT 1 FROM "ProductVariant" v WHERE v."productId" = i."productId" AND v."sku" LIKE $1)) AS images`,
    [`${SKU_PREFIX}%`],
  );
  printTable('Productos por categoría (en la base)', byCategory.map((row) => [row.name, row.total]));
  printTable('Productos por departamento', countBy(catalog.products, (p) => p.department));
  console.log(
    `\n  Catálogo ampliado: ${after} productos, ${totals[0].variants} variantes y ${totals[0].images} imágenes.` +
      `\n  Productos activos en toda la base (incluye el seed original): ${totals[0].products}.`,
  );
  console.log('\n✔ Catálogo cargado. Revisa http://localhost:3000/catalog/products con el backend encendido.\n');
} catch (error) {
  fail(explain(error));
} finally {
  await client.end().catch(() => {});
}
