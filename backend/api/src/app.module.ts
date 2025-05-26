import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ClientsModule } from './clients/clients.module';
import { SuppliersModule } from './suppliers/suppliers.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { TripsModule } from './trips/trips.module';
import { PaymentsModule } from './payments/payments.module';
import { DatabaseModule } from './database/database.module';

@Module({
  imports: [
    // MongoDB Connection
    MongooseModule.forRoot('mongodb://localhost:27017/freight_flow'),
    
    // Feature modules
    DatabaseModule,
    ClientsModule, 
    SuppliersModule, 
    VehiclesModule, 
    TripsModule,
    PaymentsModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

// This should run after the app initializes to add sample data
export async function seedDatabase(app) {
  // MongoDB seeding will be implemented in the DatabaseModule
  console.log('MongoDB seeding will be handled by DatabaseModule');
}
