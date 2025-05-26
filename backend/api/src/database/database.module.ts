import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Client, ClientSchema } from '../clients/schemas/client.schema';
import { Supplier, SupplierSchema } from '../suppliers/schemas/supplier.schema';
import { Vehicle, VehicleSchema } from '../vehicles/schemas/vehicle.schema';
import { Trip, TripSchema } from '../trips/schemas/trip.schema';
import { MongoSeeder } from './mongo-seeder';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Client.name, schema: ClientSchema },
      { name: Supplier.name, schema: SupplierSchema },
      { name: Vehicle.name, schema: VehicleSchema },
      { name: Trip.name, schema: TripSchema },
    ]),
  ],
  providers: [MongoSeeder],
  exports: [MongoSeeder],
})
export class DatabaseModule {} 