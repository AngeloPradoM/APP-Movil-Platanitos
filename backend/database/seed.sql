-- Datos de demostración de Platanitos (equivalentes a prisma/seed.ts).
-- Es idempotente: puede ejecutarse varias veces sin duplicar registros.
-- Requiere que las tablas ya existan (migraciones aplicadas).

-- Marcas
INSERT INTO "Brand" ("id", "name", "slug", "isActive", "createdAt", "updatedAt")
VALUES
  (gen_random_uuid(), 'Nike', 'nike', true, now(), now()),
  (gen_random_uuid(), 'Adidas', 'adidas', true, now(), now())
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name", "isActive" = true, "updatedAt" = now();

-- Categorías
INSERT INTO "Category" ("id", "name", "slug", "isActive", "createdAt", "updatedAt")
VALUES
  (gen_random_uuid(), 'Zapatillas', 'zapatillas', true, now(), now())
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name", "isActive" = true, "updatedAt" = now();

-- Productos
INSERT INTO "Product" ("id", "brandId", "categoryId", "name", "slug", "description", "isActive", "createdAt", "updatedAt")
SELECT gen_random_uuid(), b."id", c."id", v.name, v.slug, v.description, true, now(), now()
FROM (
  VALUES
    ('nike', 'zapatillas', 'Nike Air Max 270', 'nike-air-max-270',
     'Zapatilla urbana con amortiguación Air para uso diario.'),
    ('adidas', 'zapatillas', 'Adidas Grand Court Base', 'adidas-grand-court-base',
     'Diseño clásico y versátil para combinar con cualquier estilo.')
) AS v(brand_slug, category_slug, name, slug, description)
JOIN "Brand" b ON b."slug" = v.brand_slug
JOIN "Category" c ON c."slug" = v.category_slug
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name",
      "description" = EXCLUDED."description",
      "brandId" = EXCLUDED."brandId",
      "categoryId" = EXCLUDED."categoryId",
      "isActive" = true,
      "updatedAt" = now();

-- Imagen principal de cada producto
INSERT INTO "ProductImage" ("id", "productId", "url", "altText", "sortOrder", "createdAt")
SELECT gen_random_uuid(), p."id", v.url, p."name", 0, now()
FROM (
  VALUES
    ('nike-air-max-270', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff'),
    ('adidas-grand-court-base', 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77')
) AS v(slug, url)
JOIN "Product" p ON p."slug" = v.slug
ON CONFLICT ("productId", "sortOrder") DO UPDATE
  SET "url" = EXCLUDED."url", "altText" = EXCLUDED."altText";

-- Variantes (talla EUR, color, precio y stock)
INSERT INTO "ProductVariant" ("id", "productId", "sku", "sizeSystem", "sizeValue", "color", "price", "stock", "isActive", "createdAt", "updatedAt")
SELECT gen_random_uuid(), p."id", v.sku, 'EUR'::"SizeSystem", v.size_value, v.color, v.price, v.stock, true, now(), now()
FROM (
  VALUES
    ('nike-air-max-270', 'PLAT-NIKE-AM270-40-NEGRO', '40', 'Negro', 499.90::numeric, 8),
    ('nike-air-max-270', 'PLAT-NIKE-AM270-41-NEGRO', '41', 'Negro', 499.90::numeric, 6),
    ('adidas-grand-court-base', 'PLAT-ADI-GRAND-39-BLANCO', '39', 'Blanco', 249.90::numeric, 12),
    ('adidas-grand-court-base', 'PLAT-ADI-GRAND-40-BLANCO', '40', 'Blanco', 249.90::numeric, 10)
) AS v(slug, sku, size_value, color, price, stock)
JOIN "Product" p ON p."slug" = v.slug
ON CONFLICT ("sku") DO UPDATE
  SET "productId" = EXCLUDED."productId",
      "sizeSystem" = EXCLUDED."sizeSystem",
      "sizeValue" = EXCLUDED."sizeValue",
      "color" = EXCLUDED."color",
      "price" = EXCLUDED."price",
      "stock" = EXCLUDED."stock",
      "isActive" = true,
      "updatedAt" = now();

-- Tiendas (pantalla Ubícanos)
INSERT INTO "Store" ("id", "slug", "name", "district", "address", "hours", "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES
  (gen_random_uuid(), 'jockey-plaza', 'Platanitos Jockey Plaza', 'Santiago de Surco',
   'Av. Javier Prado Este 4200, tienda 1-12', 'Lun a Dom · 10:00 a 22:00', 0, true, now(), now()),
  (gen_random_uuid(), 'mega-plaza', 'Platanitos Mega Plaza', 'Independencia',
   'Av. Alfredo Mendiola 3698, tienda 214', 'Lun a Dom · 10:00 a 22:00', 1, true, now(), now()),
  (gen_random_uuid(), 'plaza-san-miguel', 'Platanitos Plaza San Miguel', 'San Miguel',
   'Av. La Marina 2000, tienda A-35', 'Lun a Dom · 10:00 a 22:00', 2, true, now(), now()),
  (gen_random_uuid(), 'real-plaza-salaverry', 'Platanitos Real Plaza Salaverry', 'Jesús María',
   'Av. Gral. Felipe Salaverry 2370, tienda 108', 'Lun a Dom · 10:00 a 22:00', 3, true, now(), now())
ON CONFLICT ("slug") DO UPDATE
  SET "name" = EXCLUDED."name",
      "district" = EXCLUDED."district",
      "address" = EXCLUDED."address",
      "hours" = EXCLUDED."hours",
      "sortOrder" = EXCLUDED."sortOrder",
      "isActive" = true,
      "updatedAt" = now();

-- Artículos del blog
INSERT INTO "BlogPost" ("id", "slug", "title", "category", "summary", "body", "imageUrl", "readMinutes", "isPublished", "publishedAt", "createdAt", "updatedAt")
VALUES
  (gen_random_uuid(), 'elegir-talla-perfecta',
   'Cómo elegir la talla perfecta sin probarte el calzado', 'Guías',
   'Mide tu pie en casa y compara con nuestra tabla EUR, US y CM.',
   'Coloca una hoja en el piso, apoya el talón contra la pared y marca la punta del dedo más largo. Mide la distancia en centímetros y busca ese valor en la tabla CM de la ficha del producto. Si estás entre dos tallas, elige la mayor para zapatillas y la menor para sandalias con correas ajustables.',
   'https://images.unsplash.com/photo-1560769629-975ec94e6a86?fit=crop&q=85&w=800', 3, true, now(), now(), now()),
  (gen_random_uuid(), 'tendencias-plataformas-tonos-tierra',
   'Tendencias de temporada: plataformas y tonos tierra', 'Tendencias',
   'Las suelas altas y los colores camel dominan esta temporada.',
   'Las plataformas siguen siendo protagonistas por su comodidad y estilo. Combínalas con prendas en tonos tierra, beige y verde oliva. Para la noche, los tacos cuadrados ofrecen estabilidad sin perder elegancia.',
   'https://images.unsplash.com/photo-1591884807537-0bce39888fe0?fit=crop&q=85&w=800', 4, true, now(), now(), now()),
  (gen_random_uuid(), 'cuidar-botines-cuero-lluvia',
   'Cuida tus botines de cuero en temporada de lluvia', 'Cuidado',
   'Tres pasos sencillos para que tu calzado dure más.',
   'Limpia el barro con un paño húmedo apenas llegues a casa. Deja secar a temperatura ambiente, nunca cerca de una fuente de calor. Aplica una crema hidratante incolora una vez por semana y usa un spray impermeabilizante antes de salir.',
   'https://images.unsplash.com/photo-1605732440685-d0654d81aa30?fit=crop&q=85&w=800', 2, true, now(), now(), now())
ON CONFLICT ("slug") DO UPDATE
  SET "title" = EXCLUDED."title",
      "category" = EXCLUDED."category",
      "summary" = EXCLUDED."summary",
      "body" = EXCLUDED."body",
      "imageUrl" = EXCLUDED."imageUrl",
      "readMinutes" = EXCLUDED."readMinutes",
      "updatedAt" = now();
