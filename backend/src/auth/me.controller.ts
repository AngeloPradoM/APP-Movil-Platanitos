import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from './current-user.decorator.js';
import { AuthService } from './auth.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Controller('me')
@UseGuards(AuthGuard('jwt'))
export class MeController {
  constructor(private readonly authService: AuthService) {}

  @Get()
  getCurrentUser(@CurrentUser() user: unknown) {
    return user;
  }

  @Patch()
  updateProfile(@CurrentUser() user: { id: string }, @Body() input: UpdateProfileDto) {
    return this.authService.updateProfile(user.id, input);
  }
}
