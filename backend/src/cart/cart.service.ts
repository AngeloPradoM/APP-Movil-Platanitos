import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service.js';
import { AddCartItemDto } from './dto/add-cart-item.dto.js';
import { UpdateCartItemDto } from './dto/update-cart-item.dto.js';
import { mapCart } from './cart.mapper.js';

const cartInclude = {
  items: {
    orderBy: { createdAt: 'asc' as const },
    include: {
      variant: {
        include: {
          product: { select: { name: true, slug: true } },
        },
      },
    },
  },
} satisfies Prisma.CartInclude;

@Injectable()
export class CartService {
  constructor(private readonly prisma: PrismaService) {}

  async getCart(userId: string) {
    const cart = await this.prisma.cart.findUnique({ where: { userId }, include: cartInclude });
    return mapCart(cart ?? { id: null, status: 'ACTIVE', items: [] });
  }

  async addItem(userId: string, input: AddCartItemDto) {
    const variant = await this.prisma.productVariant.findFirst({
      where: { id: input.variantId, isActive: true, product: { isActive: true } },
    });
    if (!variant) throw new NotFoundException('Variante no encontrada');

    const cart = await this.prisma.cart.upsert({
      where: { userId },
      update: { status: 'ACTIVE' },
      create: { userId },
    });
    const existing = await this.prisma.cartItem.findUnique({ where: { cartId_variantId: { cartId: cart.id, variantId: variant.id } } });
    const quantity = (existing?.quantity ?? 0) + input.quantity;
    if (quantity > variant.stock) throw new BadRequestException('La cantidad supera el stock disponible');

    await this.prisma.cartItem.upsert({
      where: { cartId_variantId: { cartId: cart.id, variantId: variant.id } },
      update: { quantity },
      create: { cartId: cart.id, variantId: variant.id, quantity },
    });
    return this.getCart(userId);
  }

  async updateItem(userId: string, itemId: string, input: UpdateCartItemDto) {
    const item = await this.prisma.cartItem.findFirst({ where: { id: itemId, cart: { userId } }, include: { variant: true } });
    if (!item) throw new NotFoundException('Ítem de carrito no encontrado');
    if (input.quantity > item.variant.stock) throw new BadRequestException('La cantidad supera el stock disponible');
    if (input.quantity === 0) {
      await this.prisma.cartItem.delete({ where: { id: item.id } });
    } else {
      await this.prisma.cartItem.update({ where: { id: item.id }, data: { quantity: input.quantity } });
    }
    return this.getCart(userId);
  }

  async removeItem(userId: string, itemId: string) {
    const result = await this.prisma.cartItem.deleteMany({ where: { id: itemId, cart: { userId } } });
    if (result.count === 0) throw new NotFoundException('Ítem de carrito no encontrado');
    return this.getCart(userId);
  }
}
