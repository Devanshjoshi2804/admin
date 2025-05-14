import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CreateTripDto } from './create-trip.dto';
import { IsArray, IsBoolean, IsNotEmpty, IsNumber, IsObject, IsOptional, IsString } from 'class-validator';

export class UpdateTripDto extends PartialType(OmitType(CreateTripDto, [] as const)) {
  @IsArray()
  @IsObject({ each: true })
  @IsOptional()
  documents?: {
    id: string;
    type: string;
    number: string;
    filename: string;
    uploadDate: string;
    expiryDate?: string;
  }[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  lrNumbers?: string[];

  @IsOptional()
  @IsString()
  clientId?: string;

  @IsOptional()
  @IsString()
  clientName?: string;

  @IsOptional()
  @IsString()
  clientAddress?: string;

  @IsOptional()
  @IsString()
  clientAddressType?: string;

  @IsOptional()
  @IsString()
  clientCity?: string;

  @IsOptional()
  @IsString()
  destinationAddress?: string;

  @IsOptional()
  @IsString()
  destinationCity?: string;

  @IsOptional()
  @IsString()
  destinationAddressType?: string;

  @IsOptional()
  @IsString()
  supplierId?: string;

  @IsOptional()
  @IsString()
  supplierName?: string;

  @IsOptional()
  @IsString()
  vehicleId?: string;

  @IsOptional()
  @IsString()
  vehicleNumber?: string;

  @IsOptional()
  @IsString()
  driverName?: string;

  @IsOptional()
  @IsString()
  driverPhone?: string;

  @IsOptional()
  @IsString()
  vehicleType?: string;

  @IsOptional()
  @IsString()
  vehicleSize?: string;

  @IsOptional()
  @IsString()
  vehicleCapacity?: string;

  @IsOptional()
  @IsString()
  axleType?: string;

  @IsOptional()
  @IsArray()
  materials?: any[];

  @IsOptional()
  @IsString()
  pickupDate?: string;

  @IsOptional()
  @IsString()
  pickupTime?: string;

  @IsOptional()
  @IsNumber()
  clientFreight?: number;

  @IsOptional()
  @IsNumber()
  supplierFreight?: number;

  @IsOptional()
  @IsNumber()
  advancePercentage?: number;

  @IsOptional()
  @IsObject()
  fieldOps?: {
    name: string;
    phone: string;
    email: string;
  };

  @IsOptional()
  @IsBoolean()
  gsmTracking?: boolean;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  advancePaymentStatus?: string;

  @IsOptional()
  @IsString()
  balancePaymentStatus?: string;

  @IsOptional()
  @IsNumber()
  lrCharges?: number;
  
  @IsOptional()
  @IsBoolean()
  podUploaded?: boolean;
  
  @IsOptional()
  @IsString()
  utrNumber?: string;
  
  @IsOptional()
  @IsString()
  paymentMethod?: string;
  
  @IsOptional()
  additionalCharges?: any[];
  
  @IsOptional()
  deductionCharges?: any[];
} 