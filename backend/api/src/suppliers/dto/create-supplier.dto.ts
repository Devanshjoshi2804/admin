import { IsNotEmpty, IsObject, IsOptional, IsString, IsBoolean } from 'class-validator';

export class CreateSupplierDto {
  @IsString()
  @IsOptional()
  id?: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsOptional()
  state?: string;

  @IsString()
  @IsOptional()
  pinCode?: string;

  @IsString()
  @IsOptional()
  pincode?: string;

  @IsBoolean()
  @IsOptional()
  hasGST?: boolean;

  @IsString()
  @IsOptional()
  gstNumber?: string;

  @IsString()
  @IsOptional()
  aadharCardNumber?: string;

  @IsString()
  @IsOptional()
  panCardNumber?: string;

  @IsString()
  @IsOptional()
  panNumber?: string;

  @IsString()
  @IsOptional()
  contactName?: string;
  
  @IsString()
  @IsOptional()
  contactPhone?: string;
  
  @IsString()
  @IsOptional()
  contactEmail?: string;

  @IsObject()
  @IsOptional()
  contactPerson?: {
    name?: string;
    phone?: string;
    email?: string;
  };
  
  @IsString()
  @IsOptional()
  representativeName?: string;
  
  @IsString()
  @IsOptional()
  representativeDesignation?: string;
  
  @IsString()
  @IsOptional()
  representativePhone?: string;
  
  @IsString()
  @IsOptional()
  representativeEmail?: string;
  
  @IsString()
  @IsOptional()
  bankName?: string;
  
  @IsString()
  @IsOptional()
  accountType?: string;
  
  @IsString()
  @IsOptional()
  accountNumber?: string;

  @IsString()
  @IsOptional()
  accountHolderName?: string;
  
  @IsString()
  @IsOptional()
  ifscCode?: string;

  @IsObject()
  @IsOptional()
  accountDetails?: {
    accountNumber?: string;
    bankName?: string;
    ifscCode?: string;
    accountHolderName?: string;
    accountType?: string;
  };

  @IsString()
  @IsOptional()
  serviceType?: string;

  @IsOptional()
  vehicleTypes?: string[];

  @IsString()
  @IsOptional()
  status?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
  
  @IsOptional()
  documents?: any[];
} 