import { Prisma } from '@prisma/client';

export const orderInclude = {
  items: {
    orderBy: { productName: 'asc' as const },
    include: {
      variant: {
        select: {
          product: {
            select: {
              slug: true,
              images: { orderBy: { sortOrder: 'asc' as const }, take: 1, select: { url: true } },
            },
          },
        },
      },
    },
  },
  statusHistory: { orderBy: { createdAt: 'asc' as const } },
  addressSnapshot: true,
} satisfies Prisma.OrderInclude;

type OrderWithRelations = Prisma.OrderGetPayload<{ include: typeof orderInclude }>;

export function mapOrder(order: OrderWithRelations) {
  return {
    id: order.id,
    publicNumber: order.publicNumber,
    status: order.status,
    paymentMethod: order.paymentMethod,
    subtotal: order.subtotal.toString(),
    shipping: order.shipping.toString(),
    total: order.total.toString(),
    currency: order.currency,
    estimatedFrom: order.estimatedFrom,
    estimatedTo: order.estimatedTo,
    createdAt: order.createdAt,
    address: order.addressSnapshot
      ? {
          recipient: order.addressSnapshot.recipient,
          line1: order.addressSnapshot.line1,
          district: order.addressSnapshot.district,
          province: order.addressSnapshot.province,
          department: order.addressSnapshot.department,
          reference: order.addressSnapshot.reference,
          phone: order.addressSnapshot.phone,
        }
      : null,
    items: order.items.map((item) => ({
      id: item.id,
      variantId: item.variantId,
      productName: item.productName,
      productSlug: item.variant?.product.slug ?? null,
      image: item.variant?.product.images[0]?.url ?? null,
      sku: item.sku,
      sizeSystem: item.sizeSystem,
      sizeValue: item.sizeValue,
      color: item.color,
      quantity: item.quantity,
      unitPrice: item.unitPrice.toString(),
      subtotal: item.subtotal.toString(),
    })),
    statusHistory: order.statusHistory.map((entry) => ({
      status: entry.status,
      note: entry.note,
      createdAt: entry.createdAt,
    })),
  };
}
