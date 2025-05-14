import { Controller, Get, Post, Body, Patch, Param, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { TripsService } from './trips.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';

@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() createTripDto: CreateTripDto) {
    console.log("Creating trip with data:", JSON.stringify(createTripDto));
    return this.tripsService.create(createTripDto);
  }

  @Get()
  findAll() {
    return this.tripsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tripsService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateTripDto: UpdateTripDto
  ) {
    console.log("Updating trip with data:", JSON.stringify(updateTripDto));
    return this.tripsService.update(id, updateTripDto);
  }

  @Patch(':id/payment-status')
  updatePaymentStatus(
    @Param('id') id: string,
    @Body() paymentData: { 
      advancePaymentStatus?: string; 
      balancePaymentStatus?: string;
      utrNumber?: string;
      paymentMethod?: string;
    }
  ) {
    console.log("Updating payment status with data:", JSON.stringify(paymentData));
    return this.tripsService.updatePaymentStatus(id, paymentData);
  }

  @Post(':id/documents')
  uploadDocument(
    @Param('id') id: string,
    @Body() docData: { type: string; number: string; filename: string }
  ) {
    return this.tripsService.uploadDocument(id, docData);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.tripsService.remove(id);
  }
}
