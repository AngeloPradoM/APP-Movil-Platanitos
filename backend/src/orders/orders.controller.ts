import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto.js';
import { OrdersService } from './orders.service.js';

@Controller('orders')
@UseGuards(AuthGuard('jwt'))
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() input: CreateOrderDto) {
    return this.ordersService.create(user.id, input);
  }

  @Get()
  list(@CurrentUser() user: { id: string }) {
    return this.ordersService.list(user.id);
  }

  @Get(':publicNumber')
  get(@CurrentUser() user: { id: string }, @Param('publicNumber') publicNumber: string) {
    return this.ordersService.get(user.id, publicNumber);
  }

  @Patch(':publicNumber/status')
  updateStatus(
    @CurrentUser() user: { id: string },
    @Param('publicNumber') publicNumber: string,
    @Body() input: UpdateOrderStatusDto,
  ) {
    return this.ordersService.updateStatus(user.id, publicNumber, input);
  }
}
