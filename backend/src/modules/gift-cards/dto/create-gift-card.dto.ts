import { Transform } from 'class-transformer';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export const GIFT_CARD_AMOUNTS = [50, 100, 150, 200];

export class CreateGiftCardDto {
  @IsIn(GIFT_CARD_AMOUNTS)
  amount!: number;

  @Transform(({ value }) => String(value).trim())
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  recipientName!: string;

  @Transform(({ value }) => String(value).trim().toLowerCase())
  @IsEmail()
  @MaxLength(254)
  recipientEmail!: string;

  @IsOptional()
  @Transform(({ value }) => String(value).trim())
  @IsString()
  @MaxLength(120)
  message?: string;
}
