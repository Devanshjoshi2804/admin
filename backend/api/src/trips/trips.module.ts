import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TripsService } from './trips.service';
import { TripsController } from './trips.controller';
import { Trip, TripSchema } from './schemas/trip.schema';

@Module({
  imports: [
    // MongoDB support
    MongooseModule.forFeature([{ name: Trip.name, schema: TripSchema }])
  ],
  controllers: [TripsController],
  providers: [TripsService],
  exports: [MongooseModule, TripsService],
})
export class TripsModule {}
