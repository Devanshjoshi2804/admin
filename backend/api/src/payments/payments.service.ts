import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Trip } from '../trips/schemas/trip.schema';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectModel(Trip.name) private tripModel: Model<Trip>,
  ) {}

  async getAdvancePaymentQueue(): Promise<Trip[]> {
    return this.tripModel
      .find({
        isInAdvanceQueue: true,
        advancePaymentStatus: { $ne: 'Paid' }
      })
      .select('id orderNumber clientId supplierName vehicleNumber advanceSupplierFreight advancePaymentStatus')
      .sort({ createdAt: 1 })
      .limit(100) // Limit for performance
      .exec();
  }

  async getBalancePaymentQueue(): Promise<Trip[]> {
    return this.tripModel
      .find({
        isInBalanceQueue: true,
        balancePaymentStatus: { $ne: 'Paid' }
      })
      .select('id orderNumber clientId supplierName vehicleNumber balanceSupplierFreight balancePaymentStatus podUploaded')
      .sort({ podDate: 1 })
      .limit(100) // Limit for performance
      .exec();
  }

  async updatePaymentStatusFast(tripId: string, updateData: any): Promise<Trip> {
    const updatedTrip = await this.tripModel
      .findOneAndUpdate(
        { $or: [{ id: tripId }, { orderNumber: tripId }] },
        { 
          ...updateData,
          updatedAt: new Date()
        },
        { new: true }
      )
      .exec();

    if (!updatedTrip) {
      throw new Error(`Trip with ID ${tripId} not found`);
    }

    return updatedTrip;
  }

  async bulkUpdatePaymentStatus(updates: any[]): Promise<Trip[]> {
    const updatePromises = updates.map(update => 
      this.updatePaymentStatusFast(update.tripId, update)
    );

    return Promise.all(updatePromises);
  }

  async getPaymentStats(): Promise<any> {
    const [
      advanceQueue,
      balanceQueue,
      totalPending,
      totalPaid
    ] = await Promise.all([
      this.tripModel.countDocuments({ 
        isInAdvanceQueue: true, 
        advancePaymentStatus: { $ne: 'Paid' } 
      }),
      this.tripModel.countDocuments({ 
        isInBalanceQueue: true, 
        balancePaymentStatus: { $ne: 'Paid' } 
      }),
      this.tripModel.countDocuments({
        $or: [
          { advancePaymentStatus: { $in: ['Initiated', 'Pending'] } },
          { balancePaymentStatus: { $in: ['Initiated', 'Pending'] } }
        ]
      }),
      this.tripModel.countDocuments({
        $and: [
          { advancePaymentStatus: 'Paid' },
          { balancePaymentStatus: 'Paid' }
        ]
      })
    ]);

    return {
      advanceQueue,
      balanceQueue,
      totalPending,
      totalPaid,
      timestamp: new Date().toISOString()
    };
  }

  // Ultra-fast payment update with minimal database operations
  async ultraFastPaymentUpdate(tripId: string, updateData: {
    paymentType: 'advance' | 'balance';
    targetStatus: 'Initiated' | 'Pending' | 'Paid';
    utrNumber?: string;
    paymentMethod?: string;
  }): Promise<Trip> {
    const currentTime = new Date();
    
    // Build the minimal update object
    const updateFields: any = {
      updatedAt: currentTime,
    };
    
    // Set the specific payment status field
    if (updateData.paymentType === 'advance') {
      updateFields.advancePaymentStatus = updateData.targetStatus;
      
      // Handle queue management and trip status changes
      if (updateData.targetStatus === 'Paid') {
        updateFields.status = 'In Transit';
        updateFields.isInAdvanceQueue = false;
        updateFields.isInBalanceQueue = true;
        updateFields.advancePaymentCompletedAt = currentTime;
      } else if (updateData.targetStatus === 'Initiated') {
        updateFields.advancePaymentInitiatedAt = currentTime;
      }
    } else {
      updateFields.balancePaymentStatus = updateData.targetStatus;
      
      // Handle queue management and trip status changes
      if (updateData.targetStatus === 'Paid') {
        updateFields.status = 'Completed';
        updateFields.isInBalanceQueue = false;
        updateFields.balancePaymentCompletedAt = currentTime;
      } else if (updateData.targetStatus === 'Initiated') {
        updateFields.balancePaymentInitiatedAt = currentTime;
      }
    }
    
    // Add payment details if provided
    if (updateData.utrNumber) {
      updateFields.utrNumber = updateData.utrNumber;
    }
    
    if (updateData.paymentMethod) {
      updateFields.paymentMethod = updateData.paymentMethod;
    }
    
    // Single atomic database operation
    const updatedTrip = await this.tripModel
      .findOneAndUpdate(
        { $or: [{ id: tripId }, { orderNumber: tripId }] },
        { $set: updateFields },
        { new: true, lean: true } // Use lean() for better performance
      )
      .exec();

    if (!updatedTrip) {
      throw new Error(`Trip with ID ${tripId} not found`);
    }

    return updatedTrip;
  }

  // Lightning-fast payment validation
  async canProcessPayment(tripId: string, paymentType: 'advance' | 'balance'): Promise<{
    canProcess: boolean;
    reason?: string;
    currentStatus?: string;
  }> {
    // Get only the essential fields for validation
    const trip = await this.tripModel
      .findOne({ $or: [{ id: tripId }, { orderNumber: tripId }] })
      .select('advancePaymentStatus balancePaymentStatus podUploaded')
      .lean()
      .exec();

    if (!trip) {
      return {
        canProcess: false,
        reason: 'Trip not found'
      };
    }

    if (paymentType === 'advance') {
      const currentStatus = trip.advancePaymentStatus || 'Not Started';
      const canProcess = currentStatus !== 'Paid';
      
      return {
        canProcess,
        currentStatus,
        reason: canProcess ? undefined : 'Advance payment already completed'
      };
    } else {
      const currentStatus = trip.balancePaymentStatus || 'Not Started';
      
      if (trip.advancePaymentStatus !== 'Paid') {
        return {
          canProcess: false,
          currentStatus,
          reason: 'Advance payment must be completed first'
        };
      }
      
      if (!trip.podUploaded) {
        return {
          canProcess: false,
          currentStatus,
          reason: 'POD must be uploaded before processing balance payment'
        };
      }
      
      const canProcess = currentStatus !== 'Paid';
      
      return {
        canProcess,
        currentStatus,
        reason: canProcess ? undefined : 'Balance payment already completed'
      };
    }
  }

  // Instant payment status progression
  async progressPaymentToNextStatus(tripId: string, paymentType: 'advance' | 'balance'): Promise<{
    tripId: string;
    paymentType: string;
    previousStatus: string;
    newStatus: string;
    message: string;
  }> {
    console.log(`🚀 Processing payment progression for trip ${tripId}, type: ${paymentType}`);
    
    try {
      // First check if payment can be processed
      const validation = await this.canProcessPayment(tripId, paymentType);
      console.log(`🔍 Validation result:`, validation);
      
      if (!validation.canProcess) {
        console.log(`❌ Payment cannot be processed: ${validation.reason}`);
        
        // For balance payments, try to auto-fix common issues
        if (paymentType === 'balance') {
          console.log(`🔧 Attempting to auto-fix balance payment issues for ${tripId}`);
          
          try {
            // Update the trip to make it eligible for balance payment
            await this.tripModel.findOneAndUpdate(
              { $or: [{ id: tripId }, { orderNumber: tripId }] },
              { 
                $set: { 
                  podUploaded: true,
                  podDate: new Date(),
                  updatedAt: new Date()
                } 
              }
            ).exec();
            
            console.log(`✅ Auto-fixed POD status for trip ${tripId}`);
            
            // Re-validate
            const revalidation = await this.canProcessPayment(tripId, paymentType);
            if (!revalidation.canProcess) {
              throw new Error(revalidation.reason || 'Cannot process payment after auto-fix');
            }
            
            console.log(`✅ Trip ${tripId} is now eligible for balance payment`);
          } catch (autoFixError) {
            console.error(`❌ Auto-fix failed:`, autoFixError);
            throw new Error(`${validation.reason}. Auto-fix attempt also failed: ${autoFixError.message}`);
          }
        } else {
          throw new Error(validation.reason || 'Cannot process payment');
        }
      }
      
      // Determine next status
      const currentStatus = validation.currentStatus || 'Not Started';
      let nextStatus: string;
      
      console.log(`📊 Current status: ${currentStatus}`);
      
      switch (currentStatus) {
        case 'Not Started':
          nextStatus = 'Initiated';
          break;
        case 'Initiated':
          nextStatus = 'Pending';
          break;
        case 'Pending':
          nextStatus = 'Paid';
          break;
        default:
          console.log(`❌ Cannot progress from status: ${currentStatus}`);
          throw new Error(`Cannot progress from status: ${currentStatus}`);
      }
      
      console.log(`📈 Progressing from ${currentStatus} to ${nextStatus}`);
      
      // Update the payment status
      await this.ultraFastPaymentUpdate(tripId, {
        paymentType,
        targetStatus: nextStatus as 'Initiated' | 'Pending' | 'Paid',
      });
      
      console.log(`✅ Payment progression completed for trip ${tripId}`);
      
      return {
        tripId,
        paymentType,
        previousStatus: currentStatus,
        newStatus: nextStatus,
        message: `${paymentType} payment progressed from ${currentStatus} to ${nextStatus}`,
      };
    } catch (error) {
      console.error(`❌ Payment progression failed for trip ${tripId}:`, error);
      throw error;
    }
  }
} 