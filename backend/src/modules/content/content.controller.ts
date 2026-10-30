import { Controller, Get, Param } from '@nestjs/common';
import { ContentService } from './content.service.js';

@Controller('content')
export class ContentController {
  constructor(private readonly contentService: ContentService) {}

  @Get('stores')
  listStores() {
    return this.contentService.listStores();
  }

  @Get('blog')
  listPosts() {
    return this.contentService.listPosts();
  }

  @Get('blog/:slug')
  getPost(@Param('slug') slug: string) {
    return this.contentService.getPost(slug);
  }
}
