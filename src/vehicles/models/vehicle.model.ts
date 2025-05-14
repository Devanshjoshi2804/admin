export class Vehicle {
  id: string;
  registrationNumber: string;
  supplierId: string;
  supplierName: string;
  vehicleType: string;
  vehicleSize: string;
  vehicleCapacity: string;
  axleType: string;
  driverName: string;
  driverPhone: string;
  insuranceExpiry: string;
}

export class CreateVehicleDto {
  registrationNumber: string;
  supplierId: string;
  supplierName: string;
  vehicleType: string;
  vehicleSize: string;
  vehicleCapacity: string;
  axleType: string;
  driverName: string;
  driverPhone: string;
  insuranceExpiry: string;
}

export class UpdateVehicleDto extends CreateVehicleDto {} 