import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Vehicle, VehicleDocument } from './schemas/vehicle.schema';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectModel(Vehicle.name)
    private vehicleModel: Model<VehicleDocument>,
  ) {}

  async create(createVehicleDto: CreateVehicleDto): Promise<Vehicle> {
    // Generate a unique ID if not provided
    const vehicleId = createVehicleDto.id || `VH${uuidv4().substring(0, 8).toUpperCase()}`;
    
    // Create the MongoDB document
    const newVehicle = new this.vehicleModel({
      ...createVehicleDto,
      id: vehicleId,
    });
    
    // Save to MongoDB
    return await newVehicle.save();
  }

  async findAll(): Promise<Vehicle[]> {
    // Get vehicles from MongoDB
    return this.vehicleModel.find().sort({ registrationNumber: 1 }).exec();
  }

  async findOne(id: string): Promise<Vehicle> {
    const vehicle = await this.vehicleModel.findOne({ id }).exec();
    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    return vehicle;
  }

  async update(id: string, updateVehicleDto: UpdateVehicleDto): Promise<Vehicle> {
    const updatedVehicle = await this.vehicleModel.findOneAndUpdate(
      { id },
      { $set: updateVehicleDto },
      { new: true }
    ).exec();
    
    if (!updatedVehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    
    return updatedVehicle;
  }

  async remove(id: string): Promise<void> {
    const result = await this.vehicleModel.deleteOne({ id }).exec();
    if (result.deletedCount === 0) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
  }
}
