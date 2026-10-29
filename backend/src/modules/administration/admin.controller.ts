import { Controller, ForbiddenException, Get, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { PrismaService } from '../../database/prisma.service.js';

@Controller('admin')
@UseGuards(AuthGuard('jwt'))
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('users')
  async users(@CurrentUser() user: { role: UserRole }) {
    if (user.role !== UserRole.ADMINISTRADOR) {
      throw new ForbiddenException('Acceso exclusivo para administradores.');
    }
    return this.prisma.user.findMany({
      select: { id: true, name: true, email: true, role: true, isActive: true },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }
}
