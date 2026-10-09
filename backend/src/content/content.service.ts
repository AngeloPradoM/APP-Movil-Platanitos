import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service.js';

const storeSelect = { slug: true, name: true, district: true, address: true, hours: true };
const postSelect = {
  slug: true,
  title: true,
  category: true,
  summary: true,
  body: true,
  imageUrl: true,
  readMinutes: true,
  publishedAt: true,
};

@Injectable()
export class ContentService {
  constructor(private readonly prisma: PrismaService) {}

  listStores() {
    return this.prisma.store.findMany({
      where: { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      select: storeSelect,
    });
  }

  listPosts() {
    return this.prisma.blogPost.findMany({
      where: { isPublished: true, publishedAt: { lte: new Date() } },
      orderBy: { publishedAt: 'desc' },
      select: postSelect,
    });
  }

  async getPost(slug: string) {
    const post = await this.prisma.blogPost.findFirst({
      where: { slug, isPublished: true, publishedAt: { lte: new Date() } },
      select: postSelect,
    });
    if (!post) throw new NotFoundException('Artículo no encontrado');
    return post;
  }
}
