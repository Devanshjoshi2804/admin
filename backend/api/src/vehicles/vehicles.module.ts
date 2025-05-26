import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Vehicle, VehicleSchema } from './schemas/vehicle.schema';
import { VehiclesController } from './vehicles.controller';
import { VehiclesService } from './vehicles.service';

@Module({
  imports: [
    // MongoDB support
    MongooseModule.forFeature([{ name: Vehicle.name, schema: VehicleSchema }])
  ],
  providers: [VehiclesService],
  controllers: [VehiclesController],
  exports: [MongooseModule, VehiclesService],
})
export class VehiclesModule {}
