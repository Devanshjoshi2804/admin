import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateVehicleDto {
  @IsString()
  @IsOptional()
  id?: string;

  @IsString()
  @IsNotEmpty()
  registrationNumber: string;

  @IsString()
  @IsNotEmpty()
  type: string;

  @IsString()
  @IsNotEmpty()
  capacity: string;

  @IsString()
  @IsOptional()
  dimensions?: string;

  @IsString()
  @IsNotEmpty()
  supplierId: string;

  @IsString()
  @IsOptional()
  supplierName?: string;

  @IsString()
  @IsOptional()
  driverName?: string;

  @IsString()
  @IsOptional()
  driverPhone?: string;

  @IsString()
  @IsOptional()
  insuranceExpiryDate?: string;

  @IsString()
  @IsOptional()
  pucExpiryDate?: string;

  @IsString()
  @IsOptional()
  fitnessExpiryDate?: string;

  @IsString()
  @IsOptional()
  permitExpiryDate?: string;

  @IsString()
  @IsOptional()
  status?: string;
} 