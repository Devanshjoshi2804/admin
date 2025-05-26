import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Client } from '../clients/schemas/client.schema';
import { Supplier } from '../suppliers/schemas/supplier.schema';
import { Vehicle } from '../vehicles/schemas/vehicle.schema';
import { Trip } from '../trips/schemas/trip.schema';

@Injectable()
export class MongoSeeder {
  constructor(
    @InjectModel(Client.name)
    private readonly clientModel: Model<Client>,
    
    @InjectModel(Supplier.name)
    private readonly supplierModel: Model<Supplier>,
    
    @InjectModel(Vehicle.name)
    private readonly vehicleModel: Model<Vehicle>,
    
    @InjectModel(Trip.name)
    private readonly tripModel: Model<Trip>,
  ) {}

  async seed() {
    try {
      // Check if we already have data
      const clientCount = await this.clientModel.countDocuments().exec();
      const supplierCount = await this.supplierModel.countDocuments().exec();
      const vehicleCount = await this.vehicleModel.countDocuments().exec();
      const tripCount = await this.tripModel.countDocuments().exec();
      
      // Only seed if we have no clients
      if (clientCount === 0) {
        console.log('Seeding MongoDB with sample client data...');
        
        // Create sample clients
        await this.clientModel.insertMany([
          {
            id: 'CL001',
            name: 'Tata Steel Ltd',
            address: '8th Floor, Bombay House, Homi Mody Street, Mumbai - 400001',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400001',
            addressType: 'Corporate Office',
            gstNumber: '27AAACT2727Q1ZW',
            panNumber: 'AAACT2727Q',
            logisticsPOC: {
              name: 'Rajesh Kumar',
              phone: '9876543210',
              email: 'rajesh.kumar@tatasteel.com'
            },
            financePOC: {
              name: 'Priya Sharma',
              phone: '9876543211',
              email: 'priya.sharma@tatasteel.com'
            },
            invoicingType: 'Digital',
            salesRep: {
              name: 'Vikram Singh',
              phone: '9876543212',
              email: 'vikram.singh@freightflow.com'
            },
            status: 'Active'
          },
          {
            id: 'CL002',
            name: 'Reliance Industries',
            address: 'Maker Chambers IV, 222, Nariman Point, Mumbai - 400021',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400021',
            addressType: 'Warehouse',
            gstNumber: '27AAACR5009K1ZZ',
            panNumber: 'AAACR5009K',
            logisticsPOC: {
              name: 'Anand Patel',
              phone: '9876543213',
              email: 'anand.patel@ril.com'
            },
            financePOC: {
              name: 'Sunil Mehta',
              phone: '9876543214',
              email: 'sunil.mehta@ril.com'
            },
            invoicingType: 'Physical',
            salesRep: {
              name: 'Rahul Verma',
              phone: '9876543215',
              email: 'rahul.verma@freightflow.com'
            },
            status: 'Active'
          },
          {
            id: 'CL003',
            name: 'Asian Paints Ltd',
            address: '6A, Shantinagar, Santacruz (E), Mumbai - 400055',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400055',
            addressType: 'Factory',
            gstNumber: '27AAACA6666Q1ZS',
            panNumber: 'AAACA6666Q',
            logisticsPOC: {
              name: 'Sanjay Mishra',
              phone: '9876543216',
              email: 'sanjay.mishra@asianpaints.com'
            },
            financePOC: {
              name: 'Neha Joshi',
              phone: '9876543217',
              email: 'neha.joshi@asianpaints.com'
            },
            invoicingType: 'Digital',
            salesRep: {
              name: 'Deepak Kumar',
              phone: '9876543218',
              email: 'deepak.kumar@freightflow.com'
            },
            status: 'Active'
          }
        ]);
        
        console.log('MongoDB client seeding completed successfully!');
      }
      
      // Only seed suppliers if we have none
      if (supplierCount === 0) {
        console.log('Seeding MongoDB with sample supplier data...');
        
        // Create sample suppliers
        await this.supplierModel.insertMany([
          {
            id: 'SP001',
            name: 'Mahindra Logistics',
            address: '1A & 1B, 4th Floor, Techniplex I, Veer Savarkar Flyover, Goregaon (West), Mumbai - 400062',
            city: 'Mumbai',
            state: 'Maharashtra',
            pincode: '400062',
            gstNumber: '27AABCT1674Q1ZX',
            panNumber: 'AABCT1674Q',
            contactPerson: {
              name: 'Vikram Sharma',
              phone: '9876543220',
              email: 'vikram.sharma@mahindralogistics.com'
            },
            accountDetails: {
              bankName: 'HDFC Bank',
              accountNumber: '50100023456789',
              ifscCode: 'HDFC0001234',
              accountHolderName: 'Mahindra Logistics Ltd'
            },
            vehicleTypes: ['LCV', 'HCV', 'Trailer'],
            status: 'Active'
          },
          {
            id: 'SP002',
            name: 'TCI Freight',
            address: 'TCI House, 69 Institutional Area, Sector 32, Gurugram - 122001',
            city: 'Gurugram',
            state: 'Haryana',
            pincode: '122001',
            gstNumber: '06AABCT1674Q2ZY',
            panNumber: 'AABCT1674Q',
            contactPerson: {
              name: 'Rajesh Agarwal',
              phone: '9876543221',
              email: 'rajesh.agarwal@tcifreight.com'
            },
            accountDetails: {
              bankName: 'ICICI Bank',
              accountNumber: '123456789012',
              ifscCode: 'ICIC0001234',
              accountHolderName: 'Transport Corporation of India Ltd'
            },
            vehicleTypes: ['LCV', 'HCV', 'Container'],
            status: 'Active'
          },
          {
            id: 'SP003',
            name: 'Safexpress',
            address: '28, Udyog Vihar, Phase IV, Gurugram - 122015',
            city: 'Gurugram',
            state: 'Haryana',
            pincode: '122015',
            gstNumber: '06AAECS5762G1ZD',
            panNumber: 'AAECS5762G',
            contactPerson: {
              name: 'Amit Singh',
              phone: '9876543222',
              email: 'amit.singh@safexpress.com'
            },
            accountDetails: {
              bankName: 'Axis Bank',
              accountNumber: '987654321012',
              ifscCode: 'UTIB0001234',
              accountHolderName: 'Safexpress Pvt Ltd'
            },
            vehicleTypes: ['LCV', 'HCV'],
            status: 'Active'
          }
        ]);
        
        console.log('MongoDB supplier seeding completed successfully!');
      }
      
      // Only seed vehicles if we have none
      if (vehicleCount === 0) {
        console.log('Seeding MongoDB with sample vehicle data...');
        
        // Create sample vehicles
        await this.vehicleModel.insertMany([
          {
            id: 'VH001',
            registrationNumber: 'MH02AB1234',
            type: 'LCV',
            capacity: '3.5 Ton',
            dimensions: '14ft x 7ft x 7ft',
            supplierId: 'SP001',
            supplierName: 'Mahindra Logistics',
            driverName: 'Ramesh Kumar',
            driverPhone: '9876543230',
            insuranceExpiryDate: new Date('2024-12-31'),
            pucExpiryDate: new Date('2024-06-30'),
            fitnessExpiryDate: new Date('2024-09-30'),
            permitExpiryDate: new Date('2024-10-31'),
            status: 'Active'
          },
          {
            id: 'VH002',
            registrationNumber: 'HR55CD5678',
            type: 'HCV',
            capacity: '16 Ton',
            dimensions: '24ft x 8ft x 8ft',
            supplierId: 'SP002',
            supplierName: 'TCI Freight',
            driverName: 'Suresh Yadav',
            driverPhone: '9876543231',
            insuranceExpiryDate: new Date('2024-11-30'),
            pucExpiryDate: new Date('2024-07-31'),
            fitnessExpiryDate: new Date('2024-08-31'),
            permitExpiryDate: new Date('2024-12-31'),
            status: 'Active'
          },
          {
            id: 'VH003',
            registrationNumber: 'DL01EF9012',
            type: 'Container',
            capacity: '20 ft',
            dimensions: '20ft x 8ft x 8.5ft',
            supplierId: 'SP003',
            supplierName: 'Safexpress',
            driverName: 'Mahesh Singh',
            driverPhone: '9876543232',
            insuranceExpiryDate: new Date('2024-10-31'),
            pucExpiryDate: new Date('2024-08-31'),
            fitnessExpiryDate: new Date('2024-07-31'),
            permitExpiryDate: new Date('2024-11-30'),
            status: 'Active'
          }
        ]);
        
        console.log('MongoDB vehicle seeding completed successfully!');
      }
      
      // Only seed trips if we have none
      if (tripCount === 0) {
        console.log('Seeding MongoDB with sample trip data...');
        
        // Create sample trips
        await this.tripModel.insertMany([
          {
            id: 'TR001',
            clientId: 'CL001',
            clientName: 'Tata Steel Ltd',
            vehicleId: 'VH001',
            vehicleNumber: 'MH02AB1234',
            vehicleType: 'LCV',
            supplierId: 'SP001',
            supplierName: 'Mahindra Logistics',
            source: 'Mumbai',
            destination: 'Pune',
            distance: 150,
            startDate: new Date('2024-05-15'),
            endDate: new Date('2024-05-16'),
            loadingDate: new Date('2024-05-15T10:00:00'),
            unloadingDate: new Date('2024-05-16T14:00:00'),
            pricing: {
              baseAmount: 15000,
              gst: 2700,
              totalAmount: 17700
            },
            documents: [
              {
                type: 'E-Way Bill',
                url: 'https://example.com/ewb001.pdf',
                uploadedAt: new Date('2024-05-14')
              },
              {
                type: 'Invoice',
                url: 'https://example.com/inv001.pdf',
                uploadedAt: new Date('2024-05-16')
              }
            ],
            status: 'Completed',
            notes: 'Delivery completed on time'
          },
          {
            id: 'TR002',
            clientId: 'CL002',
            clientName: 'Reliance Industries',
            vehicleId: 'VH002',
            vehicleNumber: 'HR55CD5678',
            vehicleType: 'HCV',
            supplierId: 'SP002',
            supplierName: 'TCI Freight',
            source: 'Mumbai',
            destination: 'Delhi',
            distance: 1400,
            startDate: new Date('2024-05-18'),
            endDate: new Date('2024-05-22'),
            loadingDate: new Date('2024-05-18T09:00:00'),
            pricing: {
              baseAmount: 45000,
              gst: 8100,
              totalAmount: 53100
            },
            documents: [
              {
                type: 'E-Way Bill',
                url: 'https://example.com/ewb002.pdf',
                uploadedAt: new Date('2024-05-17')
              }
            ],
            status: 'In Transit',
            notes: 'Vehicle left Mumbai on schedule'
          },
          {
            id: 'TR003',
            clientId: 'CL003',
            clientName: 'Asian Paints Ltd',
            vehicleId: 'VH003',
            vehicleNumber: 'DL01EF9012',
            vehicleType: 'Container',
            supplierId: 'SP003',
            supplierName: 'Safexpress',
            source: 'Mumbai',
            destination: 'Bangalore',
            distance: 980,
            startDate: new Date('2024-05-25'),
            pricing: {
              baseAmount: 35000,
              gst: 6300,
              totalAmount: 41300
            },
            status: 'Scheduled',
            notes: 'Pickup scheduled for 9 AM'
          }
        ]);
        
        console.log('MongoDB trip seeding completed successfully!');
      }
    } catch (error) {
      console.error('Error in MongoDB seed function:', error);
    }
  }
} 