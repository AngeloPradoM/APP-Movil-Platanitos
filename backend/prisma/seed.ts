import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, SizeSystem } from '@prisma/client';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL no está configurada');

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: databaseUrl }) });

const catalog = [
  {
    brand: { name: 'Nike', slug: 'nike' },
    category: { name: 'Zapatillas', slug: 'zapatillas' },
    name: 'Nike Air Max 270',
    slug: 'nike-air-max-270',
    description: 'Zapatilla urbana con amortiguación Air para uso diario.',
    image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
    variants: [
      { sku: 'PLAT-NIKE-AM270-40-NEGRO', sizeValue: '40', color: 'Negro', price: '499.90', stock: 8 },
      { sku: 'PLAT-NIKE-AM270-41-NEGRO', sizeValue: '41', color: 'Negro', price: '499.90', stock: 6 },
    ],
  },
  {
    brand: { name: 'Adidas', slug: 'adidas' },
    category: { name: 'Zapatillas', slug: 'zapatillas' },
    name: 'Adidas Grand Court Base',
    slug: 'adidas-grand-court-base',
    description: 'Diseño clásico y versátil para combinar con cualquier estilo.',
    image: 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77',
    variants: [
      { sku: 'PLAT-ADI-GRAND-39-BLANCO', sizeValue: '39', color: 'Blanco', price: '249.90', stock: 12 },
      { sku: 'PLAT-ADI-GRAND-40-BLANCO', sizeValue: '40', color: 'Blanco', price: '249.90', stock: 10 },
    ],
  },
] as const;

async function main() {
  for (const item of catalog) {
    const brand = await prisma.brand.upsert({
      where: { slug: item.brand.slug },
      update: { name: item.brand.name, isActive: true },
      create: item.brand,
    });
    const category = await prisma.category.upsert({
      where: { slug: item.category.slug },
      update: { name: item.category.name, isActive: true },
      create: item.category,
    });
    const product = await prisma.product.upsert({
      where: { slug: item.slug },
      update: { name: item.name, description: item.description, brandId: brand.id, categoryId: category.id, isActive: true },
      create: { name: item.name, slug: item.slug, description: item.description, brandId: brand.id, categoryId: category.id },
    });

    await prisma.productImage.upsert({
      where: { productId_sortOrder: { productId: product.id, sortOrder: 0 } },
      update: { url: item.image, altText: item.name },
      create: { productId: product.id, url: item.image, altText: item.name, sortOrder: 0 },
    });

    for (const variant of item.variants) {
      await prisma.productVariant.upsert({
        where: { sku: variant.sku },
        update: { productId: product.id, sizeSystem: SizeSystem.EUR, sizeValue: variant.sizeValue, color: variant.color, price: variant.price, stock: variant.stock, isActive: true },
        create: { productId: product.id, sku: variant.sku, sizeSystem: SizeSystem.EUR, sizeValue: variant.sizeValue, color: variant.color, price: variant.price, stock: variant.stock },
      });
    }
  }
  console.log(`Seed completado: ${catalog.length} productos de demostración.`);
}

main().catch((error) => {
  console.error('Error ejecutando el seed:', error);
  process.exitCode = 1;
}).finally(() => prisma.$disconnect());
