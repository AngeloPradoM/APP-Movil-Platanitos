import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { IsBoolean, IsIn, IsInt, IsNumber, IsString, MaxLength, Min } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { SaveProductDto } from './dto/save-product.dto.js';
import { InventoryService, assertWarehouseStaff } from './inventory.service.js';
import { ProductEditorService } from './product-editor.service.js';

class StockMovementDto {
  @IsIn(['entry', 'exit', 'adjustment'])
  type!: 'entry' | 'exit' | 'adjustment';

  @IsInt()
  @Min(0)
  quantity!: number;

  @IsString()
  @MaxLength(120)
  reason!: string;
}

class UpdatePriceDto {
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  price!: number;
}

class UpdateCategoryDto {
  @IsBoolean()
  isActive!: boolean;
}

@Controller('inventory')
@UseGuards(AuthGuard('jwt'))
export class InventoryController {
  constructor(
    private readonly inventory: InventoryService,
    private readonly editor: ProductEditorService,
  ) {}

  @Get()
  list(
    @CurrentUser() user: { role: string },
    @Query('q') query = '',
    @Query('lowStock') lowStock = '',
  ) {
    this.allow(user.role);
    return this.inventory.list(query, lowStock === '1' || lowStock === 'true');
  }

  @Get('brands')
  brands(@CurrentUser() user: { role: string }) {
    this.allow(user.role);
    return this.editor.brands();
  }

  @Get('products/:productId')
  product(@CurrentUser() user: { role: string }, @Param('productId', ParseUUIDPipe) productId: string) {
    this.allow(user.role);
    return this.editor.getProduct(productId);
  }

  @Post('products')
  createProduct(@CurrentUser() user: { role: string }, @Body() body: SaveProductDto) {
    this.allow(user.role);
    return this.editor.create(body);
  }

  @Put('products/:productId')
  updateProduct(
    @CurrentUser() user: { role: string },
    @Param('productId', ParseUUIDPipe) productId: string,
    @Body() body: SaveProductDto,
  ) {
    this.allow(user.role);
    return this.editor.update(productId, body);
  }

  @Get('categories')
  categories(@CurrentUser() user: { role: string }) {
    this.allow(user.role);
    return this.inventory.categories();
  }

  @Patch('categories/:id')
  setCategory(
    @CurrentUser() user: { role: string },
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: UpdateCategoryDto,
  ) {
    this.allow(user.role);
    return this.inventory.setCategoryActive(id, body.isActive);
  }

  @Get(':variantId/movements')
  movements(
    @CurrentUser() user: { role: string },
    @Param('variantId', ParseUUIDPipe) variantId: string,
  ) {
    this.allow(user.role);
    return this.inventory.movements(variantId);
  }

  @Post(':variantId/movements')
  move(
    @CurrentUser() user: { id: string; role: string },
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @Body() body: StockMovementDto,
  ) {
    this.allow(user.role);
    return this.inventory.registerMovement(user.id, variantId, body);
  }

  @Patch(':variantId/price')
  price(
    @CurrentUser() user: { role: string },
    @Param('variantId', ParseUUIDPipe) variantId: string,
    @Body() body: UpdatePriceDto,
  ) {
    this.allow(user.role);
    return this.inventory.updatePrice(variantId, body.price);
  }

  private allow(role: string) {
    try {
      assertWarehouseStaff(role);
    } catch {
      throw new ForbiddenException('Acceso exclusivo para almacén y administración.');
    }
  }
}
