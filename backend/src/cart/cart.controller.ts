import { Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { AddCartItemDto } from './dto/add-cart-item.dto.js';
import { UpdateCartItemDto } from './dto/update-cart-item.dto.js';
import { CartService } from './cart.service.js';

@Controller('cart')
@UseGuards(AuthGuard('jwt'))
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get()
  getCart(@CurrentUser() user: { id: string }) {
    return this.cartService.getCart(user.id);
  }

  @Post('items')
  addItem(@CurrentUser() user: { id: string }, @Body() input: AddCartItemDto) {
    return this.cartService.addItem(user.id, input);
  }

  @Patch('items/:itemId')
  updateItem(@CurrentUser() user: { id: string }, @Param('itemId', ParseUUIDPipe) itemId: string, @Body() input: UpdateCartItemDto) {
    return this.cartService.updateItem(user.id, itemId, input);
  }

  @Delete('items/:itemId')
  removeItem(@CurrentUser() user: { id: string }, @Param('itemId', ParseUUIDPipe) itemId: string) {
    return this.cartService.removeItem(user.id, itemId);
  }
}
