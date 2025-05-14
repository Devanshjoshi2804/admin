import { Injectable, NotFoundException } from '@nestjs/common';
import { Trip, CreateTripDto, UpdateTripDto } from './models/trip.model';

@Injectable()
export class TripsService {
  private trips: Trip[] = [
    {
      id: "TRP001",
      orderNumber: "FTL-123456",
      lrNumbers: ["LR12345"],
      clientId: "CL001",
      clientName: "Tata Steel Ltd",
      clientAddress: "Bombay House, 24 Homi Mody Street, Fort, Mumbai - 400001",
      clientAddressType: "Corporate Office",
      clientCity: "Mumbai",
      destinationAddress: "Plot No. 45-A, MIDC Industrial Area, Taloja, Maharashtra - 410208",
      destinationCity: "Navi Mumbai",
      destinationAddressType: "Factory",
      supplierId: "SUP001",
      supplierName: "Speedway Logistics",
      vehicleId: "VEH001",
      vehicleNumber: "MH02AB1234",
      driverName: "Ramesh Singh",
      driverPhone: "9876543222",
      vehicleType: "Truck",
      vehicleSize: "32 ft",
      vehicleCapacity: "15 Tons",
      axleType: "Single Axle",
      materials: [
        {
          name: "Steel Coils",
          weight: 10,
          unit: "MT",
          ratePerMT: 5000
        }
      ],
      pickupDate: "2023-07-01",
      pickupTime: "10:30",
      clientFreight: 50000,
      supplierFreight: 45000,
      advancePercentage: 30,
      advanceSupplierFreight: 13500,
      balanceSupplierFreight: 31500,
      documents: [],
      fieldOps: {
        name: "Ajay Sharma",
        phone: "9876543225",
        email: "ajay.sharma@freightflow.com"
      },
      gsmTracking: true,
      status: "In Transit",
      advancePaymentStatus: "Paid",
      balancePaymentStatus: "Not Started",
      podUploaded: false,
      createdAt: "2023-06-30T10:15:00Z"
    },
    {
      id: "TRP002",
      orderNumber: "FTL-123457",
      lrNumbers: ["LR12346"],
      clientId: "CL002",
      clientName: "Reliance Industries",
      clientAddress: "Maker Chambers IV, 222, Nariman Point, Mumbai - 400021",
      clientAddressType: "Head Office",
      clientCity: "Mumbai",
      destinationAddress: "Plot No. 1, Reliance Refinery Complex, Jamnagar, Gujarat - 361142",
      destinationCity: "Jamnagar",
      destinationAddressType: "Refinery",
      supplierId: "SUP002",
      supplierName: "Highway Transport Co",
      vehicleId: "VEH002",
      vehicleNumber: "KA01CD5678",
      driverName: "Mohan Kumar",
      driverPhone: "9876543223",
      vehicleType: "Trailer",
      vehicleSize: "40 ft",
      vehicleCapacity: "25 Tons",
      axleType: "Multi Axle",
      materials: [
        {
          name: "Chemical Drums",
          weight: 15,
          unit: "MT",
          ratePerMT: 6000
        }
      ],
      pickupDate: "2023-07-02",
      pickupTime: "08:45",
      clientFreight: 90000,
      supplierFreight: 80000,
      advancePercentage: 40,
      advanceSupplierFreight: 32000,
      balanceSupplierFreight: 48000,
      documents: [],
      fieldOps: {
        name: "Rajan Patel",
        phone: "9876543226",
        email: "rajan.patel@freightflow.com"
      },
      gsmTracking: true,
      status: "Booked",
      advancePaymentStatus: "Initiated",
      balancePaymentStatus: "Not Started",
      podUploaded: false,
      createdAt: "2023-07-01T14:30:00Z"
    }
  ];

  findAll(): Trip[] {
    return this.trips;
  }

  findOne(id: string): Trip {
    const trip = this.trips.find(trip => trip.id === id);
    if (!trip) {
      throw new NotFoundException(`Trip with ID ${id} not found`);
    }
    return trip;
  }

  create(createTripDto: CreateTripDto): Trip {
    // Generate order number if not provided
    const orderNumber = createTripDto.orderNumber || `FTL-${this.generateOrderNumber()}`;
    
    // Calculate advance/balance based on supplier freight and advance percentage
    const advanceSupplierFreight = Math.round(createTripDto.supplierFreight * (createTripDto.advancePercentage / 100));
    const balanceSupplierFreight = createTripDto.supplierFreight - advanceSupplierFreight;
    
    const newTrip: Trip = {
      id: `TRP${this.generateTripId()}`,
      orderNumber,
      ...createTripDto,
      advanceSupplierFreight,
      balanceSupplierFreight,
      documents: [],
      fieldOps: {
        name: "Operations Team",
        phone: "9876543200",
        email: "ops@freightflow.com"
      },
      status: "Booked",
      advancePaymentStatus: "Initiated",
      balancePaymentStatus: "Not Started",
      podUploaded: false,
      createdAt: new Date().toISOString()
    };
    
    this.trips.push(newTrip);
    return newTrip;
  }

  update(id: string, updateTripDto: UpdateTripDto): Trip {
    const tripIndex = this.trips.findIndex(trip => trip.id === id);
    if (tripIndex === -1) {
      throw new NotFoundException(`Trip with ID ${id} not found`);
    }
    
    const trip = this.trips[tripIndex];
    
    // Recalculate advance/balance if necessary
    let advanceSupplierFreight = trip.advanceSupplierFreight;
    let balanceSupplierFreight = trip.balanceSupplierFreight;
    
    if (updateTripDto.supplierFreight !== undefined || updateTripDto.advancePercentage !== undefined) {
      const supplierFreight = updateTripDto.supplierFreight ?? trip.supplierFreight;
      const advancePercentage = updateTripDto.advancePercentage ?? trip.advancePercentage;
      
      advanceSupplierFreight = Math.round(supplierFreight * (advancePercentage / 100));
      balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
    }
    
    const updatedTrip = {
      ...trip,
      ...updateTripDto,
      advanceSupplierFreight,
      balanceSupplierFreight
    };
    
    this.trips[tripIndex] = updatedTrip;
    return updatedTrip;
  }

  remove(id: string): void {
    const tripIndex = this.trips.findIndex(trip => trip.id === id);
    if (tripIndex === -1) {
      throw new NotFoundException(`Trip with ID ${id} not found`);
    }
    this.trips.splice(tripIndex, 1);
  }

  private generateTripId(): string {
    // Generate a random 3-digit number
    return Math.floor(100 + Math.random() * 900).toString();
  }

  private generateOrderNumber(): string {
    // Generate a random 6-digit number
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
} 