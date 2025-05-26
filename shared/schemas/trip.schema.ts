import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type TripDocument = Trip & Document;

// Define charge interface for additional and deduction charges
export interface Charge {
  description: string;
  amount: number;
  reason?: string;
  addedAt?: Date;
  addedBy?: string;
}

@Schema({ timestamps: true })
export class Trip {
  @Prop({ required: true, unique: true })
  id: string;

  @Prop({ required: true })
  orderNumber: string;

  @Prop({ required: true })
  clientId: string;

  @Prop()
  clientName: string;

  @Prop({ required: true })
  vehicleId: string;

  @Prop()
  vehicleNumber: string;

  @Prop()
  vehicleType: string;

  @Prop({ required: true })
  supplierId: string;

  @Prop()
  supplierName: string;

  @Prop({ required: true })
  source: string;

  @Prop({ required: true })
  destination: string;

  @Prop()
  distance: number;

  @Prop({ required: true })
  startDate: Date;

  @Prop()
  endDate: Date;

  @Prop()
  loadingDate: Date;

  @Prop()
  unloadingDate: Date;

  @Prop({ type: Object })
  pricing: {
    baseAmount: number;
    gst: number;
    totalAmount: number;
  };

  @Prop({ type: [Object] })
  documents: {
    type: string;
    url: string;
    uploadedAt: Date;
    filename?: string;
    isDownloadable?: boolean;
  }[];

  @Prop({ default: 'Booked', enum: ['Booked', 'In Transit', 'Completed', 'Cancelled'] })
  status: string;

  @Prop({ default: 0 })
  clientFreight: number;

  @Prop({ default: 0 })
  supplierFreight: number;

  @Prop({ default: 30 })
  advancePercentage: number;

  @Prop({ default: 0 })
  margin: number;

  @Prop({ default: 0 })
  advanceSupplierFreight: number;

  @Prop({ default: 0 })
  balanceSupplierFreight: number;

  // Additional charges fields
  @Prop({ type: [Object], default: [] })
  additionalCharges: Charge[];

  @Prop({ type: [Object], default: [] })
  deductionCharges: Charge[];

  // Individual charge amounts for easier queries
  @Prop({ default: 0 })
  lrCharges: number;

  @Prop({ default: 0 })
  platformFees: number;

  @Prop({ default: 0 })
  miscellaneousCharges: number;

  @Prop({ default: 0 })
  totalAdditionalCharges: number;

  @Prop({ default: 0 })
  totalDeductionCharges: number;

  @Prop({ default: 'Not Started', enum: ['Not Started', 'Initiated', 'Pending', 'Paid'] })
  advancePaymentStatus: string;

  @Prop({ default: 'Not Started', enum: ['Not Started', 'Initiated', 'Pending', 'Paid'] })
  balancePaymentStatus: string;

  @Prop({ default: false })
  podUploaded: boolean;

  @Prop()
  podDate: Date;

  @Prop()
  podDocument: {
    filename: string;
    url: string;
    uploadedAt: Date;
    isDownloadable: boolean;
  };

  @Prop()
  paymentDate: Date;

  @Prop()
  utrNumber: string;

  @Prop({ default: 'Bank Transfer' })
  paymentMethod: string;

  @Prop({ default: false })
  isInAdvanceQueue: boolean;

  @Prop({ default: false })
  isInBalanceQueue: boolean;

  @Prop()
  advancePaymentInitiatedAt: Date;

  @Prop()
  advancePaymentCompletedAt: Date;

  @Prop()
  balancePaymentInitiatedAt: Date;

  @Prop()
  balancePaymentCompletedAt: Date;

  @Prop({ type: Object })
  fieldOps: {
    name: string;
    phone: string;
    email: string;
  };

  @Prop()
  notes: string;

  @Prop({ type: [Object], default: [] })
  paymentHistory: {
    paymentType: string;
    status: string;
    amount: number;
    timestamp: Date;
    utrNumber?: string;
    paymentMethod?: string;
    notes?: string;
  }[];

  // Charges history for audit trail
  @Prop({ type: [Object], default: [] })
  chargesHistory: {
    action: 'add' | 'remove' | 'modify';
    chargeType: 'additional' | 'deduction';
    description: string;
    amount: number;
    reason?: string;
    timestamp: Date;
    addedBy?: string;
  }[];
}

export const TripSchema = SchemaFactory.createForClass(Trip); 