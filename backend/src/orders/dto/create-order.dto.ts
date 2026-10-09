import { PaymentMethod } from '@prisma/client';
import { IsEnum, IsOptional, IsUUID } from 'class-validator';

export class CreateOrderDto {
  @IsEnum(PaymentMethod)
  paymentMethod!: PaymentMethod;

  /** Si se omite, se usa la dirección predeterminada del usuario (si tiene). */
  @IsOptional()
  @IsUUID()
  addressId?: string;
}
