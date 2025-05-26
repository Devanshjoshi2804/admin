import { IsEmail, IsNotEmpty, MinLength, IsOptional, IsIn } from 'class-validator';

export class CreateUserDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsIn(['admin', 'manager', 'operator', 'user'])
  role?: string;

  @IsOptional()
  phone?: string;
} 