import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module.js';
import { AddressesController } from './addresses.controller.js';
import { AddressesService } from './addresses.service.js';

@Module({
  imports: [DatabaseModule],
  controllers: [AddressesController],
  providers: [AddressesService],
})
export class AddressesModule {}
