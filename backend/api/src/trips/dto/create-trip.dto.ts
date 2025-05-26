import { IsArray, IsBoolean, IsDate, IsNotEmpty, IsNumber, IsObject, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateTripDto {
  @IsString()
  @IsOptional()
  id?: string;

  @IsString()
  @IsOptional()
  orderNumber?: string;

  @IsString()
  @IsNotEmpty()
  clientId: string;

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
  @IsNotEmpty()
  supplierId: string;

  @IsString()
  @IsOptional()
  supplierName?: string;

  @IsString()
  @IsNotEmpty()
  source: string;

  @IsString()
  @IsNotEmpty()
  destination: string;

  @IsNumber()
  @IsOptional()
  distance?: number;

  @IsDate()
  @Type(() => Date)
  @IsNotEmpty()
  startDate: Date;

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
  status?: string = 'Scheduled';

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
  margin: number = 0;

  @IsNumber()
  @IsOptional()
  advanceSupplierFreight: number = 0;

  @IsNumber()
  @IsOptional()
  balanceSupplierFreight: number = 0;

  @IsString()
  @IsOptional()
  advancePaymentStatus?: string;

  @IsString()
  @IsOptional()
  balancePaymentStatus?: string;

  @IsObject()
  @IsOptional()
  fieldOps?: {
    name: string;
    phone: string;
    email: string;
  };

  @IsBoolean()
  @IsOptional()
  gsmTracking?: boolean;

  @IsString()
  @IsOptional()
  notes?: string;
} 