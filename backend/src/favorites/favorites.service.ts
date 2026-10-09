import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service.js';
import { mapProduct, ProductWithRelations } from '../catalog/catalog.mapper.js';

const productInclude = {
  brand: { select: { name: true, slug: true } },
  category: { select: { name: true, slug: true } },
  images: { orderBy: { sortOrder: 'asc' as const }, take: 1 },
  variants: { where: { isActive: true }, orderBy: { price: 'asc' as const } },
};

@Injectable()
export class FavoritesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId, product: { isActive: true } },
      orderBy: { createdAt: 'desc' },
      include: { product: { include: productInclude } },
    });
    return favorites.map((favorite) => mapProduct(favorite.product as unknown as ProductWithRelations));
  }

  async add(userId: string, productId: string) {
    const product = await this.prisma.product.findFirst({ where: { id: productId, isActive: true }, select: { id: true } });
    if (!product) throw new NotFoundException('Producto no encontrado');
    await this.prisma.favorite.upsert({
      where: { userId_productId: { userId, productId } },
      update: {},
      create: { userId, productId },
    });
    return this.list(userId);
  }

  async remove(userId: string, productId: string) {
    await this.prisma.favorite.deleteMany({ where: { userId, productId } });
    return this.list(userId);
  }
}
