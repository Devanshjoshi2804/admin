import { IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

export class CreateClientDto {
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
  addressType?: string;

  @IsString()
  @IsOptional()
  gstNumber?: string;

  @IsString()
  @IsOptional()
  panNumber?: string;

  @IsObject()
  @IsOptional()
  logisticsPOC?: {
    name?: string;
    phone?: string;
    email?: string;
  };

  @IsObject()
  @IsOptional()
  financePOC?: {
    name?: string;
    phone?: string;
    email?: string;
  };

  @IsString()
  @IsOptional()
  invoicingType?: string;

  @IsObject()
  @IsOptional()
  salesRep?: {
    name?: string;
    phone?: string;
    email?: string;
    designation?: string;
  };
  
  @IsObject()
  @IsOptional()
  salesRepresentative?: {
    name?: string;
    phone?: string;
    email?: string;
    designation?: string;
  };
  
  // Additional fields to match frontend model
  @IsString()
  @IsOptional()
  logisticsName?: string;
  
  @IsString()
  @IsOptional()
  logisticsPhone?: string;
  
  @IsString()
  @IsOptional()
  logisticsEmail?: string;
  
  @IsString()
  @IsOptional()
  financeName?: string;
  
  @IsString()
  @IsOptional()
  financePhone?: string;
  
  @IsString()
  @IsOptional()
  financeEmail?: string;
  
  @IsString()
  @IsOptional()
  salesRepName?: string;
  
  @IsString()
  @IsOptional()
  salesRepDesignation?: string;
  
  @IsString()
  @IsOptional()
  salesRepPhone?: string;
  
  @IsString()
  @IsOptional()
  salesRepEmail?: string;
  
  @IsOptional()
  documents?: any[];
} 