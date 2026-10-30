import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OrderStatus, PaymentMethod, PaymentStatus, Prisma } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../../database/prisma.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto.js';
import { LiveService } from '../live/live.service.js';
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
  constructor(
    private readonly prisma: PrismaService,
    private readonly live: LiveService,
  ) {}

  async create(userId: string, input: CreateOrderDto) {
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
    const publicNumber = `PL-${randomInt(10_000_000, 99_999_999)}`;
    const paymentStatus = input.paymentMethod === PaymentMethod.CASH
      ? PaymentStatus.PENDING
      : PaymentStatus.SUCCEEDED;
    const address = await this.prisma.address.findFirst({
      where: input.addressId ? { id: input.addressId, userId } : { userId, isDefault: true },
    });
    if (input.addressId && !address) throw new NotFoundException('Dirección no encontrada');

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
          publicNumber,
          userId,
          paymentMethod: input.paymentMethod,
          subtotal,
          shipping: SHIPPING_COST,
          total,
          carrier: 'Platanitos Envíos',
          trackingCode: publicNumber,
          estimatedFrom: new Date(now + 6 * DAY_MS),
          estimatedTo: new Date(now + 8 * DAY_MS),
          addressId: address?.id,
          addressSnapshot: address
            ? {
                create: {
                  recipient: address.recipient,
                  line1: address.line1,
                  district: address.district,
                  province: address.province,
                  department: address.department,
                  postalCode: address.postalCode,
                  reference: address.reference,
                  phone: address.phone,
                  country: address.country,
                },
              }
            : undefined,
          items: { create: items },
          statusHistory: { create: { status: OrderStatus.PREPARATION, note: 'Pedido registrado' } },
          paymentAttempts: {
            create: {
              method: input.paymentMethod,
              amount: total,
              status: paymentStatus,
            },
          },
        },
        include: orderInclude,
      });
      await transaction.cartItem.deleteMany({ where: { cartId: cart.id } });
      await transaction.auditEvent.create({
        data: {
          userId,
          eventType: 'ORDER_NOTICE',
          metadata: {
            orderId: created.id,
            title: 'Pago y envío registrados',
            body: paymentStatus === PaymentStatus.PENDING
              ? `Pedido ${publicNumber}: el pago en efectivo queda pendiente. El envío con Platanitos Envíos usa el código ${publicNumber}.`
              : `Pedido ${publicNumber}: el pago quedó confirmado. El envío con Platanitos Envíos usa el código ${publicNumber}.`,
          },
        },
      });
      return created;
    });
    this.live.orderChanged(userId, {
      type: 'order.created',
      orderId: order.id,
      publicNumber: order.publicNumber,
      status: order.status,
      title: 'Pedido registrado',
      body: `Pedido ${order.publicNumber} quedó en preparación.`,
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

  /** Avanza el estado logístico del pedido. */
  async updateStatus(userId: string, publicNumber: string, input: UpdateOrderStatusDto) {
    const order = await this.prisma.order.findFirst({ where: { userId, publicNumber }, select: { id: true, status: true } });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    const current = STATUS_FLOW.indexOf(order.status);
    const next = STATUS_FLOW.indexOf(input.status);
    if (next !== current + 1) {
      throw new BadRequestException('El envío solo avanza un paso: preparación, despacho, en camino y entregado.');
    }
    const updated = await this.prisma.order.update({
      where: { id: order.id },
      data: {
        status: input.status,
        statusHistory: {
          create: STATUS_FLOW.slice(current + 1, next + 1).map((status) => ({ status, note: 'Estado actualizado' })),
        },
      },
      include: orderInclude,
    });
    await this.prisma.auditEvent.create({
      data: {
        userId,
        eventType: 'ORDER_NOTICE',
        metadata: {
          orderId: updated.id,
          title: 'Envío actualizado',
          body: `Pedido ${updated.publicNumber}: ${input.status}.`,
        },
      },
    });
    if (input.status === OrderStatus.DELIVERED && updated.paymentMethod === PaymentMethod.CASH) {
      await this.prisma.paymentAttempt.updateMany({
        where: { orderId: updated.id, status: PaymentStatus.PENDING },
        data: { status: PaymentStatus.SUCCEEDED },
      });
    }
    this.live.orderChanged(userId, {
      orderId: updated.id,
      publicNumber: updated.publicNumber,
      status: updated.status,
      title: 'Envío actualizado',
      body: `Pedido ${updated.publicNumber}: ${updated.status}.`,
    });
    return mapOrder(updated);
  }

  async notices(userId: string) {
    const events = await this.prisma.auditEvent.findMany({
      where: { userId, eventType: 'ORDER_NOTICE' },
      orderBy: { createdAt: 'desc' },
      take: 40,
    });
    return events.map((event) => {
      const data = event.metadata as { title?: string; body?: string; orderId?: string } | null;
      return {
        id: event.id,
        title: data?.title ?? 'Aviso',
        body: data?.body ?? '',
        orderId: data?.orderId ?? null,
        createdAt: event.createdAt,
      };
    });
  }
}
