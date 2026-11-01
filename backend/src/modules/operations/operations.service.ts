import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStatus, Prisma, SupportTicketStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';
import { LiveService } from '../live/live.service.js';

const SUPPORT_TYPES = new Set(['CHANGE', 'RETURN', 'CLAIM']);

const SUPPORT_TYPE_LABEL: Record<string, string> = {
  CHANGE: 'Cambio',
  RETURN: 'Devolución',
  CLAIM: 'Reclamo',
};

/** Estados que consume Flutter (demo + remoto). */
const STATUS_OUT: Record<SupportTicketStatus, string> = {
  OPEN: 'REGISTERED',
  IN_PROGRESS: 'IN_REVIEW',
  RESOLVED: 'RESOLVED',
  CLOSED: 'REJECTED',
};

const STATUS_IN: Record<string, SupportTicketStatus> = {
  REGISTERED: SupportTicketStatus.OPEN,
  IN_REVIEW: SupportTicketStatus.IN_PROGRESS,
  RESOLVED: SupportTicketStatus.RESOLVED,
  REJECTED: SupportTicketStatus.CLOSED,
  OPEN: SupportTicketStatus.OPEN,
  IN_PROGRESS: SupportTicketStatus.IN_PROGRESS,
  CLOSED: SupportTicketStatus.CLOSED,
};

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

  async supportTickets(viewer: { id: string; role: string }) {
    const staff = viewer.role === 'ATENCION_CLIENTE' || viewer.role === 'ADMINISTRADOR';
    const tickets = await this.prisma.supportTicket.findMany({
      where: staff ? undefined : { userId: viewer.id },
      orderBy: { createdAt: 'desc' },
      take: 80,
      include: {
        order: { select: { id: true, publicNumber: true, status: true } },
        user: { select: { id: true, name: true, email: true } },
      },
    });
    const notes = await this.prisma.auditEvent.findMany({
      where: {
        eventType: 'SUPPORT_RESOLUTION',
        createdAt: { gte: tickets.at(-1)?.createdAt ?? new Date(0) },
      },
      orderBy: { createdAt: 'desc' },
      take: 160,
    });
    const noteByTicket = new Map<string, string>();
    for (const event of notes) {
      const data = event.metadata as { ticketId?: string; note?: string } | null;
      if (!data?.ticketId || noteByTicket.has(data.ticketId)) continue;
      if (data.note?.trim()) noteByTicket.set(data.ticketId, data.note.trim());
    }
    return tickets.map((ticket) => {
      const type = this.supportType(ticket.subject);
      return {
        id: ticket.id,
        orderId: ticket.orderId ?? ticket.order?.id ?? '',
        publicNumber: ticket.order?.publicNumber ?? 'Sin pedido',
        userId: ticket.userId,
        customerName: ticket.user.name,
        customerEmail: ticket.user.email,
        type,
        status: STATUS_OUT[ticket.status],
        reason: ticket.message,
        resolutionNote: noteByTicket.get(ticket.id) ?? null,
        createdAt: ticket.createdAt,
        updatedAt: ticket.updatedAt,
      };
    });
  }

  async createSupportTicket(
    user: { id: string; role: string },
    input: { publicNumber: string; type: string; reason: string },
  ) {
    if (user.role !== 'CLIENTE' && user.role !== 'ADMINISTRADOR') {
      throw new ForbiddenException('Solo el cliente puede registrar una solicitud.');
    }
    const type = input.type.trim().toUpperCase();
    if (!SUPPORT_TYPES.has(type)) {
      throw new BadRequestException('Tipo inválido. Usa CHANGE, RETURN o CLAIM.');
    }
    const reason = input.reason.trim();
    if (reason.length < 10) {
      throw new BadRequestException('Describe el motivo con al menos 10 caracteres.');
    }
    const order = await this.prisma.order.findFirst({
      where: { publicNumber: input.publicNumber.trim(), userId: user.id },
    });
    if (!order) throw new NotFoundException('Pedido no encontrado.');
    this.assertSupportEligible(order.status, type);

    const open = await this.prisma.supportTicket.findFirst({
      where: {
        userId: user.id,
        orderId: order.id,
        subject: { startsWith: `[${type}]` },
        status: { in: [SupportTicketStatus.OPEN, SupportTicketStatus.IN_PROGRESS] },
      },
    });
    if (open) {
      throw new BadRequestException(
        `Ya tienes un ${SUPPORT_TYPE_LABEL[type].toLowerCase()} abierto para este pedido.`,
      );
    }

    const ticket = await this.prisma.supportTicket.create({
      data: {
        userId: user.id,
        orderId: order.id,
        subject: `[${type}] ${SUPPORT_TYPE_LABEL[type]} · ${order.publicNumber}`,
        message: reason,
        status: SupportTicketStatus.OPEN,
      },
      include: { order: { select: { publicNumber: true } }, user: { select: { name: true, email: true } } },
    });

    await this.notice(
      user.id,
      order.id,
      'Solicitud registrada',
      `Tu ${SUPPORT_TYPE_LABEL[type].toLowerCase()} del pedido ${order.publicNumber} fue recibido. Atención al cliente lo revisará.`,
    );
    this.live.publish({
      audience: 'staff',
      type: 'support.created',
      orderId: order.id,
      publicNumber: order.publicNumber,
      status: 'REGISTERED',
      title: 'Nueva solicitud',
      body: `${SUPPORT_TYPE_LABEL[type]} · ${order.publicNumber}`,
    });
    this.live.publish({
      audience: 'customer',
      userId: user.id,
      type: 'support.created',
      orderId: order.id,
      publicNumber: order.publicNumber,
      status: 'REGISTERED',
      title: 'Solicitud registrada',
      body: `Pedido ${order.publicNumber}: tu solicitud quedó registrada.`,
    });

    return {
      id: ticket.id,
      orderId: order.id,
      publicNumber: order.publicNumber,
      userId: user.id,
      customerName: ticket.user.name,
      customerEmail: ticket.user.email,
      type,
      status: 'REGISTERED',
      reason,
      resolutionNote: null,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
    };
  }

  async updateSupportTicket(
    agent: { id: string; role: string },
    ticketId: string,
    input: { status: string; note?: string },
  ) {
    if (agent.role !== 'ATENCION_CLIENTE' && agent.role !== 'ADMINISTRADOR') {
      throw new ForbiddenException('Solo atención al cliente puede gestionar solicitudes.');
    }
    const next = STATUS_IN[input.status.trim().toUpperCase()];
    if (!next) throw new BadRequestException('Estado inválido.');

    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: { order: { select: { id: true, publicNumber: true } } },
    });
    if (!ticket) throw new NotFoundException('Solicitud no encontrada.');

    const allowed: Partial<Record<SupportTicketStatus, SupportTicketStatus[]>> = {
      OPEN: [SupportTicketStatus.IN_PROGRESS, SupportTicketStatus.CLOSED],
      IN_PROGRESS: [SupportTicketStatus.RESOLVED, SupportTicketStatus.CLOSED],
      RESOLVED: [],
      CLOSED: [],
    };
    if (!(allowed[ticket.status] ?? []).includes(next)) {
      throw new BadRequestException('Esa transición no está permitida.');
    }
    if (
      (next === SupportTicketStatus.RESOLVED || next === SupportTicketStatus.CLOSED) &&
      !(input.note?.trim())
    ) {
      throw new BadRequestException('Indica una nota de resolución o rechazo.');
    }

    const updated = await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status: next },
      include: {
        order: { select: { id: true, publicNumber: true } },
        user: { select: { name: true, email: true } },
      },
    });

    const note = input.note?.trim() ?? '';
    if (note) {
      await this.prisma.auditEvent.create({
        data: {
          userId: agent.id,
          eventType: 'SUPPORT_RESOLUTION',
          metadata: {
            ticketId,
            status: STATUS_OUT[next],
            note,
            customerUserId: ticket.userId,
            orderId: ticket.orderId,
          },
        },
      });
    }

    const type = this.supportType(ticket.subject);
    const publicNumber = updated.order?.publicNumber ?? 'pedido';
    const title =
      next === SupportTicketStatus.IN_PROGRESS
        ? 'Solicitud en revisión'
        : next === SupportTicketStatus.RESOLVED
          ? 'Solicitud resuelta'
          : 'Solicitud rechazada';
    const body =
      next === SupportTicketStatus.IN_PROGRESS
        ? `Pedido ${publicNumber}: atención al cliente está revisando tu ${SUPPORT_TYPE_LABEL[type].toLowerCase()}.`
        : next === SupportTicketStatus.RESOLVED
          ? `Pedido ${publicNumber}: tu ${SUPPORT_TYPE_LABEL[type].toLowerCase()} fue resuelto. ${note}`
          : `Pedido ${publicNumber}: tu ${SUPPORT_TYPE_LABEL[type].toLowerCase()} fue rechazado. ${note}`;

    if (ticket.orderId) {
      await this.notice(ticket.userId, ticket.orderId, title, body);
    }
    this.live.orderChanged(ticket.userId, {
      type: 'support.updated',
      orderId: ticket.orderId ?? undefined,
      publicNumber,
      status: STATUS_OUT[next],
      title,
      body,
    });

    return {
      id: updated.id,
      orderId: updated.orderId ?? '',
      publicNumber,
      userId: updated.userId,
      customerName: updated.user.name,
      customerEmail: updated.user.email,
      type,
      status: STATUS_OUT[next],
      reason: updated.message,
      resolutionNote: note || null,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    };
  }

  private supportType(subject: string) {
    const match = /^\[(CHANGE|RETURN|CLAIM)\]/.exec(subject);
    return match?.[1] ?? 'CLAIM';
  }

  private assertSupportEligible(status: OrderStatus, type: string) {
    if (status === OrderStatus.CANCELLED) {
      throw new BadRequestException('No se pueden abrir solicitudes sobre un pedido cancelado.');
    }
    if (type === 'CLAIM') {
      if (
        status === OrderStatus.PREPARATION ||
        status === OrderStatus.DISPATCH ||
        status === OrderStatus.TRANSIT ||
        status === OrderStatus.DELIVERED
      ) {
        return;
      }
      throw new BadRequestException('El reclamo solo aplica a pedidos en curso o entregados.');
    }
    if (status !== OrderStatus.DELIVERED) {
      throw new BadRequestException(
        `El ${SUPPORT_TYPE_LABEL[type].toLowerCase()} solo aplica cuando el pedido ya fue entregado.`,
      );
    }
  }
}
