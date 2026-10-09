import { PaymentMethod } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class CreateOrderDto {
  @IsEnum(PaymentMethod)
  paymentMethod!: PaymentMethod;
}
