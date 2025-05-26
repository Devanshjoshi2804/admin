import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SupplierDocument = Supplier & Document;

@Schema({ timestamps: true })
export class Supplier {
  @Prop({ required: true, unique: true })
  id: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  address: string;

  @Prop({ required: true })
  city: string;

  @Prop()
  state: string;

  @Prop()
  pinCode: string;

  // GST Information
  @Prop({ default: true })
  hasGST: boolean;

  @Prop()
  gstNumber: string;

  // Identity Documents
  @Prop({ required: true })
  aadharCardNumber: string;

  @Prop({ required: true })
  panCardNumber: string;

  // Contact Person
  @Prop()
  contactName: string;

  @Prop()
  contactPhone: string;

  @Prop()
  contactEmail: string;

  // Representative
  @Prop()
  representativeName: string;

  @Prop()
  representativeDesignation: string;

  @Prop()
  representativePhone: string;

  @Prop()
  representativeEmail: string;

  // Bank Details
  @Prop()
  bankName: string;

  @Prop()
  accountType: string;

  @Prop()
  accountNumber: string;

  @Prop()
  accountHolderName: string;

  @Prop()
  ifscCode: string;

  // Business Information
  @Prop()
  serviceType: string;

  @Prop({ default: true })
  isActive: boolean;

  // Enhanced Documents for both GST and Non-GST suppliers
  @Prop({ type: [Object], default: [] })
  documents: {
    type: string; // 'aadhar_card', 'pan_card', 'gst_certificate', 'non_gst_declaration', 'itr_year_1', 'itr_year_2', 'itr_year_3', 'lr_copy', 'loading_slip', 'bank_passbook', 'cancelled_cheque', 'other'
    url: string;
    filename: string;
    originalName: string;
    mimeType: string;
    size: number;
    number?: string; // For document numbers like Aadhar number, PAN number, etc.
    year?: number; // For ITR documents
    uploadedAt: Date;
    isVerified?: boolean;
    verifiedAt?: Date;
    verifiedBy?: string;
  }[];

  // Verification Status
  @Prop({ default: false })
  isVerified: boolean;

  @Prop()
  verifiedAt: Date;

  @Prop()
  verifiedBy: string;

  @Prop({ type: [String], default: [] })
  verificationNotes: string[];
}

export const SupplierSchema = SchemaFactory.createForClass(Supplier); 