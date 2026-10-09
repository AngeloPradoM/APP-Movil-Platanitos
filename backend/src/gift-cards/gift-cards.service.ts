import { Injectable } from '@nestjs/common';
import { GiftCard, Prisma } from '@prisma/client';
import { randomBytes } from 'node:crypto';
import { PrismaService } from '../database/prisma.service.js';
import { CreateGiftCardDto } from './dto/create-gift-card.dto.js';

function mapGiftCard(card: GiftCard) {
  return {
    id: card.id,
    code: card.code,
    amount: card.amount.toFixed(2),
    recipientName: card.recipientName,
    recipientEmail: card.recipientEmail,
    message: card.message,
    createdAt: card.createdAt,
  };
}

@Injectable()
export class GiftCardsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Emisión simulada: no hay cobro ni envío real de correo. */
  async create(userId: string, input: CreateGiftCardDto) {
    const hex = randomBytes(4).toString('hex').toUpperCase();
    const card = await this.prisma.giftCard.create({
      data: {
        purchaserId: userId,
        code: `GC-${hex.slice(0, 4)}-${hex.slice(4)}`,
        amount: new Prisma.Decimal(input.amount),
        recipientName: input.recipientName,
        recipientEmail: input.recipientEmail,
        message: input.message || null,
      },
    });
    return mapGiftCard(card);
  }

  async list(userId: string) {
    const cards = await this.prisma.giftCard.findMany({
      where: { purchaserId: userId },
      orderBy: { createdAt: 'desc' },
    });
    return cards.map(mapGiftCard);
  }
}
