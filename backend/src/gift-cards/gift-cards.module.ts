import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module.js';
import { GiftCardsController } from './gift-cards.controller.js';
import { GiftCardsService } from './gift-cards.service.js';

@Module({
  imports: [DatabaseModule],
  controllers: [GiftCardsController],
  providers: [GiftCardsService],
})
export class GiftCardsModule {}
