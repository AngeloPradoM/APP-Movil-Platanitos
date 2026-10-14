import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module.js';
import { AuthModule } from '../auth/auth.module.js';
import { AdminController } from './admin.controller.js';
@Module({ imports: [DatabaseModule, AuthModule], controllers: [AdminController] })
export class AdministrationModule {}
