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