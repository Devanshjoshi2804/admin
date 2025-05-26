import { IsArray, IsNumber, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ChargeDto {
  @IsString()
  description: string;

  @IsNumber()
  amount: number;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class UpdateAdditionalChargesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChargeDto)
  additionalCharges: ChargeDto[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChargeDto)
  deductionCharges: ChargeDto[];

  @IsNumber()
  newBalanceAmount: number;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsString()
  addedBy?: string;
} 