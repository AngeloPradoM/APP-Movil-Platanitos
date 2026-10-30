import { Prisma } from '@prisma/client';

export type ProductWithRelations = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  brand: { name: string; slug: string };
  category: { name: string; slug: string };
  images: Array<{ url: string; altText: string | null; sortOrder: number }>;
  variants: Array<{
    id: string;
    sku: string;
    sizeSystem: string;
    sizeValue: string;
    color: string;
    price: Prisma.Decimal;
    comparePrice: Prisma.Decimal | null;
    stock: number;
  }>;
};

export function mapProduct(product: ProductWithRelations) {
  return {
    id: product.id,
    name: product.name,
    slug: product.slug,
    description: product.description,
    brand: product.brand,
    category: product.category,
    images: product.images.map((image) => ({
      url: image.url,
      altText: image.altText,
      sortOrder: image.sortOrder,
    })),
    variants: product.variants.map((variant) => ({
      id: variant.id,
      sku: variant.sku,
      sizeSystem: variant.sizeSystem,
      sizeValue: variant.sizeValue,
      color: variant.color,
      price: variant.price.toString(),
      comparePrice: variant.comparePrice?.toString() ?? null,
      stock: variant.stock,
    })),
  };
}
