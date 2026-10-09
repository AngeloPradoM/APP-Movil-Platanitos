// Genera el catálogo ampliado a partir de las plantillas de platanitos-catalog.mjs
// y lo convierte en sentencias SQL idempotentes. La salida es determinista: la
// misma semilla produce siempre los mismos productos, slugs y SKU, por eso
// volver a cargarlo actualiza filas en lugar de duplicarlas.
import {
  BRANDS,
  CATALOG_SIZE,
  FEATURES,
  GENDER_DEPARTMENT,
  IMAGES,
  MODEL_WORDS,
  SEED,
  TEMPLATES,
  imageUrl,
} from './platanitos-catalog.mjs';

// Prefijo de SKU exclusivo del catálogo ampliado (el seed original usa "PLAT-").
export const SKU_PREFIX = 'PLT-';

// Mismas reglas que usa la app Flutter para las secciones del inicio.
const BAG_WORDS = ['cartera', 'bolso', 'mochila'];
const ACCESSORY_WORDS = ['accesorio', 'reloj', 'correa', 'billetera'];
// La app solo muestra como comprables las tallas EUR 35-40.
const APP_EUR_SIZES = ['35', '36', '37', '38', '39', '40'];
// Primera página de la app (20 productos): 12 de calzado, 4 bolsos y 4 accesorios.
const SHOWCASE = 'SSBSASSBSASSBSASSBSA';

// Tramo del rango de precio que ocupa cada nivel de marca (0 = mínimo, 1 = máximo).
const TIER_SPAN = { 1: [0, 0.25], 2: [0.2, 0.55], 3: [0.45, 0.95] };

function mulberry32(seed) {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function slugify(text) {
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

const range = (from, to) => Array.from({ length: to - from + 1 }, (_, i) => String(from + i));
const toNinety = (value) => Number((Math.max(Math.round(value), 1) - 0.1).toFixed(2));
const truncate = (text, max) => (text.length <= max ? text : text.slice(0, max - 1).trimEnd() + '…');

// Reparte CATALOG_SIZE productos según el peso de cada plantilla (mayor residuo).
function allocate(templates, total) {
  const weightSum = templates.reduce((sum, t) => sum + t.weight, 0);
  const shares = templates.map((t, index) => {
    const exact = (t.weight * total) / weightSum;
    return { index, count: Math.floor(exact), remainder: exact - Math.floor(exact) };
  });
  let missing = total - shares.reduce((sum, s) => sum + s.count, 0);
  for (const share of [...shares].sort((a, b) => b.remainder - a.remainder || a.index - b.index)) {
    if (missing === 0) break;
    share.count += 1;
    missing -= 1;
  }
  return shares.map((s) => s.count);
}

function validateModel() {
  for (const t of TEMPLATES) {
    for (const brand of t.brands) {
      if (!BRANDS[brand]) throw new Error(`La plantilla "${t.key}" usa la marca "${brand}", que no está en BRANDS.`);
    }
    for (const brand of Object.keys(t.models ?? {})) {
      if (!t.brands.includes(brand)) throw new Error(`La plantilla "${t.key}" define modelos para "${brand}" pero no la incluye en brands.`);
    }
    for (const key of t.images) {
      if (!IMAGES[key]) throw new Error(`La plantilla "${t.key}" usa la imagen "${key}", que no está en IMAGES.`);
    }
    if (!FEATURES[t.family]) throw new Error(`La plantilla "${t.key}" usa la familia "${t.family}", sin características definidas.`);
  }
}

export function generateCatalog({ size = CATALOG_SIZE, seed = SEED } = {}) {
  validateModel();
  const rng = mulberry32(seed);
  const int = (max) => Math.floor(rng() * max);
  const pick = (list) => list[int(list.length)];
  const shuffle = (list) => {
    const copy = [...list];
    for (let i = copy.length - 1; i > 0; i -= 1) {
      const j = int(i + 1);
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  };

  const expand = (pattern, prefix) =>
    pattern
      .replaceAll('{p}', prefix ?? '')
      .replaceAll('{w}', () => pick(MODEL_WORDS))
      .replace(/[#%@]/g, (char) => {
        if (char === '#') return String(int(10));
        if (char === '%') return String(1 + int(9));
        return String.fromCharCode(65 + int(26));
      })
      .replace(/\s+/g, ' ')
      .trim();

  function sizesFor(scheme, gender) {
    if (scheme === 'one') return { system: 'ONE_SIZE', values: ['Única'] };
    if (scheme === 'baby') return { system: 'ALPHA', values: ['0-3M', '3-6M', '6-12M', '12-18M'] };
    if (scheme === 'apparel') {
      if (gender === 'Niño' || gender === 'Niña') return { system: 'ALPHA', values: ['4', '6', '8', '10', '12'] };
      if (gender === 'Juvenil') return { system: 'ALPHA', values: ['10', '12', '14', '16'] };
      if (gender === 'Mujer') return { system: 'ALPHA', values: ['XS', 'S', 'M', 'L', 'XL'] };
      if (gender === 'Hombre') return { system: 'ALPHA', values: ['S', 'M', 'L', 'XL', 'XXL'] };
      return { system: 'ALPHA', values: ['S', 'M', 'L', 'XL'] };
    }
    if (gender === 'Mujer') return { system: 'EUR', values: range(35, 40) };
    if (gender === 'Hombre') return { system: 'EUR', values: range(pick([38, 39]), pick([43, 44])) };
    if (gender === 'Niño' || gender === 'Niña') return { system: 'EUR', values: range(27, 34) };
    if (gender === 'Juvenil') return { system: 'EUR', values: range(33, 39) };
    return { system: 'EUR', values: range(36, 43) };
  }

  const stockFor = () => {
    const roll = rng();
    if (roll < 0.07) return 0;
    if (roll < 0.2) return 1 + int(3);
    return 4 + int(22);
  };

  const counts = allocate(TEMPLATES, size);
  const products = [];
  const usedSlugs = new Set();
  const usedKeys = new Set();

  TEMPLATES.forEach((t, templateIndex) => {
    const brandOrder = shuffle(t.brands);
    for (let i = 0; i < counts[templateIndex]; i += 1) {
      const brand = brandOrder[i % brandOrder.length];
      const lines = t.models?.[brand] ?? BRANDS[brand].models ?? ['{w}'];

      let gender, type, model, color, name;
      for (let attempt = 0; attempt < 8; attempt += 1) {
        gender = t.genders.length > 0 ? pick(t.genders) : null;
        type = pick(t.types);
        model = expand(pick(lines), t.prefix);
        color = pick(t.colors);
        const genderLabel = gender === 'Mujer' && BRANDS[brand].dama ? 'Dama' : gender;
        name = truncate([type, t.genderInName === false ? '' : genderLabel, model].filter(Boolean).join(' '), 160);
        if (!usedKeys.has(`${brand}|${name}|${color}`)) break;
      }
      usedKeys.add(`${brand}|${name}|${color}`);

      const baseSlug = slugify(`${brand} ${name} ${color}`).slice(0, 170).replace(/-+$/, '');
      let slug = baseSlug;
      for (let n = 2; usedSlugs.has(slug); n += 1) slug = `${baseSlug}-${n}`;
      usedSlugs.add(slug);

      const brandRange = t.brandPrice?.[brand];
      const [low, high] = brandRange ? [0, 1] : TIER_SPAN[BRANDS[brand].tier];
      const [minPrice, maxPrice] = brandRange ?? t.price;
      const price = toNinety(minPrice + (maxPrice - minPrice) * (low + rng() * (high - low)));
      let comparePrice = null;
      if (rng() < 0.4) {
        const discount = 0.15 + rng() * 0.35;
        comparePrice = toNinety(price / (1 - discount));
        if (comparePrice <= price) comparePrice = toNinety(price + 10);
      }

      const number = products.length + 1;
      const { system, values } = sizesFor(t.sizes, gender);
      const variants = values.map((value) => ({
        sku: `${SKU_PREFIX}${String(number).padStart(4, '0')}-${value === 'Única' ? 'U' : value.replace(/[^A-Za-z0-9]/g, '').toUpperCase()}`,
        sizeSystem: system,
        sizeValue: value,
        color,
        price,
        comparePrice,
        stock: stockFor(),
      }));

      const start = int(t.images.length);
      const imageCount = t.images.length > 1 && rng() < 0.5 ? 2 : 1;
      const images = Array.from({ length: imageCount }, (_, sortOrder) => ({
        url: imageUrl(t.images[(start + sortOrder) % t.images.length]),
        altText: truncate(sortOrder === 0 ? `${name} - ${color}` : `${name} - vista ${sortOrder + 1}`, 160),
        sortOrder,
      }));

      const [first, second] = shuffle(FEATURES[t.family]);
      const description = `${name} de ${brand}, ${t.about}. ${first} ${second} Color: ${color}.`;

      products.push({
        number,
        template: t.key,
        family: t.family,
        department: t.department ?? GENDER_DEPARTMENT[gender],
        category: { name: t.category, slug: slugify(t.category) },
        brand: { name: brand, slug: slugify(brand) },
        name,
        slug,
        description,
        color,
        price,
        comparePrice,
        variants,
        images,
      });
    }
  });

  // Orden de publicación (createdAt descendente): primero una "vitrina" variada
  // para la primera página de la app y luego el resto mezclado.
  const categoryHas = (product, words) => words.some((word) => product.category.name.toLowerCase().includes(word));
  const kinds = {
    S: (p) =>
      p.family === 'calzado' &&
      p.variants.filter((v) => v.sizeSystem === 'EUR' && APP_EUR_SIZES.includes(v.sizeValue) && v.stock > 0).length >= 3,
    B: (p) => categoryHas(p, BAG_WORDS),
    A: (p) => categoryHas(p, ACCESSORY_WORDS),
  };
  const pool = shuffle(products);
  const ordered = [];
  for (const kind of SHOWCASE) {
    const index = pool.findIndex(kinds[kind]);
    if (index >= 0) ordered.push(...pool.splice(index, 1));
  }
  ordered.push(...pool);
  ordered.forEach((product, position) => {
    product.minutesAgo = position;
  });

  const unique = (items) => [...new Map(items.map((item) => [item.slug, item])).values()].sort((a, b) => a.slug.localeCompare(b.slug));
  return {
    products: ordered,
    brands: unique(ordered.map((p) => p.brand)),
    categories: unique(ordered.map((p) => p.category)),
  };
}

// ------------------------------------------------------------------ SQL

const lit = (value) => {
  if (value === null || value === undefined) return 'NULL';
  if (typeof value === 'number') return value.toFixed(Number.isInteger(value) ? 0 : 2);
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  return `'${String(value).replace(/'/g, "''")}'`;
};
const rows = (items, toValues) => items.map((item) => `  (${toValues(item).map(lit).join(', ')})`).join(',\n');

// Comprueba que existan las tablas y los tallajes ALPHA/ONE_SIZE antes de insertar.
export const CATALOG_GUARD_SQL = `DO $$
BEGIN
  IF to_regclass('public."Product"') IS NULL THEN
    RAISE EXCEPTION 'Faltan las tablas de Platanitos. Ejecuta primero database/platanitos.sql o "npm run db:setup".';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'SizeSystem' AND e.enumlabel IN ('ALPHA', 'ONE_SIZE')
    HAVING count(*) = 2
  ) THEN
    RAISE EXCEPTION 'Falta la migración 20261009031301_size_system_alpha_one_size. Ejecuta "npx prisma migrate deploy" o recrea la base con database/platanitos.sql.';
  END IF;
END $$;`;

// Sentencias de carga (sin BEGIN/COMMIT). Usan now() de la transacción para
// identificar al final las filas del catálogo que ya no se generan.
export function buildCatalogSql(catalog) {
  const { products, brands, categories } = catalog;
  const images = products.flatMap((p) => p.images.map((image) => ({ slug: p.slug, ...image })));
  const variants = products.flatMap((p) => p.variants.map((variant) => ({ slug: p.slug, ...variant })));
  const catalogRow = `"sku" LIKE '${SKU_PREFIX}%'`;
  const onlyCatalog = (alias) => `EXISTS (SELECT 1 FROM "ProductVariant" cv WHERE cv."productId" = ${alias} AND cv.${catalogRow})
  AND NOT EXISTS (SELECT 1 FROM "ProductVariant" ov WHERE ov."productId" = ${alias} AND ov."sku" NOT LIKE '${SKU_PREFIX}%')`;

  return `-- Marcas (${brands.length})
INSERT INTO "Brand" ("id", "name", "slug", "isActive", "createdAt", "updatedAt")
SELECT gen_random_uuid(), v.name, v.slug, true, now(), now()
FROM (
VALUES
${rows(brands, (b) => [b.name, b.slug])}
) AS v(name, slug)
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name", "isActive" = true, "updatedAt" = now();

-- Categorías (${categories.length})
INSERT INTO "Category" ("id", "name", "slug", "isActive", "createdAt", "updatedAt")
SELECT gen_random_uuid(), v.name, v.slug, true, now(), now()
FROM (
VALUES
${rows(categories, (c) => [c.name, c.slug])}
) AS v(name, slug)
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name", "isActive" = true, "updatedAt" = now();

-- Productos (${products.length}). createdAt escalonado: el orden define la primera página de la app.
INSERT INTO "Product" ("id", "brandId", "categoryId", "name", "slug", "description", "isActive", "createdAt", "updatedAt")
SELECT gen_random_uuid(), b."id", c."id", v.name, v.slug, v.description, true,
       now() - make_interval(mins => v.minutes_ago), now()
FROM (
VALUES
${rows(products, (p) => [p.brand.slug, p.category.slug, p.name, p.slug, p.description, p.minutesAgo])}
) AS v(brand_slug, category_slug, name, slug, description, minutes_ago)
JOIN "Brand" b ON b."slug" = v.brand_slug
JOIN "Category" c ON c."slug" = v.category_slug
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name",
      "description" = EXCLUDED."description",
      "brandId" = EXCLUDED."brandId",
      "categoryId" = EXCLUDED."categoryId",
      "isActive" = true,
      "createdAt" = EXCLUDED."createdAt",
      "updatedAt" = now();

-- Imágenes (${images.length})
INSERT INTO "ProductImage" ("id", "productId", "url", "altText", "sortOrder", "createdAt")
SELECT gen_random_uuid(), p."id", v.url, v.alt_text, v.sort_order, now()
FROM (
VALUES
${rows(images, (i) => [i.slug, i.url, i.altText, i.sortOrder])}
) AS v(slug, url, alt_text, sort_order)
JOIN "Product" p ON p."slug" = v.slug
ON CONFLICT ("productId", "sortOrder") DO UPDATE
  SET "url" = EXCLUDED."url", "altText" = EXCLUDED."altText", "createdAt" = now();

-- Variantes (${variants.length}): talla, color, precio, precio anterior y stock
INSERT INTO "ProductVariant" ("id", "productId", "sku", "sizeSystem", "sizeValue", "color", "price", "comparePrice", "stock", "isActive", "createdAt", "updatedAt")
SELECT gen_random_uuid(), p."id", v.sku, v.size_system::"SizeSystem", v.size_value, v.color,
       v.price::numeric, v.compare_price::numeric, v.stock, true, now(), now()
FROM (
VALUES
${rows(variants, (v) => [v.slug, v.sku, v.sizeSystem, v.sizeValue, v.color, v.price, v.comparePrice, v.stock])}
) AS v(slug, sku, size_system, size_value, color, price, compare_price, stock)
JOIN "Product" p ON p."slug" = v.slug
ON CONFLICT ("sku") DO UPDATE
  SET "productId" = EXCLUDED."productId",
      "sizeSystem" = EXCLUDED."sizeSystem",
      "sizeValue" = EXCLUDED."sizeValue",
      "color" = EXCLUDED."color",
      "price" = EXCLUDED."price",
      "comparePrice" = EXCLUDED."comparePrice",
      "stock" = EXCLUDED."stock",
      "isActive" = true,
      "updatedAt" = now();

-- Limpieza: desactiva variantes y productos del catálogo (SKU ${SKU_PREFIX}…) que ya no
-- se generan y borra sus imágenes sobrantes. No toca los datos del seed original.
UPDATE "ProductVariant" SET "isActive" = false, "updatedAt" = now()
WHERE ${catalogRow} AND "isActive" AND "updatedAt" <> now()::timestamp(3);

UPDATE "Product" p SET "isActive" = false, "updatedAt" = now()
WHERE p."isActive" AND p."updatedAt" <> now()::timestamp(3)
  AND ${onlyCatalog('p."id"')};

DELETE FROM "ProductImage" i
WHERE i."createdAt" <> now()::timestamp(3)
  AND ${onlyCatalog('i."productId"')};
`;
}

export function buildCatalogSqlFile(catalog) {
  return `-- =====================================================================
-- Platanitos · Catálogo ampliado de ${catalog.products.length} productos (PostgreSQL 14 o superior)
-- =====================================================================
-- Archivo GENERADO con \`npm run db:catalog:sql\`. No lo edites a mano:
-- modifica database/catalog/platanitos-catalog.mjs y regenéralo.
--
-- Productos modelados a partir de información pública de platanitos.com
-- (departamentos, marcas, tipos de producto y rangos de precio). Imágenes
-- de Unsplash.
--
-- Cómo usarlo (DESPUÉS de database/platanitos.sql o de "npm run db:setup"):
--   - pgAdmin: clic derecho en la base "platanitos" > Query Tool >
--     abrir este archivo > Execute (F5).
--   - psql:  psql -U postgres -d platanitos -v ON_ERROR_STOP=1 -f database/catalog.sql
--
-- Es idempotente: puede ejecutarse varias veces sin duplicar registros y no
-- borra los productos de demostración originales. Corre en una transacción:
-- si algo falla, no se aplica ningún cambio.
-- =====================================================================

SET client_encoding = 'UTF8';

${CATALOG_GUARD_SQL}

BEGIN;

${buildCatalogSql(catalog).trim()}

COMMIT;
`;
}
