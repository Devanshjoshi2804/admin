import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Supplier, SupplierSchema } from './schemas/supplier.schema';
import { SuppliersController } from './suppliers.controller';
import { SuppliersService } from './suppliers.service';

@Module({
  imports: [
    // MongoDB support
    MongooseModule.forFeature([{ name: Supplier.name, schema: SupplierSchema }])
  ],
  providers: [SuppliersService],
  controllers: [SuppliersController],
  exports: [MongooseModule, SuppliersService],
})
export class SuppliersModule {}
