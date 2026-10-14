import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class SaveAddressDto {
  @Transform(trim)
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  label!: string;

  @Transform(trim)
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  recipient!: string;

  @Transform(trim)
  @IsString()
  @MinLength(5)
  @MaxLength(180)
  line1!: string;

  @Transform(trim)
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  district!: string;

  @Transform(trim)
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  province!: string;

  @Transform(trim)
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  department!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(180)
  reference?: string;

  @IsOptional()
  @Transform(trim)
  @Matches(/^9\d{8}$/)
  phone?: string;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
