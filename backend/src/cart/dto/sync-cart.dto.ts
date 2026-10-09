import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsInt, IsUUID, Max, Min, ValidateNested } from 'class-validator';

export class SyncCartItemDto {
  @IsUUID()
  variantId!: string;

  @IsInt()
  @Min(1)
  @Max(20)
  quantity!: number;
}

export class SyncCartDto {
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => SyncCartItemDto)
  items!: SyncCartItemDto[];
}
