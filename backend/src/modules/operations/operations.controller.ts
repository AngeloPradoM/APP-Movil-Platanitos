import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { assertWarehouseStaff } from '../inventory/inventory.service.js';
import { OperationsService } from './operations.service.js';

class DeliveryProofDto {
  @IsString()
  @MaxLength(120)
  recipientName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(20000)
  signatureData?: string;

  @IsOptional()
  @IsString()
  @MaxLength(700000)
  photo?: string;
}

class CreateSupportTicketDto {
  @IsString()
  @MaxLength(32)
  publicNumber!: string;

  @IsString()
  @IsIn(['CHANGE', 'RETURN', 'CLAIM'])
  type!: string;

  @IsString()
  @MinLength(10)
  @MaxLength(2000)
  reason!: string;
}

class UpdateSupportTicketDto {
  @IsString()
  @IsIn(['REGISTERED', 'IN_REVIEW', 'RESOLVED', 'REJECTED', 'OPEN', 'IN_PROGRESS', 'CLOSED'])
  status!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}

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

  @Get('deliveries')
  deliveries(@CurrentUser() user: { role: string }) {
    this.allowDriver(user.role);
    return this.operations.deliveries();
  }

  @Get('deliveries/history')
  deliveryHistory(@CurrentUser() user: { id: string; role: string }) {
    this.allowDriver(user.role);
    return this.operations.deliveryHistory(user);
  }

  @Get('deliveries/:orderId/evidence')
  evidence(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allowDriver(user.role);
    return this.operations.deliveryEvidence(orderId);
  }

  @Post('deliveries/:orderId/pickup')
  pickup(@CurrentUser() user: { role: string }, @Param('orderId', ParseUUIDPipe) orderId: string) {
    this.allowDriver(user.role);
    return this.operations.markInTransit(orderId);
  }

  @Post('deliveries/:orderId/deliver')
  complete(
    @CurrentUser() user: { id: string; role: string },
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() body: DeliveryProofDto,
  ) {
    this.allowDriver(user.role);
    return this.operations.markDelivered(orderId, body, user.id);
  }

  @Get('support')
  supportList(@CurrentUser() user: { id: string; role: string }) {
    this.allowSupportRead(user.role);
    return this.operations.supportTickets(user);
  }

  @Post('support')
  supportCreate(
    @CurrentUser() user: { id: string; role: string },
    @Body() body: CreateSupportTicketDto,
  ) {
    return this.operations.createSupportTicket(user, body);
  }

  @Patch('support/:ticketId')
  supportUpdate(
    @CurrentUser() user: { id: string; role: string },
    @Param('ticketId', ParseUUIDPipe) ticketId: string,
    @Body() body: UpdateSupportTicketDto,
  ) {
    return this.operations.updateSupportTicket(user, ticketId, body);
  }

  private allowDriver(role: string) {
    if (role === 'REPARTIDOR' || role === 'ADMINISTRADOR') return;
    throw new ForbiddenException('Acceso exclusivo para repartidores.');
  }

  private allowSupportRead(role: string) {
    if (
      role === 'CLIENTE' ||
      role === 'ATENCION_CLIENTE' ||
      role === 'ADMINISTRADOR'
    ) {
      return;
    }
    throw new ForbiddenException('Sin acceso a solicitudes de soporte.');
  }

  private allow(role: string) {
    try {
      assertWarehouseStaff(role);
    } catch {
      throw new ForbiddenException('Acceso exclusivo para almacén y administración.');
    }
  }
}
