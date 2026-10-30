import { AdministrationModule } from './modules/administration/administration.module.js';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { HealthModule } from './modules/health/health.module.js';
import { DatabaseModule } from './database/database.module.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { CatalogModule } from './modules/catalog/catalog.module.js';
import { CartModule } from './modules/cart/cart.module.js';
import { FavoritesModule } from './modules/favorites/favorites.module.js';
import { OrdersModule } from './modules/orders/orders.module.js';
import { LoyaltyModule } from './modules/loyalty/loyalty.module.js';
import { GiftCardsModule } from './modules/gift-cards/gift-cards.module.js';
import { ContentModule } from './modules/content/content.module.js';
import { AddressesModule } from './modules/addresses/addresses.module.js';
import { InventoryModule } from './modules/inventory/inventory.module.js';
import { OperationsModule } from './modules/operations/operations.module.js';
import { LiveModule } from './modules/live/live.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 60 }]),
    DatabaseModule,
    HealthModule,
    AuthModule,
    AdministrationModule,
    CatalogModule,
    CartModule,
    FavoritesModule,
    OrdersModule,
    LoyaltyModule,
    GiftCardsModule,
    ContentModule,
    AddressesModule,
    InventoryModule,
    OperationsModule,
    LiveModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
