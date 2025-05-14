import { IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

export class CreateClientDto {
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
  @IsNotEmpty()
  addressType: string;

  @IsString()
  @IsOptional()
  gstNumber?: string;

  @IsString()
  @IsOptional()
  panNumber?: string;

  @IsObject()
  @IsOptional()
  logisticsPOC?: {
    name: string;
    phone: string;
    email: string;
  };

  @IsObject()
  @IsOptional()
  financePOC?: {
    name: string;
    phone: string;
    email: string;
  };

  @IsString()
  @IsOptional()
  invoicingType?: string;

  @IsObject()
  @IsOptional()
  salesRep?: {
    name: string;
    phone: string;
    email: string;
  };
} 