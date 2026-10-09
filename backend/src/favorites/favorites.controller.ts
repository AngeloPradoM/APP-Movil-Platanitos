import { Controller, Delete, Get, Param, ParseUUIDPipe, Put, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { FavoritesService } from './favorites.service.js';

@Controller('favorites')
@UseGuards(AuthGuard('jwt'))
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  list(@CurrentUser() user: { id: string }) {
    return this.favoritesService.list(user.id);
  }

  @Put(':productId')
  add(@CurrentUser() user: { id: string }, @Param('productId', ParseUUIDPipe) productId: string) {
    return this.favoritesService.add(user.id, productId);
  }

  @Delete(':productId')
  remove(@CurrentUser() user: { id: string }, @Param('productId', ParseUUIDPipe) productId: string) {
    return this.favoritesService.remove(user.id, productId);
  }
}
