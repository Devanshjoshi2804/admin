import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Vehicle } from './entities/vehicle.entity';
import { VehiclesController } from './vehicles.controller';
import { VehiclesService } from './vehicles.service';

@Module({
  imports: [TypeOrmModule.forFeature([Vehicle])],
  providers: [VehiclesService],
  controllers: [VehiclesController],
  exports: [TypeOrmModule, VehiclesService],
})
export class VehiclesModule {}
