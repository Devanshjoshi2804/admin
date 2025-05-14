import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ClientsModule } from './clients/clients.module';
import { SuppliersModule } from './suppliers/suppliers.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { TripsModule } from './trips/trips.module';
import { join } from 'path';
import { Connection } from 'typeorm';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: join(process.cwd(), 'freight_flow.sqlite'),
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: true, // Set to false in production
      logging: true,
      extra: {
        // Enable foreign key constraints for proper database integrity
        pragma: [
          'PRAGMA foreign_keys = ON'
        ]
      }
    }),
    ClientsModule, 
    SuppliersModule, 
    VehiclesModule, 
    TripsModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

// This should run after the app initializes to add sample data
export async function seedDatabase(app) {
  const connection = app.get(Connection);
  
  try {
    // Check if we already have data
    const clientRepository = connection.getRepository('Client');
    const supplierRepository = connection.getRepository('Supplier');
    const vehicleRepository = connection.getRepository('Vehicle');
    
    const clientCount = await clientRepository.count();
    
    // Only seed if we have no clients
    if (clientCount === 0) {
      console.log('Seeding database with sample data...');
      
      // Create sample clients
      await clientRepository.save([
        {
          id: 'CL001',
          name: 'Tata Steel',
          address: '8th Floor, Bombay House, Homi Mody Street, Mumbai - 400001',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400001',
          contactName: 'Rajesh Sharma',
          contactPhone: '9876543210',
          contactEmail: 'rajesh.sharma@tatasteel.com',
          addressType: 'Corporate Office',
          creditDays: 30,
          status: 'Active'
        },
        {
          id: 'CL002',
          name: 'Reliance Industries',
          address: 'Maker Chambers IV, 222, Nariman Point, Mumbai - 400021',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400021',
          contactName: 'Priya Patel',
          contactPhone: '9876543211',
          contactEmail: 'priya.patel@ril.com',
          addressType: 'Warehouse',
          creditDays: 45,
          status: 'Active'
        }
      ]);
      
      // Create sample suppliers
      await supplierRepository.save([
        {
          id: 'SUP001',
          name: 'FastTrack Logistics',
          address: '123 Transport Nagar, Delhi - 110001',
          city: 'Delhi',
          state: 'Delhi',
          pincode: '110001',
          contactName: 'Amit Singh',
          contactPhone: '9876543212',
          contactEmail: 'amit@fasttrack.com',
          gstNumber: 'GSTIN1234567890',
          panNumber: 'PANCK1234D',
          bankDetails: JSON.stringify({
            accountNumber: '1234567890',
            bankName: 'HDFC Bank',
            ifscCode: 'HDFC0001234',
            accountHolderName: 'FastTrack Logistics'
          }),
          status: 'Active'
        },
        {
          id: 'SUP002',
          name: 'Highway Transport Co',
          address: '456 Transport Hub, Mumbai - 400018',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400018',
          contactName: 'Rahul Mehta',
          contactPhone: '9876543213',
          contactEmail: 'rahul@highwaytransport.com',
          gstNumber: 'GSTIN0987654321',
          panNumber: 'PANRM5678F',
          bankDetails: JSON.stringify({
            accountNumber: '0987654321',
            bankName: 'ICICI Bank',
            ifscCode: 'ICICI0004321',
            accountHolderName: 'Highway Transport Co'
          }),
          status: 'Active'
        }
      ]);
      
      // Create sample vehicles
      await vehicleRepository.save([
        {
          id: 'VEH001',
          supplierId: 'SUP001',
          registrationNumber: 'MH01AB1234',
          vehicleType: 'Open Body',
          vehicleSize: '20FT',
          vehicleCapacity: '10 Ton',
          axleType: 'Single',
          driverName: 'Rajesh Kumar',
          driverPhone: '9876543214',
          rcCopy: 'rc_copy_1.jpg',
          status: 'Active'
        },
        {
          id: 'VEH002',
          supplierId: 'SUP002',
          registrationNumber: 'MH02AB5678',
          vehicleType: 'Container',
          vehicleSize: '32FT Mxl',
          vehicleCapacity: '15 Ton',
          axleType: 'Multi',
          driverName: 'Sunil Kumar',
          driverPhone: '9876543215',
          rcCopy: 'rc_copy_2.jpg',
          status: 'Active'
        }
      ]);
      
      console.log('Database seeding completed successfully!');
    }
  } catch (error) {
    console.error('Error in seed function:', error);
  }
}
