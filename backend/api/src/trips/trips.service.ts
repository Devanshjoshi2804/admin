import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Trip } from './entities/trip.entity';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';

@Injectable()
export class TripsService {
  constructor(
    @InjectRepository(Trip)
    private tripsRepository: Repository<Trip>,
  ) {}

  async create(createTripDto: CreateTripDto): Promise<Trip> {
    // Generate a unique order number based on current date and random string
    const date = new Date();
    const formattedDate = `${date.getFullYear()}${(date.getMonth() + 1).toString().padStart(2, '0')}${date.getDate().toString().padStart(2, '0')}`;
    const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    const orderNumber = `FTL-${formattedDate}-${randomPart}`;

    // Calculate advance and balance amounts
    const advanceSupplierFreight = Number((createTripDto.supplierFreight * (createTripDto.advancePercentage / 100)).toFixed(2));
    const balanceSupplierFreight = Number((createTripDto.supplierFreight - advanceSupplierFreight).toFixed(2));

    try {
      console.log("Creating trip with DTO:", JSON.stringify(createTripDto));
      
      // Validate materials are properly formatted
      if (!createTripDto.materials || !Array.isArray(createTripDto.materials)) {
        throw new Error('Materials must be an array');
      }
      
      // Ensure materials can be serialized
      let materialsString: string;
      try {
        materialsString = JSON.stringify(createTripDto.materials || []);
      } catch (jsonError) {
        console.error('Error serializing materials:', jsonError);
        throw new Error('Invalid materials format: cannot be serialized to JSON');
      }
      
      // Create new trip entity with properly serialized JSON data
      const trip = this.tripsRepository.create({
        ...createTripDto,
        orderNumber,
        advanceSupplierFreight,
        balanceSupplierFreight,
        materials: materialsString,
        documents: JSON.stringify([]),
        fieldOps: JSON.stringify(createTripDto.fieldOps || {
          name: "Operations Team",
          phone: "9999999999",
          email: "ops@example.com"
        }),
        status: createTripDto.status || 'Booked',
        advancePaymentStatus: createTripDto.advancePaymentStatus || 'Not Started',
        balancePaymentStatus: createTripDto.balancePaymentStatus || 'Not Started',
        podUploaded: false,
      });

      const savedTrip = await this.tripsRepository.save(trip);
      return this.deserializeJsonFields(savedTrip);
    } catch (error) {
      console.error('Error creating trip:', error);
      
      // Handle specific error cases
      if (error.message && error.message.includes('materials')) {
        throw new Error(`Materials validation error: ${error.message}`);
      }
      
      // If there's a foreign key error, try creating without references
      if (error.code === 'SQLITE_CONSTRAINT') {
        console.log('Attempting to create trip without foreign key references');
        
        try {
          // Create a new DTO with nullified foreign keys
          const modifiedDto = { 
            ...createTripDto,
            clientId: undefined,
            supplierId: undefined, 
            vehicleId: undefined 
          };
          
          // Create with null references
          const trip = this.tripsRepository.create({
            ...modifiedDto,
            orderNumber,
            advanceSupplierFreight,
            balanceSupplierFreight,
            materials: JSON.stringify(createTripDto.materials || []),
            documents: JSON.stringify([]),
            fieldOps: JSON.stringify(createTripDto.fieldOps || {
              name: "Operations Team",
              phone: "9999999999",
              email: "ops@example.com"
            }),
            status: createTripDto.status || 'Booked',
            advancePaymentStatus: createTripDto.advancePaymentStatus || 'Not Started',
            balancePaymentStatus: createTripDto.balancePaymentStatus || 'Not Started',
            podUploaded: false,
          });
          
          const savedTrip = await this.tripsRepository.save(trip);
          return this.deserializeJsonFields(savedTrip);
        } catch (fallbackError) {
          console.error('Error in fallback trip creation:', fallbackError);
          throw new Error(`Failed to create trip: ${fallbackError.message}`);
        }
      }
      
      // For all other errors, throw with more context
      if (error.message) {
        throw new Error(`Trip creation failed: ${error.message}`);
      }
      
      throw error;
    }
  }

  async findAll(): Promise<Trip[]> {
    const trips = await this.tripsRepository.find({
      order: {
        createdAt: 'DESC'
      }
    });

    // Deserialize JSON fields before returning
    return trips.map(trip => this.deserializeJsonFields(trip));
  }

  async findOne(id: string): Promise<Trip> {
    // First try to find by ID
    let trip = await this.tripsRepository.findOne({ where: { id } });
    
    // If not found, try to find by orderNumber
    if (!trip) {
      trip = await this.tripsRepository.findOne({ where: { orderNumber: id } });
    }
    
    if (!trip) {
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    return this.deserializeJsonFields(trip);
  }

  async update(id: string, updateTripDto: UpdateTripDto): Promise<Trip> {
    console.log(`Attempting to update trip with ID or Order Number: ${id}`);
    console.log(`Update data:`, JSON.stringify(updateTripDto));
    
    // First try to find by ID
    let dbTrip = await this.tripsRepository.findOne({ where: { id } });
    
    // If not found, try to find by orderNumber
    if (!dbTrip) {
      console.log(`Trip not found by ID, trying with orderNumber: ${id}`);
      dbTrip = await this.tripsRepository.findOne({ where: { orderNumber: id } });
    }
    
    if (!dbTrip) {
      console.log(`Trip not found with ID or Order Number: ${id}`);
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    console.log(`Found trip:`, JSON.stringify(dbTrip));
    
    // Make a copy for updating
    const trip = { ...dbTrip };
    
    // Handle JSON fields separately
    if (updateTripDto.materials) {
      try {
        trip.materials = JSON.stringify(updateTripDto.materials);
        console.log(`Updated materials field`);
      } catch (e) {
        console.error('Error stringifying materials:', e);
      }
    }
    
    if (updateTripDto.fieldOps) {
      try {
        trip.fieldOps = JSON.stringify(updateTripDto.fieldOps);
        console.log(`Updated fieldOps field`);
      } catch (e) {
        console.error('Error stringifying fieldOps:', e);
      }
    }
    
    if (updateTripDto.documents) {
      try {
        trip.documents = JSON.stringify(updateTripDto.documents);
        console.log(`Updated documents field`);
      } catch (e) {
        console.error('Error stringifying documents:', e);
      }
    }
    
    // Handle additional charges
    if (updateTripDto.additionalCharges) {
      try {
        trip.additionalCharges = JSON.stringify(updateTripDto.additionalCharges);
        console.log(`Updated additionalCharges field:`, JSON.stringify(updateTripDto.additionalCharges));
      } catch (e) {
        console.error('Error stringifying additionalCharges:', e);
      }
    }
    
    // Handle deduction charges
    if (updateTripDto.deductionCharges) {
      try {
        trip.deductionCharges = JSON.stringify(updateTripDto.deductionCharges);
        console.log(`Updated deductionCharges field:`, JSON.stringify(updateTripDto.deductionCharges));
      } catch (e) {
        console.error('Error stringifying deductionCharges:', e);
      }
    }
    
    // Handle LR charges explicitly
    if (updateTripDto.lrCharges !== undefined) {
      console.log(`Updating lrCharges from ${trip.lrCharges} to ${updateTripDto.lrCharges}`);
      trip.lrCharges = updateTripDto.lrCharges;
    }
    
    // Update other fields
    Object.keys(updateTripDto).forEach(key => {
      if (!['materials', 'fieldOps', 'documents', 'additionalCharges', 'deductionCharges', 'lrCharges'].includes(key)) {
        console.log(`Updating field ${key}: ${trip[key]} -> ${updateTripDto[key]}`);
        trip[key] = updateTripDto[key];
      }
    });
    
    // Recalculate payment amounts if relevant fields are updated
    if (updateTripDto.supplierFreight !== undefined || updateTripDto.advancePercentage !== undefined) {
      const supplierFreight = updateTripDto.supplierFreight ?? trip.supplierFreight;
      const advancePercentage = updateTripDto.advancePercentage ?? trip.advancePercentage;
      
      trip.advanceSupplierFreight = Number((supplierFreight * (advancePercentage / 100)).toFixed(2));
      trip.balanceSupplierFreight = Number((supplierFreight - trip.advanceSupplierFreight).toFixed(2));
      console.log(`Recalculated payment amounts: advance=${trip.advanceSupplierFreight}, balance=${trip.balanceSupplierFreight}`);
    }
    
    // Save the updated entity
    try {
      console.log(`Saving updated trip:`, JSON.stringify(trip));
      const savedTrip = await this.tripsRepository.save(trip);
      console.log(`Trip successfully updated with ID: ${savedTrip.id}`);
      
      // Return with deserialized JSON
      return this.deserializeJsonFields(savedTrip);
    } catch (error) {
      console.error(`Error saving trip:`, error);
      throw error;
    }
  }

  async uploadDocument(id: string, docData: {
    type: string;
    number: string;
    filename: string;
  }): Promise<Trip> {
    // First try to find by ID
    let trip = await this.tripsRepository.findOne({ where: { id } });
    
    // If not found, try to find by orderNumber
    if (!trip) {
      trip = await this.tripsRepository.findOne({ where: { orderNumber: id } });
    }
    
    if (!trip) {
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    const newDoc: any = {
      id: uuidv4(),
      ...docData,
      uploadDate: new Date().toISOString().split('T')[0],
    };
    
    // Parse existing documents
    let documentsArray: any[] = [];
    try {
      if (trip.documents) {
        documentsArray = JSON.parse(trip.documents);
      }
      
      // Ensure documentsArray is an array
      if (!Array.isArray(documentsArray)) {
        documentsArray = [];
      }
    } catch (e) {
      console.error('Error parsing documents:', e);
      // Initialize as empty array if parsing fails
      documentsArray = [];
    }
    
    // Add new document
    documentsArray.push(newDoc);
    
    // Store back as JSON string
    trip.documents = JSON.stringify(documentsArray);
    
    // Update POD status if applicable
    if (docData.type === 'POD') {
      trip.podUploaded = true;
    }
    
    const savedTrip = await this.tripsRepository.save(trip);
    return this.deserializeJsonFields(savedTrip);
  }

  async remove(id: string): Promise<void> {
    // First try to find by ID
    let trip = await this.tripsRepository.findOne({ where: { id } });
    
    // If not found, try to find by orderNumber
    if (!trip) {
      trip = await this.tripsRepository.findOne({ where: { orderNumber: id } });
    }
    
    if (!trip) {
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    // Delete using the actual ID
    const result = await this.tripsRepository.delete(trip.id);
    if (result.affected === 0) {
      throw new NotFoundException(`Failed to delete trip with ID ${trip.id}`);
    }
  }
  
  // Helper to deserialize JSON fields stored as strings
  private deserializeJsonFields(trip: Trip): any {
    try {
      const result: any = { ...trip };
      
      // Deserialize materials if present
      if (trip.materials) {
        try {
          result.materials = JSON.parse(trip.materials);
        } catch (e) {
          console.error('Error parsing materials:', e);
          result.materials = [];
        }
      } else {
        result.materials = [];
      }
      
      // Deserialize documents if present
      if (trip.documents) {
        try {
          result.documents = JSON.parse(trip.documents);
        } catch (e) {
          console.error('Error parsing documents:', e);
          result.documents = [];
        }
      } else {
        result.documents = [];
      }
      
      // Deserialize fieldOps if present
      if (trip.fieldOps) {
        try {
          result.fieldOps = JSON.parse(trip.fieldOps);
        } catch (e) {
          console.error('Error parsing fieldOps:', e);
          result.fieldOps = {
            name: "Operations Team",
            phone: "9999999999",
            email: "ops@example.com"
          };
        }
      } else {
        result.fieldOps = {
          name: "Operations Team",
          phone: "9999999999",
          email: "ops@example.com"
        };
      }
      
      // Deserialize additionalCharges if present
      if (trip.additionalCharges) {
        try {
          result.additionalCharges = JSON.parse(trip.additionalCharges);
        } catch (e) {
          console.error('Error parsing additionalCharges:', e);
          result.additionalCharges = [];
        }
      } else {
        result.additionalCharges = [];
      }
      
      // Deserialize deductionCharges if present
      if (trip.deductionCharges) {
        try {
          result.deductionCharges = JSON.parse(trip.deductionCharges);
        } catch (e) {
          console.error('Error parsing deductionCharges:', e);
          result.deductionCharges = [];
        }
      } else {
        result.deductionCharges = [];
      }
      
      return result;
    } catch (error) {
      console.error('Error deserializing trip data:', error);
      return trip; // Return as-is if there's an error
    }
  }

  // Special method for updating payment statuses with better handling
  async updatePaymentStatus(id: string, paymentData: {
    advancePaymentStatus?: string;
    balancePaymentStatus?: string;
    utrNumber?: string;
    paymentMethod?: string;
  }): Promise<Trip> {
    console.log(`🚨 Updating payment status for trip ${id} with data:`, JSON.stringify(paymentData));
    
    // First try to find by ID
    let dbTrip = await this.tripsRepository.findOne({ where: { id } });
    
    // If not found, try to find by orderNumber
    if (!dbTrip) {
      console.log(`Trip not found by ID, trying with orderNumber: ${id}`);
      dbTrip = await this.tripsRepository.findOne({ where: { orderNumber: id } });
    }
    
    if (!dbTrip) {
      console.log(`Trip not found with ID or Order Number: ${id}`);
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    console.log(`Found trip for payment update:`, JSON.stringify({
      id: dbTrip.id,
      orderNumber: dbTrip.orderNumber,
      currentStatus: dbTrip.status,
      currentAdvanceStatus: dbTrip.advancePaymentStatus,
      currentBalanceStatus: dbTrip.balancePaymentStatus
    }));
    
    // Make a copy for updating
    const trip = { ...dbTrip };
    
    // Update payment statuses
    if (paymentData.advancePaymentStatus) {
      console.log(`Updating advance payment status: ${trip.advancePaymentStatus} -> ${paymentData.advancePaymentStatus}`);
      trip.advancePaymentStatus = paymentData.advancePaymentStatus;
      
      // If advance payment is marked as Paid and trip is in Booked status, update trip status to In Transit
      if (paymentData.advancePaymentStatus === 'Paid' && trip.status === 'Booked') {
        console.log(`Advance payment marked as Paid, updating trip status: ${trip.status} -> In Transit`);
        trip.status = 'In Transit';
      }
    }
    
    if (paymentData.balancePaymentStatus) {
      console.log(`Updating balance payment status: ${trip.balancePaymentStatus} -> ${paymentData.balancePaymentStatus}`);
      trip.balancePaymentStatus = paymentData.balancePaymentStatus;
      
      // If balance payment is marked as Paid and trip is in In Transit or Delivered status, update trip status to Completed
      if (paymentData.balancePaymentStatus === 'Paid' && 
          (trip.status === 'In Transit' || trip.status === 'Delivered')) {
        console.log(`Balance payment marked as Paid, updating trip status: ${trip.status} -> Completed`);
        trip.status = 'Completed';
      }
    }
    
    // Update other payment-related fields
    if (paymentData.utrNumber) {
      console.log(`Updating UTR number: ${trip.utrNumber} -> ${paymentData.utrNumber}`);
      trip.utrNumber = paymentData.utrNumber;
    }
    
    if (paymentData.paymentMethod) {
      console.log(`Updating payment method: ${trip.paymentMethod} -> ${paymentData.paymentMethod}`);
      trip.paymentMethod = paymentData.paymentMethod;
    }
    
    // Save the updated entity
    try {
      console.log(`Saving payment updates for trip:`, JSON.stringify({
        id: trip.id,
        orderNumber: trip.orderNumber,
        newStatus: trip.status,
        newAdvanceStatus: trip.advancePaymentStatus,
        newBalanceStatus: trip.balancePaymentStatus,
        utrNumber: trip.utrNumber,
        paymentMethod: trip.paymentMethod
      }));
      
      const savedTrip = await this.tripsRepository.save(trip);
      console.log(`🎉 Payment successfully updated for trip ID: ${savedTrip.id}`);
      
      // Return with deserialized JSON
      return this.deserializeJsonFields(savedTrip);
    } catch (error) {
      console.error(`❌ Error saving payment updates:`, error);
      throw error;
    }
  }
}
