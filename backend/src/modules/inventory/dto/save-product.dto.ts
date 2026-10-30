import { SizeSystem } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class ProductImageInput {
  @IsString()
  @MaxLength(2048)
  url!: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  altText?: string;
}

export class ProductVariantInput {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsEnum(SizeSystem)
  sizeSystem!: SizeSystem;

  @IsString()
  @MaxLength(16)
  sizeValue!: string;

  @IsString()
  @MaxLength(40)
  color!: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  price!: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  comparePrice?: number;

  @IsInt()
  @Min(0)
  stock!: number;
}

export class SaveProductDto {
  @IsString()
  @MaxLength(160)
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsUUID()
  categoryId!: string;

  @IsUUID()
  brandId!: string;

  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ProductImageInput)
  images!: ProductImageInput[];

  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ProductVariantInput)
  variants!: ProductVariantInput[];
}
