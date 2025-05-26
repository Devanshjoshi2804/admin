import { IsDate, IsOptional, IsString, IsEnum, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

export class PaymentStatusDto {
  @IsString()
  @IsOptional()
  @IsEnum(['Not Started', 'Initiated', 'Pending', 'Paid'])
  advancePaymentStatus?: string;

  @IsString()
  @IsOptional()
  @IsEnum(['Not Started', 'Initiated', 'Pending', 'Paid'])
  balancePaymentStatus?: string;

  @IsString()
  @IsOptional()
  utrNumber?: string;

  @IsString()
  @IsOptional()
  @IsEnum(['Bank Transfer', 'NEFT', 'RTGS', 'UPI', 'Cash'])
  paymentMethod?: string;

  @IsDate()
  @Type(() => Date)
  @IsOptional()
  paymentDate?: Date;
}

export class ProcessPaymentDto {
  @IsString()
  @IsEnum(['advance', 'balance'])
  paymentType: 'advance' | 'balance';

  @IsString()
  @IsEnum(['Initiated', 'Pending', 'Paid'])
  paymentStatus: 'Initiated' | 'Pending' | 'Paid';

  @IsString()
  @IsOptional()
  utrNumber?: string;

  @IsString()
  @IsOptional()
  @IsEnum(['Bank Transfer', 'NEFT', 'RTGS', 'UPI', 'Cash'])
  paymentMethod?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}

export class UploadPODDto {
  @IsString()
  filename: string;

  @IsString()
  url: string;

  @IsBoolean()
  @IsOptional()
  isDownloadable?: boolean;
} 