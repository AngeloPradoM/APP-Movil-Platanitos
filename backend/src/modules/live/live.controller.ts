import { Controller, Get, Sse, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { LiveService } from './live.service.js';

@Controller('live')
@UseGuards(AuthGuard('jwt'))
export class LiveController {
  constructor(private readonly live: LiveService) {}

  @Get('head')
  head() {
    return this.live.head();
  }

  @Sse('stream')
  stream(@CurrentUser() user: { id: string; role: string }) {
    return this.live.stream(user);
  }
}
