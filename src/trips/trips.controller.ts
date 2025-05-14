import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import { TripsService } from './trips.service';
import { CreateTripDto, UpdateTripDto } from './models/trip.model';

@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Get()
  findAll() {
    return this.tripsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tripsService.findOne(id);
  }

  @Post()
  create(@Body() createTripDto: CreateTripDto) {
    return this.tripsService.create(createTripDto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTripDto: UpdateTripDto) {
    return this.tripsService.update(id, updateTripDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.tripsService.remove(id);
  }
} 