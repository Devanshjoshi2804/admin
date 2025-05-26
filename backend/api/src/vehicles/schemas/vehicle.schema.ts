import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type VehicleDocument = Vehicle & Document;

@Schema({ timestamps: true })
export class Vehicle {
  @Prop({ required: true, unique: true })
  id: string;

  @Prop({ required: true, unique: true })
  vehicleNumber: string;

  @Prop({ required: true })
  vehicleType: string;

  @Prop({ required: true })
  vehicleSize: string;

  @Prop({ required: true })
  vehicleCapacity: string;

  @Prop({ required: true })
  axleType: string;

  @Prop({ required: true })
  supplierId: string;

  @Prop()
  supplierName: string;

  @Prop()
  ownerName: string;

  // Driver Information
  @Prop()
  driverName: string;

  @Prop()
  driverPhone: string;

  @Prop()
  driverLicense: string;

  // Compliance Information
  @Prop()
  rcNumber: string;

  @Prop()
  insuranceExpiry: string;

  @Prop()
  pucExpiry: string;

  @Prop()
  fitnessExpiry: string;

  @Prop()
  permitExpiry: string;

  // Legacy date fields for backward compatibility
  @Prop()
  registrationNumber: string;

  @Prop()
  type: string;

  @Prop()
  capacity: string;

  @Prop()
  dimensions: string;

  @Prop()
  insuranceExpiryDate: Date;

  @Prop()
  pucExpiryDate: Date;

  @Prop()
  fitnessExpiryDate: Date;

  @Prop()
  permitExpiryDate: Date;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: 'Active' })
  status: string;

  // Documents with enhanced metadata
  @Prop({ type: [Object], default: [] })
  documents: {
    type: string;
    url: string;
    filename: string;
    originalName: string;
    mimeType: string;
    size: number;
    uploadedAt: Date;
    isVerified: boolean;
    verifiedAt?: Date;
    verifiedBy?: string;
    expiryDate?: Date;
  }[];
}

export const VehicleSchema = SchemaFactory.createForClass(Vehicle); 