import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/models/payment_params.dart';

// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider for the list of trips
final tripListProvider = FutureProvider<List<Trip>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    final trips = await apiService.getTrips();
    
    // Check for financial data issues in any trips
    List<Trip> fixedTrips = [];
    
    for (final trip in trips) {
      // Check if this trip has financial data
      final hasFinancialData = trip.clientFreight != null && trip.clientFreight! > 0 && 
                               trip.supplierFreight != null && trip.supplierFreight! > 0;
      
      if (!hasFinancialData) {
        debugPrint("⚠️ Trip ${trip.id} is missing financial data, will synchronize");
        try {
          // Synchronize this trip's financial data
          final fixedTrip = await apiService.synchronizeFinancialData(trip.id);
          fixedTrips.add(fixedTrip);
        } catch (e) {
          debugPrint("Error synchronizing financial data for trip ${trip.id}: $e");
          // Apply the fix manually if synchronization with backend fails
          final clientFreight = trip.pricing.totalAmount > 0 
              ? trip.pricing.totalAmount 
              : 15000.0;
          final supplierFreight = clientFreight * 0.9;
          final advancePercentage = 30.0;
          final margin = clientFreight - supplierFreight;
          final advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
          final balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
          
          // Create a fixed trip with calculated financial values
          final manuallyFixedTrip = Trip(
            id: trip.id,
            orderNumber: trip.orderNumber.isEmpty ? trip.id : trip.orderNumber,
            clientId: trip.clientId,
            clientName: trip.clientName,
            clientAddress: trip.clientAddress,
            clientCity: trip.clientCity,
            supplierId: trip.supplierId,
            supplierName: trip.supplierName,
            vehicleId: trip.vehicleId,
            vehicleNumber: trip.vehicleNumber,
            vehicleType: trip.vehicleType,
            vehicleSize: trip.vehicleSize,
            vehicleCapacity: trip.vehicleCapacity,
            axleType: trip.axleType,
            source: trip.source,
            destination: trip.destination,
            destinationCity: trip.destinationCity,
            destinationAddress: trip.destinationAddress,
            distance: trip.distance,
            startDate: trip.startDate,
            endDate: trip.endDate,
            pickupDate: trip.pickupDate,
            pickupTime: trip.pickupTime,
            pricing: trip.pricing,
            documents: trip.documents,
            status: trip.status,
            createdAt: trip.createdAt,
            updatedAt: trip.updatedAt,
            clientFreight: clientFreight,
            supplierFreight: supplierFreight,
            advancePercentage: advancePercentage,
            margin: margin,
            advanceSupplierFreight: advanceSupplierFreight,
            balanceSupplierFreight: balanceSupplierFreight,
            advancePaymentStatus: trip.advancePaymentStatus,
            balancePaymentStatus: trip.balancePaymentStatus,
            lrNumbers: trip.lrNumbers,
            podUploaded: trip.podUploaded,
            podDate: trip.podDate,
            materials: trip.materials,
            ewayBills: trip.ewayBills,
            driverName: trip.driverName,
            driverPhone: trip.driverPhone,
            fieldOps: trip.fieldOps,
            notes: trip.notes,
            utrNumber: trip.utrNumber,
            paymentMethod: trip.paymentMethod,
            paymentDate: trip.paymentDate,
            paymentNotes: trip.paymentNotes,
            platformFees: trip.platformFees,
            lrCharges: trip.lrCharges,
            additionalCharges: trip.additionalCharges,
            deductionCharges: trip.deductionCharges,
          );
          
          fixedTrips.add(manuallyFixedTrip);
        }
      } else {
        fixedTrips.add(trip); // Keep the original trip if no issues
      }
    }
    
    return fixedTrips;
  } catch (e) {
    // If there's an error fetching trips, log it and return an empty list
    // instead of throwing an exception that would crash the UI
    debugPrint("Error in tripListProvider: $e");
    return [];
  }
});

// Provider for a specific trip
final tripDetailProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    // First fetch the trip using the regular method
    final trip = await apiService.getTripById(tripId);
    
    // Check if the financial data is missing or has zero values
    final hasFinancialData = trip.clientFreight != null && trip.clientFreight! > 0 && 
                             trip.supplierFreight != null && trip.supplierFreight! > 0;
    
    if (!hasFinancialData) {
      debugPrint("⚠️ Trip is missing financial data, checking for fixes: $tripId");
    } else {
      debugPrint("✓ Trip has financial data: client=${trip.clientFreight}, supplier=${trip.supplierFreight}");
    }
    
    // If financial data is missing or any payment values are wrong, synchronize them
    if (!hasFinancialData || 
        trip.advanceSupplierFreight == null || 
        trip.balanceSupplierFreight == null || 
        trip.margin == null) {
      
      try {
        debugPrint("⚠️ Synchronizing financial data for trip: $tripId");
        return await apiService.synchronizeFinancialData(tripId);
      } catch (e) {
        debugPrint("Error synchronizing financial data: $e");
        debugPrint("Applying financial fixes locally");
        
        // Apply the fix manually if synchronization fails
        final clientFreight = trip.pricing.totalAmount > 0 
            ? trip.pricing.totalAmount 
            : 15000.0;
        final supplierFreight = clientFreight * 0.9;
        final advancePercentage = 30.0;
        final margin = clientFreight - supplierFreight;
        final advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
        final balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
        
        // Create a fixed trip with calculated financial values
        return Trip(
          id: trip.id,
          orderNumber: trip.orderNumber.isEmpty ? trip.id : trip.orderNumber,
          clientId: trip.clientId,
          clientName: trip.clientName,
          clientAddress: trip.clientAddress,
          clientCity: trip.clientCity,
          supplierId: trip.supplierId,
          supplierName: trip.supplierName,
          vehicleId: trip.vehicleId,
          vehicleNumber: trip.vehicleNumber,
          vehicleType: trip.vehicleType,
          vehicleSize: trip.vehicleSize,
          vehicleCapacity: trip.vehicleCapacity,
          axleType: trip.axleType,
          source: trip.source,
          destination: trip.destination,
          destinationCity: trip.destinationCity,
          destinationAddress: trip.destinationAddress,
          distance: trip.distance,
          startDate: trip.startDate,
          endDate: trip.endDate,
          pickupDate: trip.pickupDate,
          pickupTime: trip.pickupTime,
          pricing: trip.pricing,
          documents: trip.documents,
          status: trip.status,
          createdAt: trip.createdAt,
          updatedAt: trip.updatedAt,
          clientFreight: clientFreight,
          supplierFreight: supplierFreight,
          advancePercentage: advancePercentage,
          margin: margin,
          advanceSupplierFreight: advanceSupplierFreight,
          balanceSupplierFreight: balanceSupplierFreight,
          advancePaymentStatus: trip.advancePaymentStatus,
          balancePaymentStatus: trip.balancePaymentStatus,
          lrNumbers: trip.lrNumbers,
          podUploaded: trip.podUploaded,
          podDate: trip.podDate,
          materials: trip.materials,
          ewayBills: trip.ewayBills,
          driverName: trip.driverName,
          driverPhone: trip.driverPhone,
          fieldOps: trip.fieldOps,
          notes: trip.notes,
          utrNumber: trip.utrNumber,
          paymentMethod: trip.paymentMethod,
          paymentDate: trip.paymentDate,
          paymentNotes: trip.paymentNotes,
          platformFees: trip.platformFees,
          lrCharges: trip.lrCharges,
          additionalCharges: trip.additionalCharges,
          deductionCharges: trip.deductionCharges,
        );
      }
    }
    
    // Ensure orderNumber is set
    if (trip.orderNumber.isEmpty) {
      return Trip(
        id: trip.id,
        orderNumber: trip.id, // Use ID as orderNumber if it's empty
        clientId: trip.clientId,
        clientName: trip.clientName,
        clientAddress: trip.clientAddress,
        clientCity: trip.clientCity,
        supplierId: trip.supplierId,
        supplierName: trip.supplierName,
        vehicleId: trip.vehicleId,
        vehicleNumber: trip.vehicleNumber,
        vehicleType: trip.vehicleType,
        vehicleSize: trip.vehicleSize,
        vehicleCapacity: trip.vehicleCapacity,
        axleType: trip.axleType,
        source: trip.source,
        destination: trip.destination,
        destinationCity: trip.destinationCity,
        destinationAddress: trip.destinationAddress,
        distance: trip.distance,
        startDate: trip.startDate,
        endDate: trip.endDate,
        pickupDate: trip.pickupDate,
        pickupTime: trip.pickupTime,
        pricing: trip.pricing,
        documents: trip.documents,
        status: trip.status,
        createdAt: trip.createdAt,
        updatedAt: trip.updatedAt,
        clientFreight: trip.clientFreight,
        supplierFreight: trip.supplierFreight,
        advancePercentage: trip.advancePercentage,
        margin: trip.margin,
        advanceSupplierFreight: trip.advanceSupplierFreight,
        balanceSupplierFreight: trip.balanceSupplierFreight,
        advancePaymentStatus: trip.advancePaymentStatus,
        balancePaymentStatus: trip.balancePaymentStatus,
        lrNumbers: trip.lrNumbers,
        podUploaded: trip.podUploaded,
        podDate: trip.podDate,
        materials: trip.materials,
        ewayBills: trip.ewayBills,
        driverName: trip.driverName,
        driverPhone: trip.driverPhone,
        fieldOps: trip.fieldOps,
        notes: trip.notes,
        utrNumber: trip.utrNumber,
        paymentMethod: trip.paymentMethod,
        paymentDate: trip.paymentDate,
        paymentNotes: trip.paymentNotes,
        platformFees: trip.platformFees,
        lrCharges: trip.lrCharges,
        additionalCharges: trip.additionalCharges,
        deductionCharges: trip.deductionCharges,
      );
    }
    
    return trip;
  } catch (e) {
    debugPrint("Error loading trip details: $e");
    rethrow;
  }
});

// Provider for trip creation
final createTripProvider = FutureProvider.family<Trip, Map<String, dynamic>>((ref, tripData) async {
  final apiService = ref.watch(apiServiceProvider);
  final createdTrip = await apiService.createTrip(tripData);
  
  // Invalidate the trips list provider to trigger a refresh
  ref.invalidate(tripListProvider);
  
  return createdTrip;
});

// Provider for updating a trip
final updateTripProvider = FutureProvider.family<Trip, (String, Map<String, dynamic>)>((ref, params) async {
  final (tripId, updateData) = params;
    final apiService = ref.watch(apiServiceProvider);
  final updatedTrip = await apiService.updateTrip(tripId, updateData);
    
  // Invalidate the trips list and detail providers to trigger a refresh
    ref.invalidate(tripListProvider);
  ref.invalidate(tripDetailProvider(tripId));
    
    return updatedTrip;
});

// Provider for updating payment status
final updatePaymentStatusProvider = FutureProvider.family<Trip, ({
  String id,
  String? advancePaymentStatus,
  String? balancePaymentStatus,
  String? utrNumber,
  String? paymentMethod,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    // First, get the current trip to have all the data
    final currentTrip = await apiService.getTripById(params.id);
    debugPrint('Current trip status: ${currentTrip.status}');
    debugPrint('Current advance payment status: ${currentTrip.advancePaymentStatus}');
    debugPrint('Current balance payment status: ${currentTrip.balancePaymentStatus}');
    
    // Determine effective payment statuses (use new values if provided, otherwise keep current values)
    final effectiveAdvanceStatus = params.advancePaymentStatus ?? currentTrip.advancePaymentStatus;
    final effectiveBalanceStatus = params.balancePaymentStatus ?? currentTrip.balancePaymentStatus;
    
    debugPrint('Updating payment status - Advance: $effectiveAdvanceStatus, Balance: $effectiveBalanceStatus');
    
    // Update payment status in the backend
    final updatedTrip = await apiService.updatePaymentStatus(
      params.id,
      {
        'advancePaymentStatus': params.advancePaymentStatus,
        'balancePaymentStatus': params.balancePaymentStatus,
        'utrNumber': params.utrNumber,
        'paymentMethod': params.paymentMethod,
      },
    );
    
    // Determine if trip status should also be updated
    final newStatus = _determineNewTripStatus(
      currentTrip.status,
      effectiveAdvanceStatus,
      effectiveBalanceStatus,
      currentTrip.podUploaded,
    );
    
    // If new status is different from current, update it
    if (newStatus != null && newStatus != currentTrip.status) {
      debugPrint('Updating trip status from ${currentTrip.status} to $newStatus');
      
      // Update trip status
      final finalTrip = await apiService.updateTrip(params.id, {'status': newStatus});
      
      // Invalidate the trips list and detail providers to trigger a refresh
      ref.invalidate(tripListProvider);
      ref.invalidate(tripDetailProvider(params.id));
      
      return finalTrip;
    }
    
    // Invalidate the trips list and detail providers to trigger a refresh
    ref.invalidate(tripListProvider);
    ref.invalidate(tripDetailProvider(params.id));
    
    return updatedTrip;
  } catch (e) {
    debugPrint('Error updating payment status: $e');
    rethrow;
  }
});

// Helper function to determine new trip status based on payment statuses
String? _determineNewTripStatus(String currentStatus, String? advanceStatus, String? balanceStatus, bool podUploaded) {
  // Default statuses if null
  advanceStatus = advanceStatus ?? 'Not Started';
  balanceStatus = balanceStatus ?? 'Not Started';
  
  debugPrint('Determining new status: Current=$currentStatus, Advance=$advanceStatus, Balance=$balanceStatus, POD=${podUploaded ? 'Uploaded' : 'Not Uploaded'}');
  
  // If both payments are paid, trip is completed
  if (advanceStatus == 'Paid' && balanceStatus == 'Paid') {
    debugPrint('Both payments are paid - marking as Completed');
    return 'Completed';
  }
  
  // If advance is paid but balance is not, check if POD is uploaded
  if (advanceStatus == 'Paid' && balanceStatus != 'Paid') {
    // If POD is uploaded or balance is "Ready for Payment", mark as Delivered
    if (podUploaded || balanceStatus == 'Ready for Payment') {
      debugPrint('Advance paid and POD uploaded - marking as Delivered');
      return 'Delivered';
    } else {
      // Otherwise, mark as In Transit
      debugPrint('Advance paid but no POD - marking as In Transit');
      return 'In Transit';
    }
  }
  
  // If advance is initiated or pending, keep trip in Booked state
  if (advanceStatus == 'Initiated' || advanceStatus == 'Pending') {
    if (currentStatus != 'Booked') {
      debugPrint('Advance payment initiated/pending - marking as Booked');
      return 'Booked';
    }
  }
  
  // If advance is not paid but was previously, revert to Booked state
  if (advanceStatus != 'Paid' && 
      (currentStatus == 'In Transit' || currentStatus == 'Delivered' || currentStatus == 'Completed')) {
    debugPrint('Advance payment changed from Paid - reverting to Booked');
    return 'Booked';
  }
  
  // If balance was previously paid but now isn't, and advance is paid, revert to In Transit
  if (balanceStatus != 'Paid' && advanceStatus == 'Paid' && currentStatus == 'Completed') {
    debugPrint('Balance payment changed from Paid - reverting to In Transit');
    return 'In Transit';
  }
  
  // No change needed for other cases
  debugPrint('No status change needed');
  return null;
}

// Notifier for optimistic UI updates
class TripNotifier extends StateNotifier<AsyncValue<Trip>> {
  final ApiService _apiService;
  final Ref _ref;
  final String tripId;
  
  TripNotifier(this._apiService, this._ref, this.tripId)
      : super(const AsyncValue.loading()) {
    _fetchTrip();
  }
  
  Future<void> _fetchTrip() async {
    try {
      final trip = await _apiService.getTripById(tripId);
      state = AsyncValue.data(trip);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  // Update platform fee with optimistic UI update
  Future<void> updatePlatformFee(double newFee) async {
    // Store the previous state for rollback
    final previousState = state;
    
    // Get the current trip data
    if (state.value == null) return;
    final currentTrip = state.value!;
    
    // Calculate the new balance supplier freight
    final deductionsTotal = (currentTrip.deductionCharges?.fold<double>(0, 
        (sum, charge) => sum + charge.amount) ?? 0) +
        (currentTrip.lrCharges ?? 250) + newFee;
    
    // Safely handle nullable values
    final supplierFreight = currentTrip.supplierFreight ?? 0;
    final advanceSupplierFreight = currentTrip.advanceSupplierFreight ?? 0;
    
    final originalBalance = supplierFreight - advanceSupplierFreight;
    final adjustedBalance = (originalBalance - deductionsTotal).clamp(0, double.infinity);
    final roundedBalance = adjustedBalance.round().toDouble();
    
    // Create a new trip object with updated values (this is a simplification since Trip is immutable)
    // In a real implementation, you would create a new Trip object with all the properties
    
    // Optimistically update the UI
    state = AsyncValue.data(currentTrip); // This is a placeholder, you'd create a new Trip object
    
    try {
      // Update the trip in the backend
      final updatedTrip = await _apiService.updateTrip(tripId, {
        'platformFees': newFee,
        'balanceSupplierFreight': roundedBalance,
      });
      
      // Update the state with the actual response
      state = AsyncValue.data(updatedTrip);
      
      // Refresh the trip list
      _ref.invalidate(tripListProvider);
    } catch (e) {
      // Rollback to previous state on error
      state = previousState;
      
      // Re-throw the error for handling in the UI
      throw Exception('Failed to update platform fee: $e');
    }
  }
  
  // Update payment status with automatic trip status update
  Future<void> updatePaymentStatus({
    String? advanceStatus,
    String? balanceStatus,
    String? utrNumber,
    String? paymentMethod,
  }) async {
    // Store the previous state for rollback
    final previousState = state;
    
    // Get the current trip data
    if (state.value == null) return;
    final currentTrip = state.value!;
    
    try {
      // Calculate the financial values if needed
      double clientFreight = currentTrip.clientFreight ?? 0.0;
      double supplierFreight = currentTrip.supplierFreight ?? 0.0;
      double advancePercentage = currentTrip.advancePercentage ?? 30.0;
      
      // If any of these values are 0, recalculate them
      if (clientFreight <= 0 || supplierFreight <= 0) {
        clientFreight = currentTrip.pricing.totalAmount > 0 
            ? currentTrip.pricing.totalAmount 
            : 15000.0;
        supplierFreight = clientFreight * 0.9;
      }
      
      // Calculate derived values
      double margin = clientFreight - supplierFreight;
      double advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
      double balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
      
      // Log the financial calculations
      debugPrint('Payment Update - Financial calculations:');
      debugPrint('Client Freight: $clientFreight, Supplier Freight: $supplierFreight');
      debugPrint('Margin: $margin (${(margin/clientFreight*100).toStringAsFixed(2)}%)');
      debugPrint('Advance%: $advancePercentage, Advance=$advanceSupplierFreight, Balance=$balanceSupplierFreight');
      
      // Optimistically update the UI - create a copy of the Trip with updated payment status
      // We need to provide all required fields from the current trip
      final optimisticTrip = Trip(
        id: currentTrip.id,
        orderNumber: currentTrip.orderNumber,
        clientId: currentTrip.clientId,
        clientName: currentTrip.clientName,
        vehicleId: currentTrip.vehicleId,
        vehicleType: currentTrip.vehicleType ?? 'Unknown',
        supplierId: currentTrip.supplierId,
        supplierName: currentTrip.supplierName,
        source: currentTrip.source,
        destination: currentTrip.destination,
        startDate: currentTrip.startDate,
        pricing: currentTrip.pricing,
        documents: currentTrip.documents,
        status: currentTrip.status,
        // Updated payment fields
        advancePaymentStatus: advanceStatus ?? currentTrip.advancePaymentStatus,
        balancePaymentStatus: balanceStatus ?? currentTrip.balancePaymentStatus,
        utrNumber: utrNumber ?? currentTrip.utrNumber,
        paymentMethod: paymentMethod ?? currentTrip.paymentMethod,
        // Updated financial fields with recalculated values
        clientFreight: clientFreight,
        supplierFreight: supplierFreight,
        advancePercentage: advancePercentage,
        margin: margin,
        advanceSupplierFreight: advanceSupplierFreight,
        balanceSupplierFreight: balanceSupplierFreight,
        // Copy all other fields to maintain data integrity
        lrNumbers: currentTrip.lrNumbers,
        materials: currentTrip.materials,
        fieldOps: currentTrip.fieldOps,
      );
      
      state = AsyncValue.data(optimisticTrip);
      
      // Update the payment status in the backend
      final updatedTrip = await _apiService.updatePaymentStatus(
        tripId,
        {
          'advancePaymentStatus': advanceStatus,
          'balancePaymentStatus': balanceStatus,
          'utrNumber': utrNumber,
          'paymentMethod': paymentMethod,
        },
      );
      
      // Determine if trip status should be updated
      final newStatus = _determineNewTripStatus(
        updatedTrip.status,
        updatedTrip.advancePaymentStatus,
        updatedTrip.balancePaymentStatus,
        updatedTrip.podUploaded,
      );
      
      Trip finalTrip = updatedTrip;
      
      // If status needs updating, do it
      if (newStatus != null && newStatus != updatedTrip.status) {
        finalTrip = await _apiService.updateTrip(tripId, {'status': newStatus});
      }
      
      // Update UI with final trip data
      state = AsyncValue.data(finalTrip);
      
      // Refresh the trip list
      _ref.invalidate(tripListProvider);
    } catch (e) {
      // Rollback to previous state on error
      state = previousState;
      
      // Re-throw the error for handling in the UI
      throw Exception('Failed to update payment status: $e');
    }
  }
}

// Provider for the trip notifier
final tripNotifierProvider = StateNotifierProvider.family<TripNotifier, AsyncValue<Trip>, String>(
  (ref, tripId) {
    final apiService = ref.watch(apiServiceProvider);
    return TripNotifier(apiService, ref, tripId);
  },
); 

// Provider for uploading a document
final uploadDocumentProvider = FutureProvider.family<void, ({
  String tripId,
  Map<String, dynamic> docData,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint('Starting document upload for trip ${params.tripId}');
    // Log the document data for debugging (excluding the file bytes)
    final Map<String, dynamic> logData = Map.from(params.docData);
    if (logData['file'] is Map && logData['file']['bytes'] != null) {
      final bytesLength = (logData['file']['bytes'] as List).length;
      logData['file'] = {
        'name': logData['file']['name'],
        'size': logData['file']['size'],
        'bytes': '${bytesLength} bytes'
      };
    }
    debugPrint('Document data: $logData');
    
    // Upload the document
    await apiService.uploadDocument(params.tripId, params.docData);
    
    debugPrint('Document uploaded successfully');
    
    // Refresh the trip detail provider
    ref.invalidate(tripDetailProvider(params.tripId));
  } catch (e, stackTrace) {
    debugPrint('Error in uploadDocumentProvider: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
});

// Use the imported PaymentParams class instead of the local definition
final processPaymentProvider = FutureProvider.family<Trip, PaymentParams>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    // Use the new process payment endpoint
    final trip = await apiService.processPayment(
      params.id,
      paymentType: params.paymentType,
      paymentStatus: params.paymentStatus,
      utrNumber: params.utrNumber,
      paymentMethod: params.paymentMethod,
    );
    
    // Refresh the trip list after updating payment status
    ref.invalidate(tripListProvider);
    
    return trip;
  } catch (e) {
    debugPrint("Error processing payment: $e");
    throw Exception("Error processing payment: $e");
  }
});

// Provider for updating additional charges
final updateAdditionalChargesProvider = FutureProvider.family<Trip, ({
  String tripId,
  List<Map<String, dynamic>> additionalCharges,
  List<Map<String, dynamic>> deductionCharges,
  double newBalanceAmount,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    debugPrint('Updating additional charges for trip ${params.tripId}');
    debugPrint('Additional charges: ${params.additionalCharges.length}');
    debugPrint('Deduction charges: ${params.deductionCharges.length}');
    debugPrint('New balance amount: ${params.newBalanceAmount}');
    
    // Update additional charges using the API service
    final trip = await apiService.updateAdditionalCharges(
      params.tripId,
      params.additionalCharges,
      params.deductionCharges,
      params.newBalanceAmount,
    );
    
    // Refresh the trip list and trip detail after updating additional charges
    ref.invalidate(tripListProvider);
    ref.invalidate(tripDetailProvider(params.tripId));
    
    debugPrint('Additional charges updated successfully');
    return trip;
  } catch (e) {
    debugPrint("Error updating additional charges: $e");
    throw Exception("Error updating additional charges: $e");
  }
}); 