import { Controller, Get, Post, Patch, Body, Param, Query } from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Get('advance-queue')
  async getAdvancePaymentQueue() {
    return this.paymentsService.getAdvancePaymentQueue();
  }

  @Get('balance-queue')
  async getBalancePaymentQueue() {
    return this.paymentsService.getBalancePaymentQueue();
  }

  @Patch(':tripId/status')
  async updatePaymentStatus(
    @Param('tripId') tripId: string,
    @Body() updateData: any,
  ) {
    return this.paymentsService.updatePaymentStatusFast(tripId, updateData);
  }

  @Patch('bulk-update')
  async bulkUpdatePaymentStatus(@Body() data: { updates: any[] }) {
    return this.paymentsService.bulkUpdatePaymentStatus(data.updates);
  }

  @Get('stats')
  async getPaymentStats() {
    return this.paymentsService.getPaymentStats();
  }

  // Ultra-fast single payment processing
  @Patch(':tripId/ultra-fast')
  async ultraFastPaymentUpdate(
    @Param('tripId') tripId: string,
    @Body() updateData: {
      paymentType: 'advance' | 'balance';
      targetStatus: 'Initiated' | 'Pending' | 'Paid';
      utrNumber?: string;
      paymentMethod?: string;
    },
  ) {
    const startTime = Date.now();
    
    try {
      console.log(`🚀 Ultra-fast payment processing started for ${tripId}`);
      
      const result = await this.paymentsService.ultraFastPaymentUpdate(tripId, updateData);
      
      const processingTime = Date.now() - startTime;
      console.log(`✅ Ultra-fast payment processing completed in ${processingTime}ms`);
      
      return {
        success: true,
        tripId,
        paymentType: updateData.paymentType,
        newStatus: updateData.targetStatus,
        processingTime,
        timestamp: new Date().toISOString(),
        data: result,
      };
    } catch (error) {
      const processingTime = Date.now() - startTime;
      console.error(`❌ Ultra-fast payment processing failed in ${processingTime}ms:`, error);
      
      throw error;
    }
  }

  // Lightning-fast payment validation
  @Get(':tripId/can-process/:paymentType')
  async canProcessPayment(
    @Param('tripId') tripId: string,
    @Param('paymentType') paymentType: 'advance' | 'balance',
  ) {
    return this.paymentsService.canProcessPayment(tripId, paymentType);
  }

  // Instant payment status progression
  @Patch(':tripId/next-status/:paymentType')
  async progressPaymentStatus(
    @Param('tripId') tripId: string,
    @Param('paymentType') paymentType: 'advance' | 'balance',
  ) {
    const startTime = Date.now();
    
    try {
      const result = await this.paymentsService.progressPaymentToNextStatus(tripId, paymentType);
      
      const processingTime = Date.now() - startTime;
      console.log(`⚡ Payment status progression completed in ${processingTime}ms`);
      
      return {
        success: true,
        processingTime,
        ...result,
      };
    } catch (error) {
      const processingTime = Date.now() - startTime;
      console.error(`❌ Payment status progression failed in ${processingTime}ms:`, error);
      
      throw error;
    }
  }
} 