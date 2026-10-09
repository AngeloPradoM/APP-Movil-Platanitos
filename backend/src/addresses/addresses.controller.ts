import { Body, Controller, Delete, Get, Param, ParseUUIDPipe, Post, Put, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { AddressesService } from './addresses.service.js';
import { SaveAddressDto } from './dto/save-address.dto.js';

@Controller('addresses')
@UseGuards(AuthGuard('jwt'))
export class AddressesController {
  constructor(private readonly addressesService: AddressesService) {}

  @Get()
  list(@CurrentUser() user: { id: string }) {
    return this.addressesService.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() input: SaveAddressDto) {
    return this.addressesService.create(user.id, input);
  }

  @Put(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id', ParseUUIDPipe) id: string,
    @Body() input: SaveAddressDto,
  ) {
    return this.addressesService.update(user.id, id, input);
  }

  @Delete(':id')
  remove(@CurrentUser() user: { id: string }, @Param('id', ParseUUIDPipe) id: string) {
    return this.addressesService.remove(user.id, id);
  }
}
