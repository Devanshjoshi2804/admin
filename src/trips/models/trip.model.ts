export class Material {
  name: string;
  weight: number;
  unit: "MT" | "KG";
  ratePerMT: number;
}

export class Document {
  id: string;
  type: "LR" | "Invoice" | "E-waybill" | "POD";
  number: string;
  filename: string;
  uploadDate: string;
  expiryDate?: string;
}

export class EwayBill {
  number: string;
  validFrom: string;
  validUntil: string;
  expiryTime: string;
}

export interface Trip {
  id: string;
  orderNumber: string;
  lrNumbers: string[];
  clientId: string;
  clientName: string;
  clientAddress: string;
  clientAddressType: string;
  clientCity: string;
  destinationAddress: string;
  destinationCity: string;
  destinationAddressType: string;
  supplierId: string;
  supplierName: string;
  vehicleId: string;
  vehicleNumber: string;
  driverName: string;
  driverPhone: string;
  vehicleType: string;
  vehicleSize: string;
  vehicleCapacity: string;
  axleType: string;
  materials: Material[];
  pickupDate: string;
  pickupTime: string;
  clientFreight: number;
  supplierFreight: number;
  advancePercentage: number;
  advanceSupplierFreight: number;
  balanceSupplierFreight: number;
  documents: Document[];
  ewayBills: EwayBill[];
  fieldOps: {
    name: string;
    phone: string;
    email: string;
  };
  gsmTracking: boolean;
  status: "Booked" | "In Transit" | "Delivered" | "Completed";
  advancePaymentStatus: "Not Started" | "Initiated" | "Pending" | "Paid";
  balancePaymentStatus: "Not Started" | "Initiated" | "Pending" | "Paid";
  podUploaded: boolean;
  additionalCharges?: {
    description: string;
    amount: number;
  }[];
  deductionCharges?: {
    description: string;
    amount: number;
  }[];
  lrCharges?: number;
  platformFees?: number;
  utrNumber?: string;
  paymentMethod?: string;
  ifscCode?: string;
  createdAt: string | Date;
  updatedAt: string | Date;
  amountChanged?: boolean;
}

export class CreateTripDto {
  orderNumber?: string;
  lrNumbers: string[];
  clientId: string;
  clientName?: string;
  clientAddress: string;
  clientAddressType: string;
  clientCity: string;
  destinationAddress: string;
  destinationCity: string;
  destinationAddressType: string;
  supplierId: string;
  supplierName?: string;
  vehicleId: string;
  vehicleNumber: string;
  driverName: string;
  driverPhone: string;
  vehicleType: string;
  vehicleSize: string;
  vehicleCapacity: string;
  axleType: string;
  materials: Material[];
  pickupDate: string;
  pickupTime: string;
  clientFreight: number;
  supplierFreight: number;
  advancePercentage: number;
  fieldOps: {
    name: string;
    phone: string;
    email: string;
  };
  ewayBills?: EwayBill[];
  gsmTracking: boolean;
  status?: "Booked" | "In Transit" | "Delivered" | "Completed";
  advancePaymentStatus?: "Initiated" | "Pending" | "Paid" | "Not Started";
  balancePaymentStatus?: "Not Started" | "Initiated" | "Pending" | "Paid";
  lrCharges?: number;
}

export class UpdateTripDto {
  lrNumbers?: string[];
  destinationAddress?: string;
  destinationCity?: string;
  destinationAddressType?: string;
  vehicleId?: string;
  vehicleNumber?: string;
  driverName?: string;
  driverPhone?: string;
  vehicleType?: string;
  vehicleSize?: string;
  vehicleCapacity?: string;
  axleType?: string;
  materials?: Material[];
  pickupDate?: string;
  pickupTime?: string;
  clientFreight?: number;
  supplierFreight?: number;
  advancePercentage?: number;
  documents?: Document[];
  ewayBills?: EwayBill[];
  gsmTracking?: boolean;
  status?: "Booked" | "In Transit" | "Delivered" | "Completed";
  advancePaymentStatus?: "Initiated" | "Pending" | "Paid";
  balancePaymentStatus?: "Not Started" | "Initiated" | "Pending" | "Paid";
  podUploaded?: boolean;
  additionalCharges?: {
    description: string;
    amount: number;
  }[];
  deductionCharges?: {
    description: string;
    amount: number;
  }[];
  lrCharges?: number;
} 