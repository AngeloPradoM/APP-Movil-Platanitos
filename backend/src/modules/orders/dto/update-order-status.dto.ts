import { OrderStatus } from '@prisma/client';
import { IsIn } from 'class-validator';

export class UpdateOrderStatusDto {
  @IsIn([OrderStatus.DISPATCH, OrderStatus.TRANSIT, OrderStatus.DELIVERED])
  status!: OrderStatus;
}
