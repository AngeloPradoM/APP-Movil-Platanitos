import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';
import { LiveService } from '../live/live.service.js';

const STAFF_ROLES = new Set(['ALMACEN', 'ADMINISTRADOR']);

export function assertWarehouseStaff(role: string) {
  if (!STAFF_ROLES.has(role)) {
    throw new BadRequestException('Esta acción es solo para almacén o administración.');
  }
}

@Injectable()
export class InventoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly live: LiveService,
  ) {}

  async list(query = '', lowStockOnly = false) {
    const term = query.trim();
    const variants = await this.prisma.productVariant.findMany({
      where: {
        isActive: true,
        product: { isActive: true },
        ...(term
          ? {
              OR: [
                { product: { name: { contains: term, mode: 'insensitive' } } },
                { product: { category: { name: { contains: term, mode: 'insensitive' } } } },
                { color: { contains: term, mode: 'insensitive' } },
                { sizeValue: { contains: term, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        product: { select: { id: true, name: true, category: { select: { name: true } } } },
        cartItems: { where: { cart: { status: 'ACTIVE' } }, select: { quantity: true } },
      },
      orderBy: [{ product: { name: 'asc' } }, { sizeValue: 'asc' }],
      take: 200,
    });
    return variants
      .map((variant) => {
        const reservedStock = variant.cartItems.reduce((sum, item) => sum + item.quantity, 0);
        const available = variant.stock - reservedStock;
        return {
          variantId: variant.id,
          productId: variant.product.id,
          productName: variant.product.name,
          category: variant.product.category.name,
          price: variant.price.toString(),
          sizeSystem: variant.sizeSystem,
          sizeValue: variant.sizeValue,
          color: variant.color,
          physicalStock: variant.stock,
          reservedStock,
          availableStock: available,
          lowStock: available <= 3,
        };
      })
      .filter((item) => !lowStockOnly || item.lowStock);
  }

  async movements(variantId: string) {
    const events = await this.prisma.auditEvent.findMany({
      where: {
        eventType: { in: ['STOCK_ENTRY', 'STOCK_EXIT', 'STOCK_ADJUSTMENT'] },
        metadata: { path: ['variantId'], equals: variantId },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return events.map((event, index) => {
      const data = event.metadata as { quantity?: number; reason?: string } | null;
      return {
        id: index + 1,
        variantId,
        type: event.eventType.replace('STOCK_', '').toLowerCase(),
        quantity: data?.quantity ?? 0,
        reason: data?.reason ?? '',
        responsibleUserId: event.userId ?? '',
        createdAt: event.createdAt,
      };
    });
  }

  async registerMovement(
    userId: string,
    variantId: string,
    input: { type: 'entry' | 'exit' | 'adjustment'; quantity: number; reason: string },
  ) {
    const reason = input.reason.trim();
    if (!reason) throw new BadRequestException('Indica el motivo del movimiento.');
    if (input.quantity < 0 || (input.quantity === 0 && input.type !== 'adjustment')) {
      throw new BadRequestException('La cantidad no es válida.');
    }
    await this.prisma.$transaction(async (transaction) => {
      const variant = await transaction.productVariant.findUnique({ where: { id: variantId } });
      if (!variant) throw new NotFoundException('Variante no encontrada');
      const next = input.type === 'entry'
        ? variant.stock + input.quantity
        : input.type === 'exit'
          ? variant.stock - input.quantity
          : input.quantity;
      if (next < 0) throw new BadRequestException('El stock no puede quedar negativo.');
      await transaction.productVariant.update({ where: { id: variantId }, data: { stock: next } });
      await transaction.auditEvent.create({
        data: {
          userId,
          eventType: `STOCK_${input.type.toUpperCase()}`,
          metadata: { variantId, quantity: input.quantity, reason },
        },
      });
    });
    this.live.publish({ audience: 'staff', type: 'inventory.updated' });
  }

  async updatePrice(variantId: string, price: number) {
    if (!Number.isFinite(price) || price < 0) {
      throw new BadRequestException('El precio no es válido.');
    }
    const updated = await this.prisma.productVariant.updateMany({
      where: { id: variantId },
      data: { price: new Prisma.Decimal(price.toFixed(2)) },
    });
    if (updated.count === 0) throw new NotFoundException('Variante no encontrada');
    this.live.publish({ audience: 'staff', type: 'inventory.updated' });
  }

  async categories() {
    const categories = await this.prisma.category.findMany({
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        isActive: true,
        _count: { select: { products: { where: { isActive: true } } } },
      },
    });
    return categories.map((category) => ({
      id: category.id,
      name: category.name,
      slug: category.slug,
      isActive: category.isActive,
      productCount: category._count.products,
    }));
  }

  async setCategoryActive(id: string, isActive: boolean) {
    const updated = await this.prisma.category.updateMany({ where: { id }, data: { isActive } });
    if (updated.count === 0) throw new NotFoundException('Categoría no encontrada');
    this.live.publish({ audience: 'all', type: 'catalog.updated' });
  }
}
