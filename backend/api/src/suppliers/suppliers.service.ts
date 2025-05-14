import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Supplier } from './entities/supplier.entity';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { UpdateSupplierDto } from './dto/update-supplier.dto';

@Injectable()
export class SuppliersService {
  constructor(
    @InjectRepository(Supplier)
    private suppliersRepository: Repository<Supplier>,
  ) {}

  async create(createSupplierDto: CreateSupplierDto): Promise<Supplier> {
    const supplier = this.suppliersRepository.create({
      ...createSupplierDto,
      contactPerson: JSON.stringify(createSupplierDto.contactPerson || {}),
      bankDetails: JSON.stringify(createSupplierDto.bankDetails || {}),
    });

    const savedSupplier = await this.suppliersRepository.save(supplier);
    return this.deserializeJsonFields(savedSupplier);
  }

  async findAll(): Promise<Supplier[]> {
    const suppliers = await this.suppliersRepository.find({
      order: {
        name: 'ASC'
      }
    });

    return suppliers.map(supplier => this.deserializeJsonFields(supplier));
  }

  async findOne(id: string): Promise<Supplier> {
    const supplier = await this.suppliersRepository.findOne({ where: { id } });
    if (!supplier) {
      throw new NotFoundException(`Supplier with ID ${id} not found`);
    }
    return this.deserializeJsonFields(supplier);
  }

  async update(id: string, updateSupplierDto: UpdateSupplierDto): Promise<Supplier> {
    const supplier = await this.suppliersRepository.findOne({ where: { id } });
    if (!supplier) {
      throw new NotFoundException(`Supplier with ID ${id} not found`);
    }

    // Handle JSON fields separately
    if (updateSupplierDto.contactPerson) {
      supplier.contactPerson = JSON.stringify(updateSupplierDto.contactPerson);
    }
    
    if (updateSupplierDto.bankDetails) {
      supplier.bankDetails = JSON.stringify(updateSupplierDto.bankDetails);
    }

    // Update other fields
    Object.keys(updateSupplierDto).forEach(key => {
      if (key !== 'contactPerson' && key !== 'bankDetails') {
        supplier[key] = updateSupplierDto[key];
      }
    });

    const savedSupplier = await this.suppliersRepository.save(supplier);
    return this.deserializeJsonFields(savedSupplier);
  }

  async remove(id: string): Promise<void> {
    const result = await this.suppliersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Supplier with ID ${id} not found`);
    }
  }

  // Helper to deserialize JSON fields stored as strings
  private deserializeJsonFields(supplier: Supplier): any {
    const result = { ...supplier };
    
    try {
      if (result.contactPerson && typeof result.contactPerson === 'string') {
        result.contactPerson = JSON.parse(result.contactPerson);
      }
      
      if (result.bankDetails && typeof result.bankDetails === 'string') {
        result.bankDetails = JSON.parse(result.bankDetails);
      }
    } catch (error) {
      console.error('Error deserializing JSON fields:', error);
    }
    
    return result;
  }
}
