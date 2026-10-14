import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getInfo() {
    return { service: 'platanitos-backend', status: 'ok', health: '/health' };
  }
}
