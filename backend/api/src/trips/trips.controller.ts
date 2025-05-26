import { Controller, Get, Post, Body, Patch, Param, Delete, HttpCode, HttpStatus, Query, BadRequestException } from '@nestjs/common';
import { TripsService } from './trips.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';
import { PaymentStatusDto } from './dto/payment-status.dto';
import { UpdateAdditionalChargesDto } from './dto/update-additional-charges.dto';

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
  async findAll(@Query('page') page?: string, @Query('limit') limit?: string) {
    const pageNum = parseInt(page || '1', 10);
    const limitNum = parseInt(limit || '50', 10);
    
    // For paginated requests, return optimized data
    if (page || limit) {
      return this.tripsService.findAllPaginated(pageNum, limitNum);
    }
    
    // For non-paginated requests, return all trips (existing behavior)
    return this.tripsService.findAll();
  }

  // ⚡ Ultra-fast trip loading with all related data in single query
  @Get('ultra-fast')
  async getTripsUltraFast(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: string,
    @Query('clientId') clientId?: string,
  ) {
    const startTime = Date.now();
    
    try {
      console.log('🚀 Ultra-fast trip loading started');
      
      const pageNum = parseInt(page || '1');
      const limitNum = parseInt(limit || '50');
      const skip = (pageNum - 1) * limitNum;
      
      const result = await this.tripsService.getTripsUltraFast({
        skip,
        limit: limitNum,
        status,
        clientId,
      });
      
      const processingTime = Date.now() - startTime;
      console.log(`✅ Ultra-fast trip loading completed in ${processingTime}ms`);
      
      return {
        success: true,
        processingTime,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total: result.total,
          pages: Math.ceil(result.total / limitNum),
        },
        data: result.trips,
      };
    } catch (error) {
      const processingTime = Date.now() - startTime;
      console.error(`❌ Ultra-fast trip loading failed in ${processingTime}ms:`, error);
      throw error;
    }
  }

  // ⚡ Lightning-fast single trip loading with all data
  @Get(':id/ultra-fast')
  async getTripUltraFast(@Param('id') id: string) {
    const startTime = Date.now();
    
    try {
      console.log(`🚀 Ultra-fast single trip loading: ${id}`);
      
      const trip = await this.tripsService.getTripUltraFast(id);
      
      const processingTime = Date.now() - startTime;
      console.log(`✅ Ultra-fast trip loading completed in ${processingTime}ms`);
      
      return {
        success: true,
        processingTime,
        data: trip,
      };
    } catch (error) {
      const processingTime = Date.now() - startTime;
      console.error(`❌ Ultra-fast trip loading failed in ${processingTime}ms:`, error);
      throw error;
    }
  }

  // ⚡ Ultra-fast trip dashboard data (aggregated stats + recent trips)
  @Get('dashboard/ultra-fast')
  async getDashboardDataUltraFast() {
    const startTime = Date.now();
    
    try {
      console.log('🚀 Ultra-fast dashboard loading started');
      
      const result = await this.tripsService.getDashboardDataUltraFast();
      
      const processingTime = Date.now() - startTime;
      console.log(`✅ Ultra-fast dashboard loading completed in ${processingTime}ms`);
      
      return {
        success: true,
        processingTime,
        data: result,
      };
    } catch (error) {
      const processingTime = Date.now() - startTime;
      console.error(`❌ Ultra-fast dashboard loading failed in ${processingTime}ms:`, error);
      throw error;
    }
  }

  @Get('payment-queue/advance')
  getAdvancePaymentQueue() {
    return this.tripsService.getAdvancePaymentQueue();
  }

  @Get('payment-queue/balance')
  getBalancePaymentQueue() {
    return this.tripsService.getBalancePaymentQueue();
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

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() data: { status: string }) {
    return this.tripsService.updateStatus(id, data.status);
  }

  @Patch(':id/additional-charges')
  updateAdditionalCharges(
    @Param('id') id: string,
    @Body() chargesData: UpdateAdditionalChargesDto
  ) {
    console.log("Updating additional charges for trip:", id, JSON.stringify(chargesData));
    return this.tripsService.updateAdditionalCharges(id, chargesData);
  }

  @Patch(':id/payment-status')
  updatePaymentStatus(
    @Param('id') id: string,
    @Body() paymentData: PaymentStatusDto
  ) {
    console.log("Real-time payment status update:", JSON.stringify(paymentData));
    return this.tripsService.updatePaymentStatus(id, paymentData);
  }

  @Post(':id/process-payment')
  processPayment(
    @Param('id') id: string,
    @Body() paymentData: {
      paymentType: 'advance' | 'balance';
      paymentStatus: 'Initiated' | 'Pending' | 'Paid';
      utrNumber?: string;
      paymentMethod?: string;
      notes?: string;
    }
  ) {
    console.log("Processing payment:", JSON.stringify(paymentData));
    return this.tripsService.processPayment(id, paymentData);
  }

  @Post(':id/upload-pod')
  uploadPOD(
    @Param('id') id: string,
    @Body() podData: {
      filename: string;
      url: string;
    }
  ) {
    console.log("Uploading POD:", JSON.stringify(podData));
    return this.tripsService.uploadPOD(id, podData);
  }

  @Post(':id/documents')
  uploadDocument(
    @Param('id') id: string,
    @Body() docData: { 
      type: string; 
      number?: string; 
      filename?: string;
      url?: string;
    }
  ) {
    return this.tripsService.uploadDocument(id, docData);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.tripsService.remove(id);
  }
}
