import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, SizeSystem } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../../database/prisma.service.js';
import { SaveProductDto } from './dto/save-product.dto.js';

const SIZE_RANK = ['EUR', 'US', 'CM', 'ALPHA', 'ONE_SIZE'];

function slugify(value: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 160);
}

function orderedVariants(variants: SaveProductDto['variants']) {
  return [...variants].sort((a, b) => {
    const system = SIZE_RANK.indexOf(a.sizeSystem) - SIZE_RANK.indexOf(b.sizeSystem);
    if (system !== 0) return system;
    return a.sizeValue.localeCompare(b.sizeValue, 'es', { numeric: true })
      || a.color.localeCompare(b.color, 'es');
  });
}

@Injectable()
export class ProductEditorService {
  constructor(private readonly prisma: PrismaService) {}

  brands() {
    return this.prisma.brand.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
      select: { id: true, name: true, slug: true },
    });
  }

  async getProduct(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        images: { orderBy: { sortOrder: 'asc' } },
        variants: {
          where: { isActive: true },
          orderBy: [{ sizeSystem: 'asc' }, { sizeValue: 'asc' }, { color: 'asc' }],
        },
      },
    });
    if (!product) throw new NotFoundException('Producto no encontrado');
    return {
      id: product.id,
      name: product.name,
      description: product.description,
      categoryId: product.categoryId,
      brandId: product.brandId,
      images: product.images.map((image) => ({
        url: image.url,
        altText: image.altText,
        sortOrder: image.sortOrder,
      })),
      variants: product.variants.map((variant) => ({
        id: variant.id,
        sizeSystem: variant.sizeSystem,
        sizeValue: variant.sizeValue,
        color: variant.color,
        price: variant.price.toString(),
        comparePrice: variant.comparePrice?.toString() ?? null,
        stock: variant.stock,
      })),
    };
  }

  create(input: SaveProductDto) {
    return this.write(null, input);
  }

  update(id: string, input: SaveProductDto) {
    return this.write(id, input);
  }

  private async write(id: string | null, input: SaveProductDto) {
    const category = await this.prisma.category.findUnique({ where: { id: input.categoryId } });
    const brand = await this.prisma.brand.findUnique({ where: { id: input.brandId } });
    if (!category || !brand) throw new BadRequestException('Elige una categoría y una marca existentes.');
    const images = input.images
      .map((image) => ({ url: image.url.trim(), altText: image.altText?.trim() || input.name.trim() }))
      .filter((image) => image.url.length > 0);
    if (images.length === 0) throw new BadRequestException('Agrega al menos una foto.');
    const variants = orderedVariants(input.variants);
    const slug = await this.uniqueSlug(slugify(input.name) || 'producto', id);

    const savedId = await this.prisma.$transaction(async (transaction) => {
      const product = id
        ? await transaction.product.update({
            where: { id },
            data: {
              name: input.name.trim(),
              description: input.description?.trim() || null,
              categoryId: category.id,
              brandId: brand.id,
            },
          })
        : await transaction.product.create({
            data: {
              name: input.name.trim(),
              slug,
              description: input.description?.trim() || null,
              categoryId: category.id,
              brandId: brand.id,
            },
          });
      if (!product) throw new NotFoundException('Producto no encontrado');

      await transaction.productImage.deleteMany({ where: { productId: product.id } });
      await transaction.productImage.createMany({
        data: images.map((image, sortOrder) => ({
          productId: product.id,
          url: image.url,
          altText: image.altText,
          sortOrder,
        })),
      });

      const kept: string[] = [];
      for (const variant of variants) {
        const data = {
          sizeSystem: variant.sizeSystem as SizeSystem,
          sizeValue: variant.sizeValue.trim(),
          color: variant.color.trim(),
          price: new Prisma.Decimal(variant.price.toFixed(2)),
          comparePrice: variant.comparePrice == null ? null : new Prisma.Decimal(variant.comparePrice.toFixed(2)),
          stock: variant.stock,
          isActive: true,
        };
        if (variant.id) {
          await transaction.productVariant.update({ where: { id: variant.id }, data });
          kept.push(variant.id);
        } else {
          const created = await transaction.productVariant.create({
            data: {
              ...data,
              productId: product.id,
              sku: `PLT-${randomInt(100000, 999999)}-${variant.sizeValue.replace(/[^A-Za-z0-9]/g, '').slice(0, 12) || 'T'}`,
            },
          });
          kept.push(created.id);
        }
      }
      await transaction.productVariant.updateMany({
        where: { productId: product.id, id: { notIn: kept } },
        data: { isActive: false },
      });
      return product.id;
    });
    return this.getProduct(savedId);
  }

  private async uniqueSlug(base: string, currentId: string | null) {
    let slug = base;
    let sequence = 2;
    while (true) {
      const existing = await this.prisma.product.findUnique({ where: { slug }, select: { id: true } });
      if (!existing || existing.id === currentId) return slug;
      slug = `${base}-${sequence++}`;
    }
  }
}
