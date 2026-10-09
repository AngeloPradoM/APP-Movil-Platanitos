import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CreateGiftCardDto } from './dto/create-gift-card.dto.js';
import { GiftCardsService } from './gift-cards.service.js';

@Controller('gift-cards')
@UseGuards(AuthGuard('jwt'))
export class GiftCardsController {
  constructor(private readonly giftCardsService: GiftCardsService) {}

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() input: CreateGiftCardDto) {
    return this.giftCardsService.create(user.id, input);
  }

  @Get()
  list(@CurrentUser() user: { id: string }) {
    return this.giftCardsService.list(user.id);
  }
}
