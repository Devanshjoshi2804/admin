import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Supplier, SupplierDocument } from './schemas/supplier.schema';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { UpdateSupplierDto } from './dto/update-supplier.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class SuppliersService {
  private readonly logger = new Logger(SuppliersService.name);

  constructor(
    @InjectModel(Supplier.name)
    private supplierModel: Model<SupplierDocument>,
  ) {}

  async create(createSupplierDto: CreateSupplierDto): Promise<Supplier> {
    try {
      // Generate a unique ID if not provided
      const supplierId = createSupplierDto.id || `SP${uuidv4().substring(0, 8).toUpperCase()}`;
      
      // Process the data to handle both formats (nested objects and flat structure)
      const supplierData: any = {
        ...createSupplierDto,
        id: supplierId,
      };
      
      // Handle pinCode/pincode field mapping for backward compatibility
      if (supplierData.pinCode && !supplierData.pincode) {
        supplierData.pincode = supplierData.pinCode;
      }
      if (supplierData.pincode && !supplierData.pinCode) {
        supplierData.pinCode = supplierData.pincode;
      }
      
      // Handle contact person data
      if (!supplierData.contactName && supplierData.contactPerson) {
        supplierData.contactName = supplierData.contactPerson.name;
        supplierData.contactPhone = supplierData.contactPerson.phone;
        supplierData.contactEmail = supplierData.contactPerson.email;
      }
      
      // Handle account details
      if (!supplierData.bankName && supplierData.accountDetails) {
        supplierData.bankName = supplierData.accountDetails.bankName;
        supplierData.accountNumber = supplierData.accountDetails.accountNumber;
        supplierData.ifscCode = supplierData.accountDetails.ifscCode;
        supplierData.accountHolderName = supplierData.accountDetails.accountHolderName;
        supplierData.accountType = supplierData.accountDetails.accountType;
      }
      
      this.logger.log(`Creating new supplier: ${supplierData.name} (${supplierId})`);
      
      // Create the MongoDB document
      const newSupplier = new this.supplierModel(supplierData);
      
      // Save to MongoDB
      const savedSupplier = await newSupplier.save();
      this.logger.log(`Supplier created successfully: ${savedSupplier.id}`);
      return savedSupplier;
    } catch (error) {
      this.logger.error(`Error creating supplier: ${error.message}`, error.stack);
      if (error.code === 11000) {
        throw new BadRequestException('Supplier with this ID already exists');
      }
      throw new BadRequestException(`Failed to create supplier: ${error.message}`);
    }
  }

  async findAll(): Promise<Supplier[]> {
    try {
      this.logger.log('Fetching all suppliers');
      // Get suppliers from MongoDB
      return this.supplierModel.find().sort({ name: 1 }).exec();
    } catch (error) {
      this.logger.error(`Error fetching suppliers: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to fetch suppliers: ${error.message}`);
    }
  }

  async findOne(id: string): Promise<Supplier> {
    try {
      this.logger.log(`Fetching supplier with ID: ${id}`);
      const supplier = await this.supplierModel.findOne({ id }).exec();
      if (!supplier) {
        this.logger.warn(`Supplier with ID ${id} not found`);
        throw new NotFoundException(`Supplier with ID ${id} not found`);
      }
      return supplier;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error fetching supplier ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to fetch supplier: ${error.message}`);
    }
  }

  async update(id: string, updateSupplierDto: UpdateSupplierDto): Promise<Supplier> {
    try {
      this.logger.log(`Updating supplier with ID: ${id}`);
      
      // Process the data to handle both formats (nested objects and flat structure)
      const supplierData: any = {
        ...updateSupplierDto,
      };
      
      // Handle pinCode/pincode field mapping for backward compatibility
      if (supplierData.pinCode && !supplierData.pincode) {
        supplierData.pincode = supplierData.pinCode;
      }
      if (supplierData.pincode && !supplierData.pinCode) {
        supplierData.pinCode = supplierData.pincode;
      }
      
      // Handle contact person data
      if (!supplierData.contactName && supplierData.contactPerson) {
        supplierData.contactName = supplierData.contactPerson.name;
        supplierData.contactPhone = supplierData.contactPerson.phone;
        supplierData.contactEmail = supplierData.contactPerson.email;
      }
      
      // Handle account details
      if (!supplierData.bankName && supplierData.accountDetails) {
        supplierData.bankName = supplierData.accountDetails.bankName;
        supplierData.accountNumber = supplierData.accountDetails.accountNumber;
        supplierData.ifscCode = supplierData.accountDetails.ifscCode;
        supplierData.accountHolderName = supplierData.accountDetails.accountHolderName;
        supplierData.accountType = supplierData.accountDetails.accountType;
      }
      
      // Remove any undefined or null values to prevent overwriting existing data
      Object.keys(supplierData).forEach(key => {
        if (supplierData[key] === undefined || supplierData[key] === null) {
          delete supplierData[key];
        }
      });
      
      const updatedSupplier = await this.supplierModel.findOneAndUpdate(
        { id },
        { $set: supplierData },
        { new: true }
      ).exec();
      
      if (!updatedSupplier) {
        this.logger.warn(`Supplier with ID ${id} not found for update`);
        throw new NotFoundException(`Supplier with ID ${id} not found`);
      }
      
      this.logger.log(`Supplier ${id} updated successfully`);
      return updatedSupplier;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error updating supplier ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to update supplier: ${error.message}`);
    }
  }

  async uploadDocument(id: string, docData: {
    type: string;
    url: string;
    number?: string;
    filename?: string;
  }): Promise<Supplier> {
    try {
      this.logger.log(`Uploading document for supplier ${id}: ${docData.type}`);
      
      // Find the supplier
      const supplier = await this.findOne(id);
      
      if (!supplier) {
        throw new NotFoundException(`Supplier with ID ${id} not found`);
      }
      
      // Create the new document object
      const newDocument = {
        ...docData,
        uploadedAt: new Date(),
      };
      
      // Add the document to the supplier
      const updatedSupplier = await this.supplierModel.findOneAndUpdate(
        { id: supplier.id },
        { $push: { documents: newDocument } },
        { new: true }
      ).exec();
      
      if (!updatedSupplier) {
        throw new NotFoundException(`Failed to update supplier with ID ${id}`);
      }
      
      this.logger.log(`Document uploaded successfully for supplier ${id}`);
      return updatedSupplier;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error uploading document for supplier ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to upload document: ${error.message}`);
    }
  }

  async remove(id: string): Promise<void> {
    try {
      this.logger.log(`Deleting supplier with ID: ${id}`);
      const result = await this.supplierModel.deleteOne({ id }).exec();
      if (result.deletedCount === 0) {
        this.logger.warn(`Supplier with ID ${id} not found for deletion`);
        throw new NotFoundException(`Supplier with ID ${id} not found`);
      }
      this.logger.log(`Supplier ${id} deleted successfully`);
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error deleting supplier ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to delete supplier: ${error.message}`);
    }
  }
}
