import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module.js';
import { LiveModule } from '../live/live.module.js';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';

@Module({
  imports: [DatabaseModule, LiveModule],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
