import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';
import { Trip, TripDocument } from './schemas/trip.schema';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';

@Injectable()
export class TripsService {
  constructor(
    @InjectModel(Trip.name)
    private tripModel: Model<TripDocument>,
  ) {}

  async create(createTripDto: CreateTripDto): Promise<Trip> {
    // Generate a unique order number based on current date and random string
    const date = new Date();
    const formattedDate = `${date.getFullYear()}${(date.getMonth() + 1).toString().padStart(2, '0')}${date.getDate().toString().padStart(2, '0')}`;
    const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    const orderNumber = createTripDto.orderNumber || `FTL-${formattedDate}-${randomPart}`;
    
    // Generate a unique ID if not provided
    const tripId = createTripDto.id || `TR${uuidv4().substring(0, 8).toUpperCase()}`;

    try {
      console.log("Creating trip with DTO:", JSON.stringify(createTripDto));
      
      // Create pricing object if individual pricing fields are provided
      const pricing = createTripDto.pricing || {
        baseAmount: createTripDto.baseAmount || 0,
        gst: createTripDto.gst || 0,
        totalAmount: createTripDto.totalAmount || 0
      };
      
      // Calculate freight-related values if not provided
      const clientFreight = createTripDto.clientFreight || 0;
      const supplierFreight = createTripDto.supplierFreight || 0;
      const advancePercentage = createTripDto.advancePercentage || 30;
      
      // Calculate derived values if not provided
      const margin = createTripDto.margin !== undefined 
        ? createTripDto.margin 
        : clientFreight - supplierFreight;
      
      const advanceSupplierFreight = createTripDto.advanceSupplierFreight !== undefined
        ? createTripDto.advanceSupplierFreight
        : (supplierFreight * advancePercentage) / 100;
      
      const balanceSupplierFreight = createTripDto.balanceSupplierFreight !== undefined
        ? createTripDto.balanceSupplierFreight
        : supplierFreight - advanceSupplierFreight;
      
      // Create the MongoDB document with streamlined workflow
      const newTrip = new this.tripModel({
        id: tripId,
        orderNumber,
        clientId: createTripDto.clientId,
        clientName: createTripDto.clientName,
        vehicleId: createTripDto.vehicleId,
        vehicleNumber: createTripDto.vehicleNumber,
        vehicleType: createTripDto.vehicleType,
        supplierId: createTripDto.supplierId,
        supplierName: createTripDto.supplierName,
        source: createTripDto.source,
        destination: createTripDto.destination,
        distance: createTripDto.distance,
        startDate: createTripDto.startDate,
        endDate: createTripDto.endDate,
        loadingDate: createTripDto.loadingDate,
        unloadingDate: createTripDto.unloadingDate,
        pricing,
        documents: createTripDto.documents || [],
        status: 'Booked', // Always start with 'Booked' status
        clientFreight,
        supplierFreight,
        advancePercentage,
        margin,
        advanceSupplierFreight,
        balanceSupplierFreight,
        advancePaymentStatus: 'Not Started',
        balancePaymentStatus: 'Not Started',
        isInAdvanceQueue: true, // Automatically add to advance payment queue
        isInBalanceQueue: false,
        paymentHistory: [],
        notes: createTripDto.notes || ''
      });
      
      // Ensure all required fields are set
      newTrip.margin = typeof newTrip.margin === 'number' ? newTrip.margin : 0;
      newTrip.advanceSupplierFreight = typeof newTrip.advanceSupplierFreight === 'number' ? newTrip.advanceSupplierFreight : 0;
      newTrip.balanceSupplierFreight = typeof newTrip.balanceSupplierFreight === 'number' ? newTrip.balanceSupplierFreight : 0;
      
      // Save to MongoDB
      const savedTrip = await newTrip.save();
      
      console.log(`Trip ${orderNumber} created and added to advance payment queue`);
      return savedTrip;
    } catch (error) {
      console.error('Error creating trip:', error);
      throw error;
    }
  }

  async findAll(): Promise<Trip[]> {
    // Get trips from MongoDB
    return this.tripModel.find().sort({ createdAt: -1 }).exec();
  }

  async findAllPaginated(page: number, limit: number): Promise<{
    data: Trip[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    const skip = (page - 1) * limit;
    
    // Get paginated trips with essential fields only for performance
    const [trips, total] = await Promise.all([
      this.tripModel
        .find()
        .select('id orderNumber clientId clientName supplierName vehicleNumber status advancePaymentStatus balancePaymentStatus clientFreight supplierFreight margin advanceSupplierFreight balanceSupplierFreight createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.tripModel.countDocuments().exec()
    ]);

    return {
      data: trips,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    };
  }

  async findOne(id: string): Promise<Trip> {
    // First try to find by ID
    let trip = await this.tripModel.findOne({ id }).exec();
    
    // If not found, try to find by orderNumber
    if (!trip) {
      trip = await this.tripModel.findOne({ orderNumber: id }).exec();
    }
    
    if (!trip) {
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    return trip;
  }

  // Get trips in advance payment queue
  async getAdvancePaymentQueue(): Promise<Trip[]> {
    return this.tripModel.find({
      isInAdvanceQueue: true,
      advancePaymentStatus: { $ne: 'Paid' }
    }).sort({ createdAt: 1 }).exec();
  }

  // Get trips in balance payment queue
  async getBalancePaymentQueue(): Promise<Trip[]> {
    return this.tripModel.find({
      isInBalanceQueue: true,
      balancePaymentStatus: { $ne: 'Paid' },
      podUploaded: true
    }).sort({ podDate: 1 }).exec();
  }

  // Real-time payment status update with automatic workflow management
  async updatePaymentStatus(id: string, paymentData: {
    advancePaymentStatus?: string;
    balancePaymentStatus?: string;
    utrNumber?: string;
    paymentMethod?: string;
  }): Promise<Trip> {
    console.log(`Real-time payment update for trip: ${id}`);
    console.log(`Payment data:`, JSON.stringify(paymentData));
    
    const trip = await this.findOne(id);
    const updateData: any = { ...paymentData };
    const currentTime = new Date();
    
    // Handle advance payment status changes
    if (paymentData.advancePaymentStatus) {
      const newStatus = paymentData.advancePaymentStatus;
      const oldStatus = trip.advancePaymentStatus;
      
      // Update timestamps
      if (newStatus === 'Initiated' && oldStatus === 'Not Started') {
        updateData.advancePaymentInitiatedAt = currentTime;
      } else if (newStatus === 'Paid') {
        updateData.advancePaymentCompletedAt = currentTime;
        updateData.paymentDate = currentTime;
        updateData.status = 'In Transit'; // Auto-update trip status
        updateData.isInAdvanceQueue = false; // Remove from advance queue
        updateData.isInBalanceQueue = true; // Add to balance queue
        
        console.log(`Advance payment completed - Trip ${trip.orderNumber} moved to In Transit`);
      }
      
      // Add to payment history
      if (!trip.paymentHistory) trip.paymentHistory = [];
      trip.paymentHistory.push({
        paymentType: 'advance',
        status: newStatus,
        amount: trip.advanceSupplierFreight,
        timestamp: currentTime,
        utrNumber: paymentData.utrNumber,
        paymentMethod: paymentData.paymentMethod
      });
      updateData.paymentHistory = trip.paymentHistory;
    }
    
    // Handle balance payment status changes
    if (paymentData.balancePaymentStatus) {
      const newStatus = paymentData.balancePaymentStatus;
      const oldStatus = trip.balancePaymentStatus;
      
      // Ensure POD is uploaded before processing balance payment
      if (newStatus !== 'Not Started' && !trip.podUploaded) {
        throw new BadRequestException('POD document must be uploaded before processing balance payment');
      }
      
      // Update timestamps
      if (newStatus === 'Initiated' && oldStatus === 'Not Started') {
        updateData.balancePaymentInitiatedAt = currentTime;
      } else if (newStatus === 'Paid') {
        updateData.balancePaymentCompletedAt = currentTime;
        updateData.paymentDate = currentTime;
        updateData.status = 'Completed'; // Auto-update trip status
        updateData.isInBalanceQueue = false; // Remove from balance queue
        
        console.log(`Balance payment completed - Trip ${trip.orderNumber} marked as Completed`);
      }
      
      // Add to payment history
      if (!trip.paymentHistory) trip.paymentHistory = [];
      trip.paymentHistory.push({
        paymentType: 'balance',
        status: newStatus,
        amount: trip.balanceSupplierFreight,
        timestamp: currentTime,
        utrNumber: paymentData.utrNumber,
        paymentMethod: paymentData.paymentMethod
      });
      updateData.paymentHistory = trip.paymentHistory;
    }
    
    // Update the trip
    const updatedTrip = await this.tripModel.findOneAndUpdate(
      { id: trip.id },
      { $set: updateData },
      { new: true }
    ).exec();
    
    if (!updatedTrip) {
      throw new NotFoundException(`Failed to update trip with ID ${id}`);
    }
    
    return updatedTrip;
  }

  // Enhanced POD upload with automatic balance queue management
  async uploadPOD(id: string, podData: {
    filename: string;
    url: string;
  }): Promise<Trip> {
    const trip = await this.findOne(id);
    
    if (trip.status !== 'In Transit') {
      throw new BadRequestException('POD can only be uploaded for trips in In Transit status');
    }
    
    if (trip.advancePaymentStatus !== 'Paid') {
      throw new BadRequestException('Advance payment must be completed before uploading POD');
    }
    
    const updateData = {
      podUploaded: true,
      podDate: new Date(),
      podDocument: {
        filename: podData.filename,
        url: podData.url,
        uploadedAt: new Date(),
        isDownloadable: true
      },
      isInBalanceQueue: true // Automatically add to balance payment queue
    };
    
    const updatedTrip = await this.tripModel.findOneAndUpdate(
      { id: trip.id },
      { $set: updateData },
      { new: true }
    ).exec();
    
    if (!updatedTrip) {
      throw new NotFoundException(`Failed to update trip with ID ${id}`);
    }
    
    console.log(`POD uploaded for trip ${trip.orderNumber} - Added to balance payment queue`);
    return updatedTrip;
  }

  async update(id: string, updateTripDto: UpdateTripDto): Promise<Trip> {
    console.log(`Attempting to update trip with ID or Order Number: ${id}`);
    console.log(`Update data:`, JSON.stringify(updateTripDto));
    
    // First try to find and update by ID
    let updatedTrip = await this.tripModel.findOneAndUpdate(
      { id },
      { $set: updateTripDto },
      { new: true }
    ).exec();
    
    // If not found, try to find and update by orderNumber
    if (!updatedTrip) {
      console.log(`Trip not found by ID, trying with orderNumber: ${id}`);
      updatedTrip = await this.tripModel.findOneAndUpdate(
        { orderNumber: id },
        { $set: updateTripDto },
        { new: true }
      ).exec();
    }
    
    if (!updatedTrip) {
      console.log(`Trip not found with ID or Order Number: ${id}`);
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    return updatedTrip;
  }

  async uploadDocument(id: string, docData: {
    type: string;
    number?: string;
    filename?: string;
    url?: string;
  }): Promise<Trip> {
    // Find the trip
    const trip = await this.findOne(id);
    
    if (!trip) {
      throw new NotFoundException(`Trip with ID ${id} not found`);
    }
    
    // Create the new document object with a generated URL if not provided
    const newDocument = {
      type: docData.type,
      url: docData.url || `https://storage.example.com/documents/${id}/${Date.now()}`,
      uploadedAt: new Date(),
      filename: docData.filename,
      isDownloadable: true
    };
    
    // Add the document to the trip
    const updatedTrip = await this.tripModel.findOneAndUpdate(
      { id: trip.id },
      { $push: { documents: newDocument } },
      { new: true }
    ).exec();
    
    if (!updatedTrip) {
      throw new NotFoundException(`Failed to update trip with ID ${id}`);
    }
    
    return updatedTrip;
  }

  async remove(id: string): Promise<void> {
    // First try to delete by ID
    let result = await this.tripModel.deleteOne({ id }).exec();
    
    // If not found, try to delete by orderNumber
    if (result.deletedCount === 0) {
      result = await this.tripModel.deleteOne({ orderNumber: id }).exec();
    }
    
    if (result.deletedCount === 0) {
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
  }

  // Streamlined payment processing method
  async processPayment(id: string, paymentData: {
    paymentType: 'advance' | 'balance';
    paymentStatus: 'Initiated' | 'Pending' | 'Paid';
    utrNumber?: string;
    paymentMethod?: string;
    notes?: string;
  }): Promise<Trip> {
    const trip = await this.findOne(id);
    if (!trip) {
      throw new NotFoundException(`Trip with ID ${id} not found`);
    }

    // Validate payment flow
    if (paymentData.paymentType === 'balance') {
      if (trip.advancePaymentStatus !== 'Paid') {
        throw new BadRequestException('Advance payment must be completed before processing balance payment');
      }
      if (!trip.podUploaded) {
        throw new BadRequestException('POD must be uploaded before processing balance payment');
      }
    }

    // Create the update object
    const updateData: any = {};
    const currentTime = new Date();
    
    if (paymentData.paymentType === 'advance') {
      updateData.advancePaymentStatus = paymentData.paymentStatus;
      
      if (paymentData.paymentStatus === 'Paid') {
        updateData.status = 'In Transit';
        updateData.isInAdvanceQueue = false;
        updateData.isInBalanceQueue = true;
        updateData.advancePaymentCompletedAt = currentTime;
      } else if (paymentData.paymentStatus === 'Initiated') {
        updateData.advancePaymentInitiatedAt = currentTime;
      }
    } else {
      updateData.balancePaymentStatus = paymentData.paymentStatus;
      
      if (paymentData.paymentStatus === 'Paid') {
        updateData.status = 'Completed';
        updateData.isInBalanceQueue = false;
        updateData.balancePaymentCompletedAt = currentTime;
      } else if (paymentData.paymentStatus === 'Initiated') {
        updateData.balancePaymentInitiatedAt = currentTime;
      }
    }

    // Add payment details
    if (paymentData.utrNumber) {
      updateData.utrNumber = paymentData.utrNumber;
    }
    
    if (paymentData.paymentMethod) {
      updateData.paymentMethod = paymentData.paymentMethod;
    }
    
    if (paymentData.paymentStatus === 'Paid') {
      updateData.paymentDate = currentTime;
    }

    // Add to payment history
    const paymentHistoryEntry = {
      paymentType: paymentData.paymentType,
      status: paymentData.paymentStatus,
      amount: paymentData.paymentType === 'advance' ? trip.advanceSupplierFreight : trip.balanceSupplierFreight,
      timestamp: currentTime,
      utrNumber: paymentData.utrNumber,
      paymentMethod: paymentData.paymentMethod,
      notes: paymentData.notes
    };

    updateData.$push = { paymentHistory: paymentHistoryEntry };

    // Update the trip
    const updatedTrip = await this.tripModel.findOneAndUpdate(
      { id: trip.id },
      updateData,
      { new: true }
    ).exec();
    
    if (!updatedTrip) {
      throw new NotFoundException(`Failed to update trip with ID ${id}`);
    }

    console.log(`Payment processed: ${paymentData.paymentType} payment ${paymentData.paymentStatus} for trip ${trip.orderNumber}`);
    return updatedTrip;
  }

  // Update additional charges method
  async updateAdditionalCharges(id: string, chargesData: {
    additionalCharges: { description: string; amount: number; reason?: string }[];
    deductionCharges: { description: string; amount: number; reason?: string }[];
    newBalanceAmount: number;
    reason?: string;
    addedBy?: string;
  }): Promise<Trip> {
    console.log(`Updating additional charges for trip: ${id}`);
    console.log(`Charges data:`, JSON.stringify(chargesData));

    const trip = await this.findOne(id);
    if (!trip) {
      throw new NotFoundException(`Trip with ID ${id} not found`);
    }

    // Validate that advance payment is completed before allowing charge modifications
    if (trip.advancePaymentStatus !== 'Paid') {
      throw new BadRequestException('Additional charges can only be modified after advance payment is completed');
    }

    const currentTime = new Date();

    // Process additional charges
    const additionalCharges = chargesData.additionalCharges.map(charge => ({
      description: charge.description,
      amount: charge.amount,
      reason: charge.reason || chargesData.reason || 'Additional charge',
      addedAt: currentTime,
      addedBy: chargesData.addedBy || 'system'
    }));

    // Process deduction charges
    const deductionCharges = chargesData.deductionCharges.map(charge => ({
      description: charge.description,
      amount: charge.amount,
      reason: charge.reason || chargesData.reason || 'Deduction charge',
      addedAt: currentTime,
      addedBy: chargesData.addedBy || 'system'
    }));

    // Calculate totals
    const totalAdditionalCharges = additionalCharges.reduce((sum, charge) => sum + charge.amount, 0);
    const totalDeductionCharges = deductionCharges.reduce((sum, charge) => sum + charge.amount, 0);

    // Extract specific charge amounts for easier queries
    const lrCharges = deductionCharges
      .filter(charge => charge.description.toLowerCase().includes('lr'))
      .reduce((sum, charge) => sum + charge.amount, 0);

    const platformFees = deductionCharges
      .filter(charge => charge.description.toLowerCase().includes('platform'))
      .reduce((sum, charge) => sum + charge.amount, 0);

    const miscellaneousCharges = deductionCharges
      .filter(charge => 
        !charge.description.toLowerCase().includes('lr') && 
        !charge.description.toLowerCase().includes('platform')
      )
      .reduce((sum, charge) => sum + charge.amount, 0);

    // Build charges history entries
    const chargesHistory = [
      ...additionalCharges.map(charge => ({
        action: 'add' as const,
        chargeType: 'additional' as const,
        description: charge.description,
        amount: charge.amount,
        reason: charge.reason,
        timestamp: currentTime,
        addedBy: charge.addedBy
      })),
      ...deductionCharges.map(charge => ({
        action: 'add' as const,
        chargeType: 'deduction' as const,
        description: charge.description,
        amount: charge.amount,
        reason: charge.reason,
        timestamp: currentTime,
        addedBy: charge.addedBy
      }))
    ];

    // Prepare update data
    const updateData = {
      additionalCharges,
      deductionCharges,
      totalAdditionalCharges,
      totalDeductionCharges,
      lrCharges,
      platformFees,
      miscellaneousCharges,
      balanceSupplierFreight: chargesData.newBalanceAmount,
      $push: {
        chargesHistory: { $each: chargesHistory }
      }
    };

    console.log(`Update data:`, JSON.stringify(updateData, null, 2));

    // Update the trip
    const updatedTrip = await this.tripModel.findOneAndUpdate(
      { id: trip.id },
      updateData,
      { new: true }
    ).exec();

    if (!updatedTrip) {
      throw new NotFoundException(`Failed to update trip with ID ${id}`);
    }

    console.log(`Additional charges updated successfully for trip ${trip.orderNumber}`);
    console.log(`- Total additional charges: ₹${totalAdditionalCharges}`);
    console.log(`- Total deduction charges: ₹${totalDeductionCharges}`);
    console.log(`- Updated balance amount: ₹${chargesData.newBalanceAmount}`);

    return updatedTrip;
  }

  // ⚡ Ultra-fast trip loading with database joins (Future implementation)
  async getTripsUltraFast(options: {
    skip: number;
    limit: number;
    status?: string;
    clientId?: string;
  }): Promise<{ trips: Trip[]; total: number }> {
    const { skip, limit, status, clientId } = options;
    
    // Build query filters
    const query: any = {};
    if (status) {
      query.status = status;
    }
    if (clientId) {
      query.clientId = clientId;
    }
    
    // Execute optimized query with minimal fields for maximum speed
    const [trips, total] = await Promise.all([
      this.tripModel
        .find(query)
        .select('id orderNumber clientId clientName supplierName vehicleNumber status advancePaymentStatus balancePaymentStatus clientFreight supplierFreight advanceSupplierFreight balanceSupplierFreight source destination createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean() // Use lean for better performance
        .exec(),
      this.tripModel.countDocuments(query).exec()
    ]);

    return { trips, total };
  }

  // ⚡ Ultra-fast single trip loading with all related data
  async getTripUltraFast(id: string): Promise<Trip> {
    // Use lean query for maximum speed
    let trip = await this.tripModel
      .findOne({ $or: [{ id }, { orderNumber: id }] })
      .lean()
      .exec();
    
    if (!trip) {
      throw new NotFoundException(`Trip with ID or Order Number ${id} not found`);
    }
    
    return trip;
  }

  // ⚡ Ultra-fast dashboard data aggregation
  async getDashboardDataUltraFast(): Promise<{
    stats: any;
    recentTrips: Trip[];
  }> {
    // Use aggregation pipeline for maximum speed
    const [statsResult, recentTrips] = await Promise.all([
      this.tripModel.aggregate([
        {
          $group: {
            _id: null,
            totalTrips: { $sum: 1 },
            bookedTrips: {
              $sum: { $cond: [{ $eq: ['$status', 'Booked'] }, 1, 0] }
            },
            inTransitTrips: {
              $sum: { $cond: [{ $eq: ['$status', 'In Transit'] }, 1, 0] }
            },
            completedTrips: {
              $sum: { $cond: [{ $eq: ['$status', 'Completed'] }, 1, 0] }
            },
            pendingAdvancePayments: {
              $sum: { $cond: [{ $ne: ['$advancePaymentStatus', 'Paid'] }, 1, 0] }
            },
            pendingBalancePayments: {
              $sum: { 
                $cond: [
                  { 
                    $and: [
                      { $ne: ['$balancePaymentStatus', 'Paid'] },
                      { $eq: ['$advancePaymentStatus', 'Paid'] }
                    ]
                  }, 
                  1, 
                  0
                ]
              }
            }
          }
        }
      ]).exec(),
      this.tripModel
        .find()
        .select('id orderNumber status clientName supplierName vehicleNumber advancePaymentStatus balancePaymentStatus createdAt')
        .sort({ createdAt: -1 })
        .limit(10)
        .lean()
        .exec()
    ]);

    const stats = statsResult[0] || {
      totalTrips: 0,
      bookedTrips: 0,
      inTransitTrips: 0,
      completedTrips: 0,
      pendingAdvancePayments: 0,
      pendingBalancePayments: 0
    };

    return { stats, recentTrips };
  }

  // Update trip status method
  async updateStatus(id: string, status: string): Promise<Trip> {
    const trip = await this.findOne(id);
    
    const updateData: any = {
      status,
      updatedAt: new Date()
    };
    
    // Handle status transitions with payment status changes
    if (status === 'In Transit' && trip.advancePaymentStatus !== 'Paid') {
      throw new BadRequestException('Cannot change status to In Transit without completing advance payment');
    }
    
    if (status === 'Completed' && trip.balancePaymentStatus !== 'Paid') {
      // Auto-initiate balance payment if not already done
      if (trip.balancePaymentStatus === 'Not Started') {
        updateData.balancePaymentStatus = 'Initiated';
        updateData.isInBalanceQueue = true;
      }
    }
    
    const updatedTrip = await this.tripModel.findOneAndUpdate(
      { id: trip.id },
      { $set: updateData },
      { new: true }
    ).exec();
    
    if (!updatedTrip) {
      throw new NotFoundException(`Failed to update trip with ID ${id}`);
    }
    
    return updatedTrip;
  }
}
