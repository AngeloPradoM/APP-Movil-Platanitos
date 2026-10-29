import { Controller, ForbiddenException, Get, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { assertWarehouseStaff } from '../inventory/inventory.service.js';
import { OperationsService } from './operations.service.js';

@Controller('operations')
@UseGuards(AuthGuard('jwt'))
export class OperationsController {
  constructor(private readonly operations: OperationsService) {}

  @Get('report')
  report(@CurrentUser() user: { role: string }) {
    this.allow(user.role);
    return this.operations.report();
  }

  @Get('fulfillment')
  fulfillment(@CurrentUser() user: { role: string }) {
    this.allow(user.role);
    return this.operations.fulfillmentTasks();
  }

  @Post('fulfillment/:orderId/start')
  start(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allow(user.role);
    return this.operations.startPreparation(orderId);
  }

  @Post('fulfillment/:orderId/ready')
  ready(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allow(user.role);
    return this.operations.markPrepared(orderId);
  }

  @Post('fulfillment/:orderId/dispatch')
  dispatch(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allow(user.role);
    return this.operations.dispatch(orderId);
  }

  @Post('fulfillment/:orderId/transit')
  transit(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allow(user.role);
    return this.operations.markInTransit(orderId);
  }

  @Post('fulfillment/:orderId/deliver')
  deliver(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allow(user.role);
    return this.operations.markDelivered(orderId);
  }

  private allow(role: string) {
    try {
      assertWarehouseStaff(role);
    } catch {
      throw new ForbiddenException('Acceso exclusivo para almacén y administración.');
    }
  }
}
