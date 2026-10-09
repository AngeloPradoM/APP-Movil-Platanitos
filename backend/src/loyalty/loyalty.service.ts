import { BadRequestException, Injectable } from '@nestjs/common';
import { LoyaltyEntryType, OrderStatus, Prisma } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../database/prisma.service.js';

export const POINTS_PER_REDEMPTION = 100;
export const REDEMPTION_VALUE = new Prisma.Decimal('5.00');
export const RECYCLING_BONUS = 50;
const RECYCLING_COOLDOWN_MS = 24 * 60 * 60 * 1000;

const LEVELS = [
  { level: 'GOLD', label: 'Oro', minPoints: 1000 },
  { level: 'SILVER', label: 'Plata', minPoints: 300 },
  { level: 'CLASSIC', label: 'Clásica', minPoints: 0 },
] as const;

type Client = Prisma.TransactionClient | PrismaService;

@Injectable()
export class LoyaltyService {
  constructor(private readonly prisma: PrismaService) {}

  async summary(userId: string) {
    const [balances, movements] = await Promise.all([
      this.balances(this.prisma, userId),
      this.prisma.loyaltyEntry.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
    ]);
    const level = LEVELS.find((entry) => balances.lifetimePoints >= entry.minPoints)!;
    return {
      points: balances.points,
      lifetimePoints: balances.lifetimePoints,
      membership: { level: level.level, label: level.label },
      walletBalance: balances.walletBalance.toFixed(2),
      movements: movements.map((entry) => ({
        id: entry.id,
        type: entry.type,
        points: entry.points,
        walletAmount: entry.walletAmount.toFixed(2),
        description: entry.description,
        createdAt: entry.createdAt,
      })),
    };
  }

  async redeem(userId: string) {
    await this.prisma.$transaction(
      async (transaction) => {
        const { points } = await this.balances(transaction, userId);
        const blocks = Math.floor(points / POINTS_PER_REDEMPTION);
        if (blocks === 0) {
          throw new BadRequestException(`Necesitas al menos ${POINTS_PER_REDEMPTION} puntos para canjear.`);
        }
        const redeemed = blocks * POINTS_PER_REDEMPTION;
        await transaction.loyaltyEntry.create({
          data: {
            userId,
            type: LoyaltyEntryType.REDEMPTION,
            points: -redeemed,
            walletAmount: REDEMPTION_VALUE.mul(blocks),
            description: `Canje de ${redeemed} puntos`,
          },
        });
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
    return this.summary(userId);
  }

  async registerRecycling(userId: string) {
    const recent = await this.prisma.loyaltyEntry.findFirst({
      where: {
        userId,
        type: LoyaltyEntryType.RECYCLING_BONUS,
        createdAt: { gte: new Date(Date.now() - RECYCLING_COOLDOWN_MS) },
      },
      select: { id: true },
    });
    if (recent) throw new BadRequestException('Ya generaste un código Resikla hoy. Vuelve mañana.');
    const code = `RSK-${randomInt(100_000, 999_999)}`;
    await this.prisma.loyaltyEntry.create({
      data: {
        userId,
        type: LoyaltyEntryType.RECYCLING_BONUS,
        points: RECYCLING_BONUS,
        description: 'Bono Resikla',
        reference: code,
      },
    });
    return { code, points: RECYCLING_BONUS, summary: await this.summary(userId) };
  }

  private async balances(client: Client, userId: string) {
    const orders = await client.order.findMany({
      where: { userId, status: { not: OrderStatus.CANCELLED } },
      select: { total: true },
    });
    const earnedEntries = await client.loyaltyEntry.aggregate({
      where: { userId, points: { gt: 0 } },
      _sum: { points: true },
    });
    const allEntries = await client.loyaltyEntry.aggregate({
      where: { userId },
      _sum: { points: true, walletAmount: true },
    });
    const purchasePoints = orders.reduce((sum, order) => sum + Math.floor(Number(order.total)), 0);
    return {
      lifetimePoints: purchasePoints + (earnedEntries._sum.points ?? 0),
      points: purchasePoints + (allEntries._sum.points ?? 0),
      walletBalance: allEntries._sum.walletAmount ?? new Prisma.Decimal(0),
    };
  }
}
