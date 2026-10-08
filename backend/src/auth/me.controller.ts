import { Controller, Get, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from './current-user.decorator.js';

@Controller('me')
export class MeController {
  @Get()
  @UseGuards(AuthGuard('jwt'))
  getCurrentUser(@CurrentUser() user: unknown) {
    return user;
  }
}
