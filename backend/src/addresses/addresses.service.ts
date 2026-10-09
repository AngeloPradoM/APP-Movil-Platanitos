import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service.js';
import { SaveAddressDto } from './dto/save-address.dto.js';

export const MAX_ADDRESSES = 10;

const addressSelect = {
  id: true,
  label: true,
  recipient: true,
  line1: true,
  district: true,
  province: true,
  department: true,
  reference: true,
  phone: true,
  isDefault: true,
};

@Injectable()
export class AddressesService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.address.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
      select: addressSelect,
    });
  }

  async create(userId: string, input: SaveAddressDto) {
    const count = await this.prisma.address.count({ where: { userId } });
    if (count >= MAX_ADDRESSES) {
      throw new BadRequestException(`Puedes guardar hasta ${MAX_ADDRESSES} direcciones`);
    }
    const isDefault = count === 0 || input.isDefault === true;
    await this.prisma.$transaction(async (transaction) => {
      if (isDefault) {
        await transaction.address.updateMany({ where: { userId }, data: { isDefault: false } });
      }
      await transaction.address.create({ data: { ...this.fields(input), userId, isDefault } });
    });
    return this.list(userId);
  }

  async update(userId: string, id: string, input: SaveAddressDto) {
    const current = await this.find(userId, id);
    const isDefault = current.isDefault || input.isDefault === true;
    await this.prisma.$transaction(async (transaction) => {
      if (isDefault && !current.isDefault) {
        await transaction.address.updateMany({ where: { userId }, data: { isDefault: false } });
      }
      await transaction.address.update({ where: { id }, data: { ...this.fields(input), isDefault } });
    });
    return this.list(userId);
  }

  async remove(userId: string, id: string) {
    const current = await this.find(userId, id);
    await this.prisma.$transaction(async (transaction) => {
      await transaction.address.delete({ where: { id } });
      if (!current.isDefault) return;
      const next = await transaction.address.findFirst({
        where: { userId },
        orderBy: { createdAt: 'asc' },
        select: { id: true },
      });
      if (next) await transaction.address.update({ where: { id: next.id }, data: { isDefault: true } });
    });
    return this.list(userId);
  }

  private async find(userId: string, id: string) {
    const address = await this.prisma.address.findFirst({ where: { id, userId }, select: { isDefault: true } });
    if (!address) throw new NotFoundException('Dirección no encontrada');
    return address;
  }

  private fields(input: SaveAddressDto) {
    return {
      label: input.label,
      recipient: input.recipient,
      line1: input.line1,
      district: input.district,
      province: input.province,
      department: input.department,
      reference: input.reference || null,
      phone: input.phone || null,
    };
  }
}
