import { Transform } from 'class-transformer';
import { IsEnum, IsInt, IsNumberString, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

enum ProductSort {
  NEWEST = 'newest',
  PRICE_ASC = 'price_asc',
  PRICE_DESC = 'price_desc',
}

export class ProductQueryDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  q?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsString()
  sizeSystem?: string;

  @IsOptional()
  @IsNumberString()
  minPrice?: string;

  @IsOptional()
  @IsNumberString()
  maxPrice?: string;

  @IsOptional()
  @IsEnum(ProductSort)
  sort: ProductSort = ProductSort.NEWEST;

  @IsOptional()
  @Transform(({ value }) => (value === undefined ? value : Number(value)))
  @IsInt()
  @Min(1)
  page = 1;

  @IsOptional()
  @Transform(({ value }) => (value === undefined ? value : Number(value)))
  @IsInt()
  @Min(1)
  @Max(50)
  limit = 20;
}
