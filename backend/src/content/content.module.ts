import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module.js';
import { ContentController } from './content.controller.js';
import { ContentService } from './content.service.js';

@Module({
  imports: [DatabaseModule],
  controllers: [ContentController],
  providers: [ContentService],
})
export class ContentModule {}
