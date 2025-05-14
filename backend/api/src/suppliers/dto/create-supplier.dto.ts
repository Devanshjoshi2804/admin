import { IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

export class CreateSupplierDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsObject()
  @IsOptional()
  contactPerson?: {
    name: string;
    phone: string;
    email: string;
  };

  @IsObject()
  @IsOptional()
  bankDetails?: {
    accountNumber: string;
    bankName: string;
    ifscCode: string;
    accountHolderName: string;
  };

  @IsString()
  @IsOptional()
  gstNumber?: string;
} 