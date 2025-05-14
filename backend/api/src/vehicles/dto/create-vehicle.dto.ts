import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateVehicleDto {
  @IsString()
  @IsNotEmpty()
  registrationNumber: string;

  @IsString()
  @IsOptional()
  supplierId?: string;

  @IsString()
  @IsNotEmpty()
  supplierName: string;

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

  @IsString()
  @IsNotEmpty()
  driverName: string;

  @IsString()
  @IsNotEmpty()
  driverPhone: string;

  @IsString()
  @IsOptional()
  insuranceExpiry?: string;
} 