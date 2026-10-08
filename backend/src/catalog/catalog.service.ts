import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service.js';
import { ProductQueryDto } from './dto/product-query.dto.js';
import { mapProduct } from './catalog.mapper.js';

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  async listProducts(query: ProductQueryDto) {
    const page = Number(query.page ?? 1);
    const limit = Number(query.limit ?? 20);
    const where: Prisma.ProductWhereInput = {
      isActive: true,
      ...(query.q
        ? {
            OR: [
              { name: { contains: query.q.trim(), mode: 'insensitive' } },
              { description: { contains: query.q.trim(), mode: 'insensitive' } },
            ],
          }
        : {}),
      ...(query.category
        ? { category: { slug: query.category.trim(), isActive: true } }
        : {}),
      ...(query.brand ? { brand: { slug: query.brand.trim(), isActive: true } } : {}),
    };

    const [total, products] = await this.prisma.$transaction([
      this.prisma.product.count({ where }),
      this.prisma.product.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          brand: { select: { name: true, slug: true } },
          category: { select: { name: true, slug: true } },
          images: { orderBy: { sortOrder: 'asc' }, take: 1 },
          variants: {
            where: { isActive: true },
            orderBy: { price: 'asc' },
            select: { id: true, sku: true, sizeSystem: true, sizeValue: true, color: true, price: true, comparePrice: true, stock: true },
          },
        },
      }),
    ]);

    return {
      data: products.map(mapProduct),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getProductBySlug(slug: string) {
    const product = await this.prisma.product.findFirst({
      where: { slug, isActive: true },
      include: {
        brand: { select: { name: true, slug: true } },
        category: { select: { name: true, slug: true } },
        images: { orderBy: { sortOrder: 'asc' } },
        variants: { where: { isActive: true }, orderBy: { price: 'asc' } },
      },
    });

    if (!product) throw new NotFoundException('Producto no encontrado');
    return mapProduct(product);
  }
}
