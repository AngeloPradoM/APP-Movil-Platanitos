import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';

@Injectable()
export class OperationsService {
  constructor(private readonly prisma: PrismaService) {}

  async report() {
    const [orders, pendingOrders, deliveredOrders, lowStockVariants, openSupportRequests, activeDeliveries, sales] =
      await Promise.all([
        this.prisma.order.count(),
        this.prisma.order.count({
          where: { status: { in: [OrderStatus.PREPARATION, OrderStatus.DISPATCH, OrderStatus.TRANSIT] } },
        }),
        this.prisma.order.count({ where: { status: OrderStatus.DELIVERED } }),
        this.prisma.productVariant.count({ where: { isActive: true, stock: { lte: 3 } } }),
        this.prisma.supportTicket.count({ where: { status: { in: ['OPEN', 'IN_PROGRESS'] } } }),
        this.prisma.order.count({ where: { status: OrderStatus.TRANSIT } }),
        this.prisma.order.aggregate({
          where: { status: { not: OrderStatus.CANCELLED } },
          _sum: { total: true },
        }),
      ]);
    const total = sales._sum.total ?? new Prisma.Decimal(0);
    return {
      orders,
      pendingOrders,
      deliveredOrders,
      lowStockVariants,
      openSupportRequests,
      activeDeliveries,
      totalSalesCents: Math.round(Number(total) * 100),
    };
  }

  async fulfillmentTasks() {
    const orders = await this.prisma.order.findMany({
      where: { status: { in: [OrderStatus.PREPARATION, OrderStatus.DISPATCH, OrderStatus.TRANSIT] } },
      orderBy: { createdAt: 'asc' },
      include: {
        items: { select: { quantity: true } },
        statusHistory: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    });
    return orders.map((order) => ({
      orderId: order.id,
      publicNumber: order.publicNumber,
      status: this.taskStatus(order.status, order.statusHistory[0]?.note),
      createdAt: order.createdAt,
      units: order.items.reduce((sum, item) => sum + item.quantity, 0),
    }));
  }

  async startPreparation(orderId: string) {
    await this.note(orderId, OrderStatus.PREPARATION, 'PREPARING');
  }

  async markPrepared(orderId: string) {
    await this.note(orderId, OrderStatus.PREPARATION, 'PREPARED');
  }

  async dispatch(orderId: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, select: { status: true } });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    if (order.status !== OrderStatus.PREPARATION) {
      throw new BadRequestException('Solo se despacha un pedido en preparación.');
    }
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: OrderStatus.DISPATCH,
        carrier: 'Platanitos Envíos',
        statusHistory: { create: { status: OrderStatus.DISPATCH, note: 'Despachado' } },
      },
    });
    await this.notice(updated.userId, updated.id, 'Envío despachado', `Pedido ${updated.publicNumber} salió del almacén. Código ${updated.trackingCode ?? updated.publicNumber}.`);
  }

  private async move(orderId: string, from: OrderStatus, to: OrderStatus, body: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    if (order.status !== from) throw new BadRequestException('El pedido no está en el paso anterior del envío.');
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: to, statusHistory: { create: { status: to, note: body } } },
    });
    await this.notice(updated.userId, updated.id, 'Envío actualizado', `Pedido ${updated.publicNumber}: ${body}`);
    return updated;
  }

  private notice(userId: string, orderId: string, title: string, body: string) {
    return this.prisma.auditEvent.create({
      data: { userId, eventType: 'ORDER_NOTICE', metadata: { orderId, title, body } },
    });
  }

  async markInTransit(orderId: string) {
    await this.move(orderId, OrderStatus.DISPATCH, OrderStatus.TRANSIT, 'Tu pedido está en camino.');
  }

  async markDelivered(orderId: string) {
    const order = await this.move(orderId, OrderStatus.TRANSIT, OrderStatus.DELIVERED, 'Tu pedido fue entregado.');
    if (order.paymentMethod === 'CASH') {
      await this.prisma.paymentAttempt.updateMany({
        where: { orderId, status: 'PENDING' },
        data: { status: 'SUCCEEDED' },
      });
    }
  }

  private taskStatus(status: OrderStatus, note?: string | null) {
    if (status === OrderStatus.TRANSIT) return 'IN_TRANSIT';
    if (status === OrderStatus.DISPATCH) return 'DISPATCHED';
    if (note === 'PREPARING' || note === 'Preparación iniciada') return 'PREPARING';
    if (note === 'PREPARED' || note === 'Listo para despacho') return 'PREPARED';
    return 'PENDING';
  }

  private async note(orderId: string, status: OrderStatus, marker: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, select: { status: true } });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    if (order.status !== status) throw new BadRequestException('El pedido no está en preparación.');
    await this.prisma.orderStatusHistory.create({ data: { orderId, status, note: marker } });
  }
}
