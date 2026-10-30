import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';
import { LiveService } from '../live/live.service.js';

@Injectable()
export class OperationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly live: LiveService,
  ) {}

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
    this.live.orderChanged(updated.userId, {
      orderId: updated.id,
      publicNumber: updated.publicNumber,
      status: updated.status,
      title: 'Envío despachado',
    });
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
    this.live.orderChanged(updated.userId, {
      orderId: updated.id,
      publicNumber: updated.publicNumber,
      status: updated.status,
      title: 'Envío actualizado',
      body,
    });
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

  async deliveries() {
    const orders = await this.prisma.order.findMany({
      where: { status: { in: [OrderStatus.DISPATCH, OrderStatus.TRANSIT] } },
      orderBy: { updatedAt: 'asc' },
      include: { addressSnapshot: true },
    });
    return orders.map((order) => ({
      id: order.id,
      orderId: order.id,
      publicNumber: order.publicNumber,
      assignedUserId: '',
      status: order.status === OrderStatus.DISPATCH ? 'ASSIGNED' : 'IN_TRANSIT',
      address: order.addressSnapshot
        ? `${order.addressSnapshot.line1}, ${order.addressSnapshot.district}`
        : 'Dirección por coordinar',
      assignedAt: order.updatedAt,
      hasEvidence: false,
    }));
  }

  async deliveryEvidence(orderId: string) {
    const events = await this.prisma.auditEvent.findMany({
      where: { eventType: 'DELIVERY_EVIDENCE' },
      orderBy: { createdAt: 'desc' },
      take: 80,
    });
    const event = events.find((item) => (item.metadata as { orderId?: string } | null)?.orderId === orderId);
    if (!event) return null;
    const data = event.metadata as {
      recipientName?: string;
      signatureData?: string;
      photo?: string;
      courierId?: string;
    };
    return {
      deliveryId: orderId,
      recipientName: data.recipientName ?? '',
      signatureData: data.signatureData ?? '[]',
      photo: data.photo ?? '',
      courierId: data.courierId ?? null,
      capturedAt: event.createdAt,
    };
  }

  async deliveryHistory(viewer: { id: string; role: string }) {
    const orders = await this.prisma.order.findMany({
      where: { status: OrderStatus.DELIVERED },
      orderBy: { updatedAt: 'desc' },
      take: 60,
      include: { addressSnapshot: true },
    });
    const events = await this.prisma.auditEvent.findMany({
      where: { eventType: 'DELIVERY_EVIDENCE' },
      orderBy: { createdAt: 'desc' },
      take: 120,
    });
    const evidenceByOrder = new Map<
      string,
      { recipientName: string; courierId: string | null; capturedAt: Date }
    >();
    for (const event of events) {
      const data = event.metadata as {
        orderId?: string;
        recipientName?: string;
        courierId?: string;
      } | null;
      if (!data?.orderId || evidenceByOrder.has(data.orderId)) continue;
      evidenceByOrder.set(data.orderId, {
        recipientName: data.recipientName ?? '',
        courierId: data.courierId ?? null,
        capturedAt: event.createdAt,
      });
    }
    const mineOnly = viewer.role === 'REPARTIDOR';
    return orders
      .filter((order) => {
        if (!mineOnly) return true;
        const evidence = evidenceByOrder.get(order.id);
        return evidence?.courierId === viewer.id;
      })
      .map((order) => {
        const evidence = evidenceByOrder.get(order.id);
        return {
          id: order.id,
          orderId: order.id,
          publicNumber: order.publicNumber,
          assignedUserId: evidence?.courierId ?? '',
          status: 'DELIVERED',
          address: order.addressSnapshot
            ? `${order.addressSnapshot.line1}, ${order.addressSnapshot.district}`
            : 'Dirección por coordinar',
          assignedAt: evidence?.capturedAt ?? order.updatedAt,
          hasEvidence: evidence != null,
          recipientName: evidence?.recipientName ?? null,
        };
      });
  }

  async markDelivered(
    orderId: string,
    proof?: { recipientName?: string; signatureData?: string; photo?: string },
    courierId?: string,
  ) {
    const order = await this.move(orderId, OrderStatus.TRANSIT, OrderStatus.DELIVERED, 'Tu pedido fue entregado.');
    if (proof?.recipientName) {
      await this.prisma.auditEvent.create({
        data: {
          userId: order.userId,
          eventType: 'DELIVERY_EVIDENCE',
          metadata: {
            orderId,
            courierId: courierId ?? null,
            recipientName: proof.recipientName,
            signatureData: proof.signatureData ?? '[]',
            photo: proof.photo ?? '',
          },
        },
      });
    }
    if (order.paymentMethod === 'CASH') {
      await this.prisma.paymentAttempt.updateMany({
        where: { orderId, status: 'PENDING' },
        data: { status: 'SUCCEEDED' },
      });
      this.live.orderChanged(order.userId, {
        orderId: order.id,
        publicNumber: order.publicNumber,
        status: order.status,
        title: 'Pago confirmado',
        body: `Pedido ${order.publicNumber}: el efectivo quedó cobrado.`,
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
    const current = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!current) throw new NotFoundException('Pedido no encontrado');
    if (current.status !== status) throw new BadRequestException('El pedido no está en preparación.');
    await this.prisma.orderStatusHistory.create({ data: { orderId, status, note: marker } });
    const body = marker === 'PREPARING'
      ? `Pedido ${current.publicNumber}: empezó la preparación.`
      : `Pedido ${current.publicNumber}: está listo para despacho.`;
    await this.notice(current.userId, current.id, 'Preparación', body);
    this.live.orderChanged(current.userId, {
      orderId: current.id,
      publicNumber: current.publicNumber,
      status: marker,
      title: 'Preparación',
      body,
    });
  }
}
