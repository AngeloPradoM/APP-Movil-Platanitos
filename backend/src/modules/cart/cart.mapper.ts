import { Prisma } from '@prisma/client';

type CartWithItems = Prisma.CartGetPayload<{
  include: {
    items: {
      include: {
        variant: { include: { product: { select: { name: true; slug: true } } } };
      };
    };
  };
}>;

export function mapCart(cart: CartWithItems | { id: null; status: string; items: never[] }) {
  if (cart.id === null) {
    return { id: null, status: cart.status, items: [], subtotal: '0.00', itemCount: 0 };
  }

  let subtotal = new Prisma.Decimal(0);
  let itemCount = 0;
  const items = cart.items.map((item) => {
    const lineSubtotal = item.variant.price.mul(item.quantity);
    subtotal = subtotal.add(lineSubtotal);
    itemCount += item.quantity;
    return {
      id: item.id,
      quantity: item.quantity,
      variant: {
        id: item.variant.id,
        sku: item.variant.sku,
        sizeSystem: item.variant.sizeSystem,
        sizeValue: item.variant.sizeValue,
        color: item.variant.color,
        price: item.variant.price.toString(),
        stock: item.variant.stock,
        product: item.variant.product,
      },
      subtotal: lineSubtotal.toString(),
    };
  });

  return { id: cart.id, status: cart.status, items, subtotal: subtotal.toString(), itemCount };
}
