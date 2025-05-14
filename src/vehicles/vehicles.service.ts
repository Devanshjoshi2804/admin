import { Injectable, NotFoundException } from '@nestjs/common';
import { Vehicle, CreateVehicleDto, UpdateVehicleDto } from './models/vehicle.model';

@Injectable()
export class VehiclesService {
  private vehicles: Vehicle[] = [
    {
      id: "VEH001",
      registrationNumber: "MH02AB1234",
      supplierId: "SUP001",
      supplierName: "Speedway Logistics",
      vehicleType: "Truck",
      vehicleSize: "32 ft",
      vehicleCapacity: "15 Tons",
      axleType: "Single Axle",
      driverName: "Ramesh Singh",
      driverPhone: "9876543222",
      insuranceExpiry: "2024-12-31"
    },
    {
      id: "VEH002",
      registrationNumber: "KA01CD5678",
      supplierId: "SUP002",
      supplierName: "Highway Transport Co",
      vehicleType: "Trailer",
      vehicleSize: "40 ft",
      vehicleCapacity: "25 Tons",
      axleType: "Multi Axle",
      driverName: "Mohan Kumar",
      driverPhone: "9876543223",
      insuranceExpiry: "2024-08-15"
    },
    {
      id: "VEH003",
      registrationNumber: "GJ05EF9012",
      supplierId: "SUP003",
      supplierName: "National Carriers",
      vehicleType: "Container",
      vehicleSize: "20 ft",
      vehicleCapacity: "10 Tons",
      axleType: "Single Axle",
      driverName: "Sanjay Patel",
      driverPhone: "9876543224",
      insuranceExpiry: "2025-03-22"
    }
  ];

  findAll(): Vehicle[] {
    return this.vehicles;
  }

  findOne(id: string): Vehicle {
    const vehicle = this.vehicles.find(vehicle => vehicle.id === id);
    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    return vehicle;
  }

  create(createVehicleDto: CreateVehicleDto): Vehicle {
    const newVehicle: Vehicle = {
      id: `VEH${this.generateVehicleId()}`,
      ...createVehicleDto,
    };
    this.vehicles.push(newVehicle);
    return newVehicle;
  }

  update(id: string, updateVehicleDto: UpdateVehicleDto): Vehicle {
    const vehicleIndex = this.vehicles.findIndex(vehicle => vehicle.id === id);
    if (vehicleIndex === -1) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    
    const updatedVehicle = {
      ...this.vehicles[vehicleIndex],
      ...updateVehicleDto,
    };
    
    this.vehicles[vehicleIndex] = updatedVehicle;
    return updatedVehicle;
  }

  remove(id: string): void {
    const vehicleIndex = this.vehicles.findIndex(vehicle => vehicle.id === id);
    if (vehicleIndex === -1) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    this.vehicles.splice(vehicleIndex, 1);
  }

  private generateVehicleId(): string {
    // Generate a random 3-digit number
    return Math.floor(100 + Math.random() * 900).toString();
  }
} 