import { Injectable, NotFoundException } from '@nestjs/common';
import { Supplier, CreateSupplierDto, UpdateSupplierDto } from './models/supplier.model';

@Injectable()
export class SuppliersService {
  private suppliers: Supplier[] = [
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

  findAll(): Supplier[] {
    return this.suppliers;
  }

  findOne(id: string): Supplier {
    const supplier = this.suppliers.find(supplier => supplier.id === id);
    if (!supplier) {
      throw new NotFoundException(`Supplier with ID ${id} not found`);
    }
    return supplier;
  }

  create(createSupplierDto: CreateSupplierDto): Supplier {
    const newSupplier: Supplier = {
      id: `SUP${this.generateSupplierId()}`,
      ...createSupplierDto,
    };
    this.suppliers.push(newSupplier);
    return newSupplier;
  }

  update(id: string, updateSupplierDto: UpdateSupplierDto): Supplier {
    const supplierIndex = this.suppliers.findIndex(supplier => supplier.id === id);
    if (supplierIndex === -1) {
      throw new NotFoundException(`Supplier with ID ${id} not found`);
    }
    
    const updatedSupplier = {
      ...this.suppliers[supplierIndex],
      ...updateSupplierDto,
    };
    
    this.suppliers[supplierIndex] = updatedSupplier;
    return updatedSupplier;
  }

  remove(id: string): void {
    const supplierIndex = this.suppliers.findIndex(supplier => supplier.id === id);
    if (supplierIndex === -1) {
      throw new NotFoundException(`Supplier with ID ${id} not found`);
    }
    this.suppliers.splice(supplierIndex, 1);
  }

  private generateSupplierId(): string {
    // Generate a random 3-digit number
    return Math.floor(100 + Math.random() * 900).toString();
  }
} 