import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { OrderStatus, PaymentMethod, PaymentStatus, Prisma } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../database/prisma.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto.js';
import { mapOrder, orderInclude } from './orders.mapper.js';

export const SHIPPING_COST = new Prisma.Decimal('6.90');
const DAY_MS = 24 * 60 * 60 * 1000;
const STATUS_FLOW: OrderStatus[] = [
  OrderStatus.PREPARATION,
  OrderStatus.DISPATCH,
  OrderStatus.TRANSIT,
  OrderStatus.DELIVERED,
];

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, input: CreateOrderDto) {
    if (input.paymentMethod === PaymentMethod.CARD) {
      throw new UnprocessableEntityException('El pago con tarjeta no está disponible en la demostración.');
    }
    const cart = await this.prisma.cart.findUnique({
      where: { userId },
      include: { items: { include: { variant: { include: { product: true } } } } },
    });
    if (!cart || cart.items.length === 0) throw new BadRequestException('La bolsa está vacía');

    let subtotal = new Prisma.Decimal(0);
    const items = cart.items.map((item) => {
      if (!item.variant.isActive || !item.variant.product.isActive) {
        throw new BadRequestException(`El producto ${item.variant.product.name} ya no está disponible`);
      }
      const lineSubtotal = item.variant.price.mul(item.quantity);
      subtotal = subtotal.add(lineSubtotal);
      return {
        variantId: item.variant.id,
        productName: item.variant.product.name,
        sku: item.variant.sku,
        sizeSystem: item.variant.sizeSystem,
        sizeValue: item.variant.sizeValue,
        color: item.variant.color,
        quantity: item.quantity,
        unitPrice: item.variant.price,
        subtotal: lineSubtotal,
      };
    });
    const total = subtotal.add(SHIPPING_COST);
    const now = Date.now();

    const order = await this.prisma.$transaction(async (transaction) => {
      for (const item of items) {
        const updated = await transaction.productVariant.updateMany({
          where: { id: item.variantId, stock: { gte: item.quantity } },
          data: { stock: { decrement: item.quantity } },
        });
        if (updated.count === 0) throw new BadRequestException(`Stock insuficiente para ${item.sku}`);
      }
      const created = await transaction.order.create({
        data: {
          publicNumber: `PL-${randomInt(10_000_000, 99_999_999)}`,
          userId,
          paymentMethod: input.paymentMethod,
          subtotal,
          shipping: SHIPPING_COST,
          total,
          estimatedFrom: new Date(now + 6 * DAY_MS),
          estimatedTo: new Date(now + 8 * DAY_MS),
          items: { create: items },
          statusHistory: { create: { status: OrderStatus.PREPARATION, note: 'Pedido registrado' } },
          paymentAttempts: {
            create: {
              method: input.paymentMethod,
              amount: total,
              status: input.paymentMethod === PaymentMethod.WALLET ? PaymentStatus.SUCCEEDED : PaymentStatus.PENDING,
            },
          },
        },
        include: orderInclude,
      });
      await transaction.cartItem.deleteMany({ where: { cartId: cart.id } });
      return created;
    });
    return mapOrder(order);
  }

  async list(userId: string) {
    const orders = await this.prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: orderInclude,
    });
    return orders.map(mapOrder);
  }

  async get(userId: string, publicNumber: string) {
    const order = await this.prisma.order.findFirst({ where: { userId, publicNumber }, include: orderInclude });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    return mapOrder(order);
  }

  /** Simula el avance logístico; en producción lo haría el operador o el courier. */
  async updateStatus(userId: string, publicNumber: string, input: UpdateOrderStatusDto) {
    const order = await this.prisma.order.findFirst({ where: { userId, publicNumber }, select: { id: true, status: true } });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    const current = STATUS_FLOW.indexOf(order.status);
    const next = STATUS_FLOW.indexOf(input.status);
    if (current < 0 || next <= current) {
      throw new BadRequestException('El pedido no puede volver a un estado anterior');
    }
    const updated = await this.prisma.order.update({
      where: { id: order.id },
      data: {
        status: input.status,
        statusHistory: {
          create: STATUS_FLOW.slice(current + 1, next + 1).map((status) => ({ status, note: 'Estado simulado' })),
        },
      },
      include: orderInclude,
    });
    return mapOrder(updated);
  }
}
