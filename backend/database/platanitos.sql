-- =====================================================================
-- Platanitos · Script completo de base de datos (PostgreSQL 14 o superior)
-- =====================================================================
-- Archivo GENERADO con `npm run db:sql`. No lo edites a mano: modifica
-- prisma/schema.prisma (nueva migración) o database/seed.sql y regenéralo.
--
-- Qué hace:
--   1. Crea todos los tipos, tablas, índices y llaves foráneas.
--   2. Registra las migraciones en "_prisma_migrations" para que
--      `npx prisma migrate deploy` las reconozca como ya aplicadas.
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

-- ---------------------------------------------------------------------
-- Migración 20261008201120_initial_auth
-- ---------------------------------------------------------------------
-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "email" VARCHAR(254) NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "documentType" VARCHAR(20),
    "documentNumber" VARCHAR(32),
    "phone" VARCHAR(20),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PasswordCredential" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "passwordHash" VARCHAR(255) NOT NULL,
    "passwordUpdatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PasswordCredential_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshSession" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "tokenHash" VARCHAR(128) NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "lastUsedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ipAddress" VARCHAR(45),
    "userAgent" VARCHAR(512),

    CONSTRAINT "RefreshSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditEvent" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "eventType" VARCHAR(64) NOT NULL,
    "ipAddress" VARCHAR(45),
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_isActive_idx" ON "User"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "PasswordCredential_userId_key" ON "PasswordCredential"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshSession_tokenHash_key" ON "RefreshSession"("tokenHash");

-- CreateIndex
CREATE INDEX "RefreshSession_userId_revokedAt_idx" ON "RefreshSession"("userId", "revokedAt");

-- CreateIndex
CREATE INDEX "RefreshSession_expiresAt_idx" ON "RefreshSession"("expiresAt");

-- CreateIndex
CREATE INDEX "AuditEvent_userId_createdAt_idx" ON "AuditEvent"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditEvent_eventType_createdAt_idx" ON "AuditEvent"("eventType", "createdAt");

-- AddForeignKey
ALTER TABLE "PasswordCredential" ADD CONSTRAINT "PasswordCredential_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshSession" ADD CONSTRAINT "RefreshSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "started_at", "applied_steps_count")
VALUES (gen_random_uuid()::text, 'fc17baa074457762b696d0a1b0a9e766677dfed3e4d68e929c0e663808e91996', now(), '20261008201120_initial_auth', now(), 1);

-- ---------------------------------------------------------------------
-- Migración 20261008201601_complete_domain
-- ---------------------------------------------------------------------
-- CreateEnum
CREATE TYPE "SizeSystem" AS ENUM ('EUR', 'US', 'CM');

-- CreateEnum
CREATE TYPE "CartStatus" AS ENUM ('ACTIVE', 'CONVERTED', 'ABANDONED');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PREPARATION', 'DISPATCH', 'TRANSIT', 'DELIVERED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('WALLET', 'CARD', 'CASH');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "SupportTicketStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED');

-- DropIndex
DROP INDEX "User_isActive_idx";

-- CreateTable
CREATE TABLE "Category" (
    "id" UUID NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Brand" (
    "id" UUID NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Brand_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Product" (
    "id" UUID NOT NULL,
    "brandId" UUID NOT NULL,
    "categoryId" UUID NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "slug" VARCHAR(180) NOT NULL,
    "description" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProductVariant" (
    "id" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "sku" VARCHAR(64) NOT NULL,
    "sizeSystem" "SizeSystem" NOT NULL,
    "sizeValue" VARCHAR(16) NOT NULL,
    "color" VARCHAR(40) NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "comparePrice" DECIMAL(10,2),
    "stock" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProductVariant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProductImage" (
    "id" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "url" VARCHAR(2048) NOT NULL,
    "altText" VARCHAR(160),
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProductImage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Favorite" (
    "userId" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Favorite_pkey" PRIMARY KEY ("userId","productId")
);

-- CreateTable
CREATE TABLE "Address" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "label" VARCHAR(60) NOT NULL,
    "recipient" VARCHAR(120) NOT NULL,
    "line1" VARCHAR(180) NOT NULL,
    "district" VARCHAR(80) NOT NULL,
    "province" VARCHAR(80) NOT NULL,
    "department" VARCHAR(80) NOT NULL,
    "postalCode" VARCHAR(20),
    "country" CHAR(2) NOT NULL DEFAULT 'PE',
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Address_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Cart" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "status" "CartStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Cart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CartItem" (
    "id" UUID NOT NULL,
    "cartId" UUID NOT NULL,
    "variantId" UUID NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CartItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Order" (
    "id" UUID NOT NULL,
    "publicNumber" VARCHAR(32) NOT NULL,
    "userId" UUID NOT NULL,
    "addressId" UUID,
    "status" "OrderStatus" NOT NULL DEFAULT 'PREPARATION',
    "paymentMethod" "PaymentMethod" NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,
    "shipping" DECIMAL(10,2) NOT NULL,
    "total" DECIMAL(10,2) NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'PEN',
    "carrier" VARCHAR(100),
    "trackingCode" VARCHAR(100),
    "estimatedFrom" TIMESTAMP(3),
    "estimatedTo" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrderAddressSnapshot" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "recipient" VARCHAR(120) NOT NULL,
    "line1" VARCHAR(180) NOT NULL,
    "district" VARCHAR(80) NOT NULL,
    "province" VARCHAR(80) NOT NULL,
    "department" VARCHAR(80) NOT NULL,
    "postalCode" VARCHAR(20),
    "country" CHAR(2) NOT NULL,

    CONSTRAINT "OrderAddressSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrderItem" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "variantId" UUID,
    "productName" VARCHAR(160) NOT NULL,
    "sku" VARCHAR(64) NOT NULL,
    "sizeSystem" "SizeSystem" NOT NULL,
    "sizeValue" VARCHAR(16) NOT NULL,
    "color" VARCHAR(40) NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unitPrice" DECIMAL(10,2) NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "OrderItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrderStatusHistory" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "status" "OrderStatus" NOT NULL,
    "note" VARCHAR(255),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OrderStatusHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentAttempt" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "amount" DECIMAL(10,2) NOT NULL,
    "providerRef" VARCHAR(120),
    "failureCode" VARCHAR(80),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaymentAttempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SupportTicket" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "orderId" UUID,
    "subject" VARCHAR(160) NOT NULL,
    "message" TEXT NOT NULL,
    "status" "SupportTicketStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SupportTicket_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Category_slug_key" ON "Category"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Brand_name_key" ON "Brand"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Brand_slug_key" ON "Brand"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "Product_slug_key" ON "Product"("slug");

-- CreateIndex
CREATE INDEX "Product_brandId_idx" ON "Product"("brandId");

-- CreateIndex
CREATE INDEX "Product_categoryId_idx" ON "Product"("categoryId");

-- CreateIndex
CREATE INDEX "Product_isActive_idx" ON "Product"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_sku_key" ON "ProductVariant"("sku");

-- CreateIndex
CREATE INDEX "ProductVariant_productId_isActive_idx" ON "ProductVariant"("productId", "isActive");

-- CreateIndex
CREATE INDEX "ProductVariant_sizeSystem_sizeValue_idx" ON "ProductVariant"("sizeSystem", "sizeValue");

-- CreateIndex
CREATE UNIQUE INDEX "ProductVariant_productId_sizeSystem_sizeValue_color_key" ON "ProductVariant"("productId", "sizeSystem", "sizeValue", "color");

-- CreateIndex
CREATE UNIQUE INDEX "ProductImage_productId_sortOrder_key" ON "ProductImage"("productId", "sortOrder");

-- CreateIndex
CREATE INDEX "Favorite_productId_idx" ON "Favorite"("productId");

-- CreateIndex
CREATE INDEX "Address_userId_isDefault_idx" ON "Address"("userId", "isDefault");

-- CreateIndex
CREATE UNIQUE INDEX "Cart_userId_key" ON "Cart"("userId");

-- CreateIndex
CREATE INDEX "CartItem_variantId_idx" ON "CartItem"("variantId");

-- CreateIndex
CREATE UNIQUE INDEX "CartItem_cartId_variantId_key" ON "CartItem"("cartId", "variantId");

-- CreateIndex
CREATE UNIQUE INDEX "Order_publicNumber_key" ON "Order"("publicNumber");

-- CreateIndex
CREATE INDEX "Order_userId_createdAt_idx" ON "Order"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "Order_status_createdAt_idx" ON "Order"("status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "OrderAddressSnapshot_orderId_key" ON "OrderAddressSnapshot"("orderId");

-- CreateIndex
CREATE INDEX "OrderItem_orderId_idx" ON "OrderItem"("orderId");

-- CreateIndex
CREATE INDEX "OrderItem_variantId_idx" ON "OrderItem"("variantId");

-- CreateIndex
CREATE INDEX "OrderStatusHistory_orderId_createdAt_idx" ON "OrderStatusHistory"("orderId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentAttempt_providerRef_key" ON "PaymentAttempt"("providerRef");

-- CreateIndex
CREATE INDEX "PaymentAttempt_orderId_createdAt_idx" ON "PaymentAttempt"("orderId", "createdAt");

-- CreateIndex
CREATE INDEX "PaymentAttempt_status_idx" ON "PaymentAttempt"("status");

-- CreateIndex
CREATE INDEX "SupportTicket_userId_status_idx" ON "SupportTicket"("userId", "status");

-- CreateIndex
CREATE INDEX "SupportTicket_orderId_idx" ON "SupportTicket"("orderId");

-- AddForeignKey
ALTER TABLE "Product" ADD CONSTRAINT "Product_brandId_fkey" FOREIGN KEY ("brandId") REFERENCES "Brand"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Product" ADD CONSTRAINT "Product_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProductVariant" ADD CONSTRAINT "ProductVariant_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProductImage" ADD CONSTRAINT "ProductImage_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Favorite" ADD CONSTRAINT "Favorite_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Favorite" ADD CONSTRAINT "Favorite_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Address" ADD CONSTRAINT "Address_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Cart" ADD CONSTRAINT "Cart_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CartItem" ADD CONSTRAINT "CartItem_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "Cart"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CartItem" ADD CONSTRAINT "CartItem_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "ProductVariant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_addressId_fkey" FOREIGN KEY ("addressId") REFERENCES "Address"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrderAddressSnapshot" ADD CONSTRAINT "OrderAddressSnapshot_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrderItem" ADD CONSTRAINT "OrderItem_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrderItem" ADD CONSTRAINT "OrderItem_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "ProductVariant"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrderStatusHistory" ADD CONSTRAINT "OrderStatusHistory_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentAttempt" ADD CONSTRAINT "PaymentAttempt_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SupportTicket" ADD CONSTRAINT "SupportTicket_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SupportTicket" ADD CONSTRAINT "SupportTicket_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "started_at", "applied_steps_count")
VALUES (gen_random_uuid()::text, 'b669ca15744d485bfdc10f619e17528ad154c6a357c33e5890198d75afcc6682', now(), '20261008201601_complete_domain', now(), 1);

-- ---------------------------------------------------------------------
-- Migración 20261009010000_loyalty_giftcards_content
-- ---------------------------------------------------------------------
-- CreateEnum
CREATE TYPE "LoyaltyEntryType" AS ENUM ('RECYCLING_BONUS', 'REDEMPTION');

-- CreateTable
CREATE TABLE "LoyaltyEntry" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "type" "LoyaltyEntryType" NOT NULL,
    "points" INTEGER NOT NULL,
    "walletAmount" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "description" VARCHAR(160) NOT NULL,
    "reference" VARCHAR(32),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LoyaltyEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GiftCard" (
    "id" UUID NOT NULL,
    "purchaserId" UUID NOT NULL,
    "code" VARCHAR(24) NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "recipientName" VARCHAR(120) NOT NULL,
    "recipientEmail" VARCHAR(254) NOT NULL,
    "message" VARCHAR(120),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GiftCard_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Store" (
    "id" UUID NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "district" VARCHAR(80) NOT NULL,
    "address" VARCHAR(180) NOT NULL,
    "hours" VARCHAR(80) NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Store_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BlogPost" (
    "id" UUID NOT NULL,
    "slug" VARCHAR(180) NOT NULL,
    "title" VARCHAR(180) NOT NULL,
    "category" VARCHAR(40) NOT NULL,
    "summary" VARCHAR(255) NOT NULL,
    "body" TEXT NOT NULL,
    "imageUrl" VARCHAR(2048) NOT NULL,
    "readMinutes" INTEGER NOT NULL,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "publishedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BlogPost_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "LoyaltyEntry_reference_key" ON "LoyaltyEntry"("reference");

-- CreateIndex
CREATE INDEX "LoyaltyEntry_userId_createdAt_idx" ON "LoyaltyEntry"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "LoyaltyEntry_userId_type_createdAt_idx" ON "LoyaltyEntry"("userId", "type", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "GiftCard_code_key" ON "GiftCard"("code");

-- CreateIndex
CREATE INDEX "GiftCard_purchaserId_createdAt_idx" ON "GiftCard"("purchaserId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Store_slug_key" ON "Store"("slug");

-- CreateIndex
CREATE INDEX "Store_isActive_sortOrder_idx" ON "Store"("isActive", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "BlogPost_slug_key" ON "BlogPost"("slug");

-- CreateIndex
CREATE INDEX "BlogPost_isPublished_publishedAt_idx" ON "BlogPost"("isPublished", "publishedAt");

-- AddForeignKey
ALTER TABLE "LoyaltyEntry" ADD CONSTRAINT "LoyaltyEntry_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GiftCard" ADD CONSTRAINT "GiftCard_purchaserId_fkey" FOREIGN KEY ("purchaserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "started_at", "applied_steps_count")
VALUES (gen_random_uuid()::text, '1d372947b259dd32a2f2a5371b2ea4912426bca67213c9d2f82e50e9f0bd723f', now(), '20261009010000_loyalty_giftcards_content', now(), 1);

-- ---------------------------------------------------------------------
-- Migración 20261009020141_address_reference_phone
-- ---------------------------------------------------------------------
-- AlterTable
ALTER TABLE "Address" ADD COLUMN     "phone" VARCHAR(20),
ADD COLUMN     "reference" VARCHAR(180);

-- AlterTable
ALTER TABLE "OrderAddressSnapshot" ADD COLUMN     "phone" VARCHAR(20),
ADD COLUMN     "reference" VARCHAR(180);

INSERT INTO "_prisma_migrations" ("id", "checksum", "finished_at", "migration_name", "started_at", "applied_steps_count")
VALUES (gen_random_uuid()::text, '7e359027b17f85ba8ecf42e0c0674b8d60bc672204faa1bb955cb6ecd461e7e0', now(), '20261009020141_address_reference_phone', now(), 1);

-- ---------------------------------------------------------------------
-- Datos de demostración
-- ---------------------------------------------------------------------
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

COMMIT;
