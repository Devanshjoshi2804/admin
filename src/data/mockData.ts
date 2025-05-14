
// Mock data for the application

// Client data
export interface Client {
  id: string;
  name: string;
  city: string;
  address: string;
  addressType: string;
  gstNumber: string;
  panNumber: string;
  logisticsPOC: {
    name: string;
    phone: string;
    email: string;
  };
  financePOC: {
    name: string;
    phone: string;
    email: string;
  };
  invoicingType: string;
  salesRep: {
    name: string;
    designation: string;
    phone: string;
    email: string;
  };
}

export const clients: Client[] = [
  {
    id: "CL001",
    name: "Tata Steel Ltd",
    city: "Mumbai",
    address: "Bombay House, 24 Homi Mody Street, Fort, Mumbai - 400001",
    addressType: "Corporate Office",
    gstNumber: "27AAACT2727Q1ZW",
    panNumber: "AAACT2727Q",
    logisticsPOC: {
      name: "Rajesh Kumar",
      phone: "9876543210",
      email: "rajesh.kumar@tatasteel.com"
    },
    financePOC: {
      name: "Priya Sharma",
      phone: "9876543211",
      email: "priya.sharma@tatasteel.com"
    },
    invoicingType: "GST 18%",
    salesRep: {
      name: "Vikram Singh",
      designation: "Account Manager",
      phone: "9876543212",
      email: "vikram.singh@freightflow.com"
    }
  },
  {
    id: "CL002",
    name: "Reliance Industries",
    city: "Mumbai",
    address: "Maker Chambers IV, 222, Nariman Point, Mumbai - 400021",
    addressType: "Head Office",
    gstNumber: "27AAACR5055K1ZZ",
    panNumber: "AAACR5055K",
    logisticsPOC: {
      name: "Anand Patel",
      phone: "9876543213",
      email: "anand.patel@ril.com"
    },
    financePOC: {
      name: "Sunil Mehta",
      phone: "9876543214",
      email: "sunil.mehta@ril.com"
    },
    invoicingType: "GST 18%",
    salesRep: {
      name: "Deepak Gupta",
      designation: "Key Account Manager",
      phone: "9876543215",
      email: "deepak.gupta@freightflow.com"
    }
  },
  {
    id: "CL003",
    name: "Asian Paints Ltd",
    city: "Mumbai",
    address: "6A Shantinagar, Santacruz East, Mumbai - 400055",
    addressType: "Manufacturing Unit",
    gstNumber: "27AAACA6666Q1ZS",
    panNumber: "AAACA6666Q",
    logisticsPOC: {
      name: "Sanjay Mishra",
      phone: "9876543216",
      email: "sanjay.mishra@asianpaints.com"
    },
    financePOC: {
      name: "Neha Joshi",
      phone: "9876543217",
      email: "neha.joshi@asianpaints.com"
    },
    invoicingType: "GST 18%",
    salesRep: {
      name: "Rahul Verma",
      designation: "Senior Account Manager",
      phone: "9876543218",
      email: "rahul.verma@freightflow.com"
    }
  }
];

// Supplier data
export interface Supplier {
  id: string;
  name: string;
  city: string;
  address: string;
  contactPerson: {
    name: string;
    phone: string;
    email: string;
  };
  bankDetails: {
    bankName: string;
    accountNumber: string;
    ifscCode: string;
    accountType: string;
  };
  gstNumber: string;
}

export const suppliers: Supplier[] = [
  {
    id: "SUP001",
    name: "Speedway Logistics",
    city: "Delhi",
    address: "123, Transport Nagar, Delhi - 110001",
    contactPerson: {
      name: "Ravi Sharma",
      phone: "9876543219",
      email: "ravi@speedwaylogistics.com"
    },
    bankDetails: {
      bankName: "HDFC Bank",
      accountNumber: "50100123456789",
      ifscCode: "HDFC0001234",
      accountType: "Current"
    },
    gstNumber: "07AABCS1234A1ZX"
  },
  {
    id: "SUP002",
    name: "Highway Transport Co",
    city: "Mumbai",
    address: "456, Truck Terminal, Vashi, Navi Mumbai - 400705",
    contactPerson: {
      name: "Suresh Patel",
      phone: "9876543220",
      email: "suresh@highwaytransport.com"
    },
    bankDetails: {
      bankName: "ICICI Bank",
      accountNumber: "12345678901234",
      ifscCode: "ICIC0001234",
      accountType: "Current"
    },
    gstNumber: "27AADCH5678B1ZY"
  },
  {
    id: "SUP003",
    name: "National Carriers",
    city: "Ahmedabad",
    address: "789, Transport Hub, Ahmedabad - 380001",
    contactPerson: {
      name: "Manoj Kumar",
      phone: "9876543221",
      email: "manoj@nationalcarriers.com"
    },
    bankDetails: {
      bankName: "State Bank of India",
      accountNumber: "35678912345670",
      ifscCode: "SBIN0012345",
      accountType: "Current"
    },
    gstNumber: "24AAGCN9101C1ZZ"
  }
];

// Vehicle data
export interface Vehicle {
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

export const vehicles: Vehicle[] = [
  {
    id: "VEH001",
    registrationNumber: "DL1GC1234",
    supplierId: "SUP001",
    supplierName: "Speedway Logistics",
    vehicleType: "Truck",
    vehicleSize: "32FT Sxl",
    vehicleCapacity: "12 Ton",
    axleType: "Single",
    driverName: "Ramesh Yadav",
    driverPhone: "9876543222",
    insuranceExpiry: "2025-12-31"
  },
  {
    id: "VEH002",
    registrationNumber: "MH02AB5678",
    supplierId: "SUP002",
    supplierName: "Highway Transport Co",
    vehicleType: "Container",
    vehicleSize: "32FT Mxl",
    vehicleCapacity: "15 Ton",
    axleType: "Multi",
    driverName: "Sunil Kumar",
    driverPhone: "9876543223",
    insuranceExpiry: "2025-10-15"
  },
  {
    id: "VEH003",
    registrationNumber: "GJ05CD9012",
    supplierId: "SUP003",
    supplierName: "National Carriers",
    vehicleType: "Trailer",
    vehicleSize: "40FT",
    vehicleCapacity: "25 Ton",
    axleType: "Multi",
    driverName: "Prakash Singh",
    driverPhone: "9876543224",
    insuranceExpiry: "2026-03-22"
  }
];

// Booking/Trip data
export interface Material {
  name: string;
  weight: number;
  unit: "MT" | "KG";
  ratePerMT: number;
}

export interface Document {
  id: string;
  type: "LR" | "Invoice" | "E-waybill" | "POD";
  number: string;
  filename: string;
  uploadDate: string;
  expiryDate?: string;
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
  fieldOps: {
    name: string;
    phone: string;
    email: string;
  };
  gsmTracking: boolean;
  status: "Booked" | "In Transit" | "Delivered" | "Completed";
  advancePaymentStatus: "Initiated" | "Pending" | "Paid";
  balancePaymentStatus: "Not Started" | "Initiated" | "Pending" | "Paid";
  podUploaded: boolean;
  createdAt: string;
}

export const trips: Trip[] = [
  {
    id: "TRP001",
    orderNumber: "FTL-20250420-001",
    lrNumbers: ["LR12345678"],
    clientId: "CL001",
    clientName: "Tata Steel Ltd",
    clientAddress: "Bombay House, 24 Homi Mody Street, Fort, Mumbai - 400001",
    clientAddressType: "Corporate Office",
    clientCity: "Mumbai",
    destinationAddress: "Tata Steel Plant, Jamshedpur, Jharkhand - 831001",
    destinationCity: "Jamshedpur",
    destinationAddressType: "Manufacturing Plant",
    supplierId: "SUP001",
    supplierName: "Speedway Logistics",
    vehicleId: "VEH001",
    vehicleNumber: "DL1GC1234",
    driverName: "Ramesh Yadav",
    driverPhone: "9876543222",
    vehicleType: "Truck",
    vehicleSize: "32FT Sxl",
    vehicleCapacity: "12 Ton",
    axleType: "Single",
    materials: [
      {
        name: "Steel Coils",
        weight: 10,
        unit: "MT",
        ratePerMT: 1500
      }
    ],
    pickupDate: "2025-04-25",
    pickupTime: "09:00",
    clientFreight: 15000,
    supplierFreight: 12000,
    advancePercentage: 40,
    advanceSupplierFreight: 4800,
    balanceSupplierFreight: 7200,
    documents: [
      {
        id: "DOC001",
        type: "LR",
        number: "LR12345678",
        filename: "lr_12345678.pdf",
        uploadDate: "2025-04-20"
      },
      {
        id: "DOC002",
        type: "Invoice",
        number: "INV98765432",
        filename: "invoice_98765432.pdf",
        uploadDate: "2025-04-20"
      },
      {
        id: "DOC003",
        type: "E-waybill",
        number: "EWB123456789012",
        filename: "ewb_123456789012.pdf",
        uploadDate: "2025-04-20",
        expiryDate: "2025-04-26"
      }
    ],
    fieldOps: {
      name: "Amit Verma",
      phone: "9876543225",
      email: "amit.verma@freightflow.com"
    },
    gsmTracking: true,
    status: "Booked",
    advancePaymentStatus: "Initiated",
    balancePaymentStatus: "Not Started",
    podUploaded: false,
    createdAt: "2025-04-20T10:30:00"
  },
  {
    id: "TRP002",
    orderNumber: "FTL-20250420-002",
    lrNumbers: ["LR87654321"],
    clientId: "CL002",
    clientName: "Reliance Industries",
    clientAddress: "Maker Chambers IV, 222, Nariman Point, Mumbai - 400021",
    clientAddressType: "Head Office",
    clientCity: "Mumbai",
    destinationAddress: "Reliance Refinery, Jamnagar, Gujarat - 361142",
    destinationCity: "Jamnagar",
    destinationAddressType: "Refinery",
    supplierId: "SUP002",
    supplierName: "Highway Transport Co",
    vehicleId: "VEH002",
    vehicleNumber: "MH02AB5678",
    driverName: "Sunil Kumar",
    driverPhone: "9876543223",
    vehicleType: "Container",
    vehicleSize: "32FT Mxl",
    vehicleCapacity: "15 Ton",
    axleType: "Multi",
    materials: [
      {
        name: "Chemical Drums",
        weight: 12,
        unit: "MT",
        ratePerMT: 2000
      },
      {
        name: "Equipment Parts",
        weight: 3,
        unit: "MT",
        ratePerMT: 2500
      }
    ],
    pickupDate: "2025-04-26",
    pickupTime: "14:00",
    clientFreight: 31500,
    supplierFreight: 25000,
    advancePercentage: 50,
    advanceSupplierFreight: 12500,
    balanceSupplierFreight: 12500,
    documents: [
      {
        id: "DOC004",
        type: "LR",
        number: "LR87654321",
        filename: "lr_87654321.pdf",
        uploadDate: "2025-04-21"
      },
      {
        id: "DOC005",
        type: "Invoice",
        number: "INV12345678",
        filename: "invoice_12345678.pdf",
        uploadDate: "2025-04-21"
      },
      {
        id: "DOC006",
        type: "E-waybill",
        number: "EWB987654321012",
        filename: "ewb_987654321012.pdf",
        uploadDate: "2025-04-21",
        expiryDate: "2025-04-27"
      }
    ],
    fieldOps: {
      name: "Sunita Sharma",
      phone: "9876543226",
      email: "sunita.sharma@freightflow.com"
    },
    gsmTracking: true,
    status: "In Transit",
    advancePaymentStatus: "Paid",
    balancePaymentStatus: "Not Started",
    podUploaded: false,
    createdAt: "2025-04-21T09:15:00"
  }
];

// Options lists for dropdowns
export const vehicleTypes = ["Container", "Truck", "Trailer"];
export const vehicleSizes = ["32FT Sxl", "32FT Mxl", "24FT", "40FT"];
export const vehicleCapacities = ["7 Ton", "9 Ton", "10 Ton", "12 Ton", "15 Ton", "18 Ton", "25 Ton", "30 Ton", "35 Ton", "40 Ton"];
export const axleTypes = ["Single", "Multi"];
export const materialTypes = ["Steel Coils", "Chemical Drums", "Equipment Parts", "Consumer Goods", "Automobile Parts", "Food Products", "Textile", "Construction Material", "Electronics", "Furniture"];
export const weightUnits = ["MT", "KG"];
export const addressTypes = ["Corporate Office", "Manufacturing Plant", "Warehouse", "Distribution Center", "Retail Store", "Refinery"];
export const invoicingTypes = ["GST 18%", "GST 12%", "GST 5%", "RCM", "Exempted"];
export const paymentStatuses = ["Initiated", "Pending", "Paid"];
export const tripStatuses = ["Booked", "In Transit", "Delivered", "Completed"];
