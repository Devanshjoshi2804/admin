import { IsArray, IsBoolean, IsNotEmpty, IsNumber, IsObject, IsOptional, IsString } from 'class-validator';

export class CreateTripDto {
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  lrNumbers: string[];

  @IsString()
  @IsOptional()
  clientId?: string;

  @IsString()
  @IsNotEmpty()
  clientName: string;

  @IsString()
  @IsNotEmpty()
  clientAddress: string;

  @IsString()
  @IsNotEmpty()
  clientAddressType: string;

  @IsString()
  @IsNotEmpty()
  clientCity: string;

  @IsString()
  @IsNotEmpty()
  destinationAddress: string;

  @IsString()
  @IsNotEmpty()
  destinationCity: string;

  @IsString()
  @IsNotEmpty()
  destinationAddressType: string;

  @IsString()
  @IsOptional()
  supplierId?: string;

  @IsString()
  @IsNotEmpty()
  supplierName: string;

  @IsString()
  @IsOptional()
  vehicleId?: string;

  @IsString()
  @IsNotEmpty()
  vehicleNumber: string;

  @IsString()
  @IsOptional()
  driverName?: string;

  @IsString()
  @IsOptional()
  driverPhone?: string;

  @IsString()
  @IsNotEmpty()
  vehicleType: string;

  @IsString()
  @IsNotEmpty()
  vehicleSize: string;

  @IsString()
  @IsNotEmpty()
  vehicleCapacity: string;

  @IsString()
  @IsNotEmpty()
  axleType: string;

  @IsArray()
  @IsObject({ each: true })
  materials: {
    name: string;
    weight: number;
    unit: string;
    ratePerMT: number;
  }[];

  @IsString()
  @IsNotEmpty()
  pickupDate: string;

  @IsString()
  @IsNotEmpty()
  pickupTime: string;

  @IsNumber()
  clientFreight: number;

  @IsNumber()
  supplierFreight: number;

  @IsNumber()
  advancePercentage: number;

  @IsObject()
  fieldOps: {
    name: string;
    phone: string;
    email: string;
  };

  @IsBoolean()
  @IsOptional()
  gsmTracking?: boolean;

  @IsString()
  @IsNotEmpty()
  status: string = 'Booked';

  @IsString()
  @IsNotEmpty()
  advancePaymentStatus: string = 'Not Started';

  @IsString()
  @IsNotEmpty()
  balancePaymentStatus: string = 'Not Started';
} 