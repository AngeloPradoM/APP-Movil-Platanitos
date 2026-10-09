import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { HealthController } from './health.controller.js';
import { DatabaseModule } from './database/database.module.js';
import { AuthModule } from './auth/auth.module.js';
import { CatalogModule } from './catalog/catalog.module.js';
import { CartModule } from './cart/cart.module.js';
import { FavoritesModule } from './favorites/favorites.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { LoyaltyModule } from './loyalty/loyalty.module.js';
import { GiftCardsModule } from './gift-cards/gift-cards.module.js';
import { ContentModule } from './content/content.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 60 }]),
    DatabaseModule,
    AuthModule,
    CatalogModule,
    CartModule,
    FavoritesModule,
    OrdersModule,
    LoyaltyModule,
    GiftCardsModule,
    ContentModule,
  ],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
