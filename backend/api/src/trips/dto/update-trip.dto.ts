import { PartialType } from '@nestjs/mapped-types';
import { CreateTripDto } from './create-trip.dto';
import { IsArray, IsDate, IsNotEmpty, IsNumber, IsObject, IsOptional, IsString, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateTripDto extends PartialType(CreateTripDto) {
  @IsString()
  @IsOptional()
  id?: string;

  @IsString()
  @IsOptional()
  orderNumber?: string;

  @IsString()
  @IsOptional()
  clientId?: string;

  @IsString()
  @IsOptional()
  clientName?: string;

  @IsString()
  @IsOptional()
  vehicleId?: string;

  @IsString()
  @IsOptional()
  vehicleNumber?: string;

  @IsString()
  @IsOptional()
  vehicleType?: string;

  @IsString()
  @IsOptional()
  supplierId?: string;

  @IsString()
  @IsOptional()
  supplierName?: string;

  @IsString()
  @IsOptional()
  source?: string;

  @IsString()
  @IsOptional()
  destination?: string;

  @IsNumber()
  @IsOptional()
  distance?: number;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  startDate?: Date;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  endDate?: Date;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  loadingDate?: Date;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  unloadingDate?: Date;

  @IsObject()
  @IsOptional()
  pricing?: {
    baseAmount: number;
    gst: number;
    totalAmount: number;
  };

  @IsNumber()
  @IsOptional()
  baseAmount?: number;

  @IsNumber()
  @IsOptional()
  gst?: number;

  @IsNumber()
  @IsOptional()
  totalAmount?: number;

  @IsArray()
  @IsObject({ each: true })
  @IsOptional()
  documents?: {
    type: string;
    url: string;
    uploadedAt: Date;
  }[];

  @IsString()
  @IsOptional()
  status?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  advancePaymentStatus?: string;

  @IsString()
  @IsOptional()
  balancePaymentStatus?: string;

  @IsNumber()
  @IsOptional()
  clientFreight?: number;

  @IsNumber()
  @IsOptional()
  supplierFreight?: number;

  @IsNumber()
  @IsOptional()
  advancePercentage?: number;

  @IsNumber()
  @IsOptional()
  margin?: number;

  @IsNumber()
  @IsOptional()
  advanceSupplierFreight?: number;

  @IsNumber()
  @IsOptional()
  balanceSupplierFreight?: number;

  @IsString()
  @IsOptional()
  utrNumber?: string;

  @IsString()
  @IsOptional()
  paymentMethod?: string;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  paymentDate?: Date;

  @IsBoolean()
  @IsOptional()
  podUploaded?: boolean;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  podDate?: Date;
} 