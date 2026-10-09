import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { LoyaltyService } from './loyalty.service.js';

@Controller('loyalty')
@UseGuards(AuthGuard('jwt'))
export class LoyaltyController {
  constructor(private readonly loyaltyService: LoyaltyService) {}

  @Get()
  summary(@CurrentUser() user: { id: string }) {
    return this.loyaltyService.summary(user.id);
  }

  @Post('redeem')
  redeem(@CurrentUser() user: { id: string }) {
    return this.loyaltyService.redeem(user.id);
  }

  @Post('recycling')
  registerRecycling(@CurrentUser() user: { id: string }) {
    return this.loyaltyService.registerRecycling(user.id);
  }
}
