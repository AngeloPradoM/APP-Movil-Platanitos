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

const stores = [
  { slug: 'jockey-plaza', name: 'Platanitos Jockey Plaza', district: 'Santiago de Surco', address: 'Av. Javier Prado Este 4200, tienda 1-12' },
  { slug: 'mega-plaza', name: 'Platanitos Mega Plaza', district: 'Independencia', address: 'Av. Alfredo Mendiola 3698, tienda 214' },
  { slug: 'plaza-san-miguel', name: 'Platanitos Plaza San Miguel', district: 'San Miguel', address: 'Av. La Marina 2000, tienda A-35' },
  { slug: 'real-plaza-salaverry', name: 'Platanitos Real Plaza Salaverry', district: 'Jesús María', address: 'Av. Gral. Felipe Salaverry 2370, tienda 108' },
] as const;

const blogPosts = [
  {
    slug: 'elegir-talla-perfecta',
    title: 'Cómo elegir la talla perfecta sin probarte el calzado',
    category: 'Guías',
    summary: 'Mide tu pie en casa y compara con nuestra tabla EUR, US y CM.',
    body: 'Coloca una hoja en el piso, apoya el talón contra la pared y marca la punta del dedo más largo. Mide la distancia en centímetros y busca ese valor en la tabla CM de la ficha del producto. Si estás entre dos tallas, elige la mayor para zapatillas y la menor para sandalias con correas ajustables.',
    imageUrl: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?fit=crop&q=85&w=800',
    readMinutes: 3,
  },
  {
    slug: 'tendencias-plataformas-tonos-tierra',
    title: 'Tendencias de temporada: plataformas y tonos tierra',
    category: 'Tendencias',
    summary: 'Las suelas altas y los colores camel dominan esta temporada.',
    body: 'Las plataformas siguen siendo protagonistas por su comodidad y estilo. Combínalas con prendas en tonos tierra, beige y verde oliva. Para la noche, los tacos cuadrados ofrecen estabilidad sin perder elegancia.',
    imageUrl: 'https://images.unsplash.com/photo-1591884807537-0bce39888fe0?fit=crop&q=85&w=800',
    readMinutes: 4,
  },
  {
    slug: 'cuidar-botines-cuero-lluvia',
    title: 'Cuida tus botines de cuero en temporada de lluvia',
    category: 'Cuidado',
    summary: 'Tres pasos sencillos para que tu calzado dure más.',
    body: 'Limpia el barro con un paño húmedo apenas llegues a casa. Deja secar a temperatura ambiente, nunca cerca de una fuente de calor. Aplica una crema hidratante incolora una vez por semana y usa un spray impermeabilizante antes de salir.',
    imageUrl: 'https://images.unsplash.com/photo-1605732440685-d0654d81aa30?fit=crop&q=85&w=800',
    readMinutes: 2,
  },
] as const;

async function seedContent() {
  for (const [sortOrder, store] of stores.entries()) {
    const data = { ...store, hours: 'Lun a Dom · 10:00 a 22:00', sortOrder, isActive: true };
    await prisma.store.upsert({ where: { slug: store.slug }, update: data, create: data });
  }
  for (const post of blogPosts) {
    await prisma.blogPost.upsert({ where: { slug: post.slug }, update: post, create: post });
  }
}

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
  await seedContent();
  console.log(
    `Seed completado: ${catalog.length} productos, ${stores.length} tiendas y ${blogPosts.length} artículos de demostración.`,
  );
}

main().catch((error) => {
  console.error('Error ejecutando el seed:', error);
  process.exitCode = 1;
}).finally(() => prisma.$disconnect());
