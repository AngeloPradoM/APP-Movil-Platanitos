import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomBytes, createHash } from 'node:crypto';
import * as argon2 from 'argon2';
import { PrismaService } from '../database/prisma.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';

type SafeUser = {
  id: string;
  email: string;
  name: string;
  documentType: string | null;
  documentNumber: string | null;
  phone: string | null;
};

@Injectable()
export class AuthService {
  private readonly refreshDays: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    config: ConfigService,
  ) {
    this.refreshDays = Number(config.get<string>('JWT_REFRESH_TTL_DAYS', '30'));
  }

  async register(input: RegisterDto) {
    const email = input.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('No se pudo crear la cuenta.');

    const passwordHash = await argon2.hash(input.password, {
      type: argon2.argon2id,
      memoryCost: 19_456,
      timeCost: 2,
      parallelism: 1,
    });

    const user = await this.prisma.user.create({
      data: {
        email,
        name: input.name.trim(),
        documentType: input.documentType?.trim(),
        documentNumber: input.documentNumber?.trim(),
        phone: input.phone?.trim(),
        passwordCredential: { create: { passwordHash } },
      },
    });

    return this.issueTokens(this.toSafeUser(user));
  }

  async login(input: LoginDto) {
    const email = input.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { passwordCredential: true },
    });
    const valid = user?.isActive && user.passwordCredential
      ? await argon2.verify(user.passwordCredential.passwordHash, input.password)
      : false;
    if (!valid || !user) {
      throw new UnauthorizedException('Correo o contraseña inválidos.');
    }

    return this.issueTokens(this.toSafeUser(user));
  }

  async refresh(refreshToken: string) {
    const tokenHash = this.hashToken(refreshToken);
    const session = await this.prisma.refreshSession.findUnique({
      where: { tokenHash },
      include: { user: true },
    });
    if (
      !session ||
      session.revokedAt ||
      session.expiresAt <= new Date() ||
      !session.user.isActive
    ) {
      throw new UnauthorizedException('Sesión inválida o expirada.');
    }

    await this.prisma.refreshSession.update({
      where: { id: session.id },
      data: { revokedAt: new Date(), lastUsedAt: new Date() },
    });
    return this.issueTokens(this.toSafeUser(session.user));
  }

  async logout(refreshToken: string): Promise<void> {
    await this.prisma.refreshSession.updateMany({
      where: { tokenHash: this.hashToken(refreshToken), revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async issueTokens(user: SafeUser) {
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      email: user.email,
    });
    const refreshToken = randomBytes(64).toString('base64url');
    const expiresAt = new Date(
      Date.now() + this.refreshDays * 24 * 60 * 60 * 1000,
    );

    await this.prisma.refreshSession.create({
      data: { userId: user.id, tokenHash: this.hashToken(refreshToken), expiresAt },
    });

    return { user, accessToken, refreshToken, refreshExpiresAt: expiresAt };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private toSafeUser(user: {
    id: string;
    email: string;
    name: string;
    documentType: string | null;
    documentNumber: string | null;
    phone: string | null;
  }): SafeUser {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      documentType: user.documentType,
      documentNumber: user.documentNumber,
      phone: user.phone,
    };
  }
}
