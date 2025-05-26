import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider for the current booking form step
final bookingStepProvider = StateProvider<int>((ref) => 0);

// Provider for the booking form data
final bookingFormDataProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Provider for fetching clients for the booking form
final bookingClientsProvider = FutureProvider<List<Client>>((ref) async {
  try {
  final apiService = ref.watch(apiServiceProvider);
    return await apiService.getClients();
  } catch (e) {
    print("Error fetching clients: $e");
    // Return empty list instead of throwing to prevent UI crashes
    return [];
  }
});

// Provider for fetching suppliers for the booking form
final bookingSuppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  try {
  final apiService = ref.watch(apiServiceProvider);
    return await apiService.getSuppliers();
  } catch (e) {
    print("Error fetching suppliers: $e");
    // Return empty list instead of throwing to prevent UI crashes
    return [];
  }
});

// Provider for getting client details by ID
final clientDetailsProvider = FutureProvider.family<Client, String>((ref, clientId) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    print("Fetching client details for ID: $clientId");
    final client = await apiService.getClientById(clientId);
    print("Client details fetched successfully: ${client.name}, ${client.address}, ${client.city}");
    return client;
  } catch (e) {
    print("Error fetching client details: $e");
    throw e;
  }
});

// Provider for getting supplier details by ID
final supplierDetailsProvider = FutureProvider.family<Supplier, String>((ref, supplierId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSupplierById(supplierId);
});

// Provider for calculating material cost based on weight and rate
final materialCostProvider = Provider.family<double, Map<String, dynamic>>((ref, materialData) {
  double weight = double.tryParse(materialData['weight']?.toString() ?? '0') ?? 0;
  double ratePerMT = double.tryParse(materialData['ratePerMT']?.toString() ?? '0') ?? 0;
  double totalCost = weight * ratePerMT;
  print("Material cost calculation: Weight: $weight, Rate: $ratePerMT, Total: $totalCost");
  return totalCost;
});

// Provider for fetching vehicles for the booking form
final bookingVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  try {
  final apiService = ref.watch(apiServiceProvider);
    return await apiService.getVehicles();
  } catch (e) {
    print("Error fetching vehicles: $e");
    // Return empty list instead of throwing to prevent UI crashes
    return [];
  }
});

// Provider for getting vehicle details by ID
final vehicleDetailsProvider = FutureProvider.family<Vehicle, String>((ref, vehicleId) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    print("Fetching vehicle details for ID: $vehicleId");
    
    // Validate the vehicle ID
    if (vehicleId.isEmpty) {
      print("Warning: Empty vehicle ID provided");
      // Return a default vehicle with empty values instead of throwing
      return Vehicle(
        id: '',
        vehicleNumber: 'Unknown Vehicle',
        vehicleType: 'N/A',
        vehicleSize: 'N/A',
        vehicleCapacity: 'N/A',
        axleType: 'N/A',
        ownerId: '',
        isActive: false,
      );
    }
    
    // Use a try-catch block specifically for the API call
    try {
    final vehicle = await apiService.getVehicleById(vehicleId);
      
      // Extra validation to ensure we have valid data
      if (vehicle.vehicleNumber.isEmpty) {
        print("Warning: Vehicle data has empty vehicle number for ID: $vehicleId");
      }
      
    print("Vehicle details fetched successfully: ${vehicle.vehicleNumber}, ${vehicle.vehicleType}");
      
      // Schedule UI update using post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.state.isLoading) {
          ref.state = AsyncValue.data(vehicle);
        }
      });
      
    return vehicle;
    } catch (apiError) {
      print("API Error fetching vehicle: $apiError");
      // If API fails, return a default vehicle instead of throwing
      return Vehicle(
        id: vehicleId,
        vehicleNumber: 'Error Loading',
        vehicleType: 'Unknown',
        vehicleSize: 'N/A',
        vehicleCapacity: 'N/A',
        axleType: 'N/A',
        ownerId: '',
        isActive: false,
      );
    }
  } catch (e) {
    print("Critical error in vehicleDetailsProvider: $e");
    // Add more detailed error logging
    if (e is Exception) {
      print("Exception details: ${e.toString()}");
    }
    
    // Return a default vehicle with error indication instead of throwing
    return Vehicle(
      id: vehicleId,
      vehicleNumber: 'Error: ${e.toString().substring(0, math.min(30, e.toString().length))}...',
      vehicleType: 'Error',
      vehicleSize: 'N/A',
      vehicleCapacity: 'N/A',
      axleType: 'N/A',
      ownerId: '',
      isActive: false,
    );
  }
});

// Provider for calculating total material cost for all materials
final totalMaterialCostProvider = Provider.family<double, List<Map<String, dynamic>>>((ref, materials) {
  double totalCost = 0;
  for (var material in materials) {
    totalCost += ref.watch(materialCostProvider(material));
  }
  return totalCost;
});

// Provider for submitting a booking
final submitBookingProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, formData) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    
    // Process the form data to match API requirements
    Map<String, dynamic> processedData = Map.from(formData);
    
    // Process any DateTimes to ISO strings
    _processNestedDates(processedData);
    
    // Ensure numeric values are properly parsed
    final clientFreight = double.tryParse(processedData['clientFreight']?.toString().replaceAll(',', '') ?? '0') ?? 0;
    final supplierFreight = double.tryParse(processedData['supplierFreight']?.toString().replaceAll(',', '') ?? '0') ?? 0;
    final advancePercentage = double.tryParse(processedData['advancePercentage']?.toString() ?? '30') ?? 30;
    
    // Calculate derived values
    final margin = clientFreight - supplierFreight;
    final advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
    final balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
    
    // Make sure all required fields are included with double precision
    processedData['clientFreight'] = clientFreight;
    processedData['supplierFreight'] = supplierFreight;
    processedData['advancePercentage'] = advancePercentage;
    processedData['margin'] = margin;
    processedData['advanceSupplierFreight'] = advanceSupplierFreight;
    processedData['balanceSupplierFreight'] = balanceSupplierFreight;
    
    print("Submitting booking with data: ${processedData.keys.join(', ')}");
    print("Processing booking data with calculated values:");
    print("Client Freight: $clientFreight, Supplier Freight: $supplierFreight");
    print("Margin: $margin, Advance: $advanceSupplierFreight, Balance: $balanceSupplierFreight");
    
    // Generate a properly formatted order number if not provided
    final dateFormatted = DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    final randomPart = DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12);
    final orderNumber = processedData['tripNumber'] ?? 'FTL-$dateFormatted-$randomPart';
    
    // Extract LR numbers with better validation
    final List<String> lrNumbers = [];
    if (processedData['lrNumber'] != null && processedData['lrNumber'].toString().isNotEmpty) {
      lrNumbers.add(processedData['lrNumber'].toString());
    }
    
    // Prepare field operations data
    final fieldOps = {
      'name': processedData['fieldOpsName']?.toString() ?? '',
      'phone': processedData['fieldOpsPhone']?.toString() ?? '',
      'email': processedData['fieldOpsEmail']?.toString() ?? '',
    };
    
    // Format the data for the API
    final apiTripData = {
      'clientId': processedData['clientId'],
      'clientName': processedData['clientName']?.toString(),
      'clientAddress': processedData['clientAddress']?.toString(),
      'clientCity': processedData['clientCity']?.toString(),
      'supplierId': processedData['supplierId'],
      'supplierName': processedData['supplierName']?.toString(),
      'vehicleId': processedData['vehicleId'],
      'vehicleNumber': processedData['vehicleNumber']?.toString(),
      'vehicleType': processedData['vehicleType']?.toString(),
      'vehicleSize': processedData['vehicleSize']?.toString(),
      'vehicleCapacity': processedData['vehicleCapacity']?.toString(),
      'axleType': processedData['axleType']?.toString(),
      'source': processedData['source'],
      'destination': processedData['destination'],
      'distance': int.tryParse(processedData['distance']?.toString() ?? '0') ?? 0,
      'startDate': processedData['pickupDate'] ?? DateTime.now().toIso8601String(),
      'pickupDate': processedData['pickupDate'] ?? DateTime.now().toIso8601String(),
      'pickupTime': processedData['pickupTime']?.toString() ?? '9:00 AM',
      'orderNumber': orderNumber,
      'status': 'Booked',
      'pricing': {
        'baseAmount': clientFreight,
        'gst': 0,
        'totalAmount': clientFreight
      },
      'clientFreight': clientFreight,
      'supplierFreight': supplierFreight,
      'advancePercentage': advancePercentage,
      'margin': margin,
      'advanceSupplierFreight': advanceSupplierFreight,
      'balanceSupplierFreight': balanceSupplierFreight,
      'advancePaymentStatus': 'Pending',
      'balancePaymentStatus': 'Pending',
      'lrNumbers': lrNumbers,
      'driverName': processedData['driverName']?.toString() ?? 'Unknown Driver',
      'driverPhone': processedData['driverPhone']?.toString() ?? '',
      'fieldOps': fieldOps,
      'podUploaded': false,
      
      // Add additional fields to ensure consistent display in trips list
      'destinationCity': processedData['destinationCity']?.toString() ?? processedData['destination'],
      'destinationAddress': processedData['destinationAddress']?.toString() ?? '',
      
      // Ensure vehicle details are included
      'vehicleDetails': {
        'number': processedData['vehicleNumber']?.toString() ?? 'Unknown Vehicle',
        'type': processedData['vehicleType']?.toString() ?? 'Truck',
        'size': processedData['vehicleSize']?.toString() ?? '',
        'capacity': processedData['vehicleCapacity']?.toString() ?? '',
        'axleType': processedData['axleType']?.toString() ?? '',
      },
      
      // Include payment tracking info
      'utrNumber': '',
      'paymentMethod': 'Bank Transfer',
      'paymentDate': null,
      'paymentNotes': ''
    };
    
    // Add materials if present
    if (processedData['materials'] != null && processedData['materials'] is List) {
      apiTripData['materials'] = processedData['materials'];
    }
    
    // Add optional fields if present
    if (processedData['notes'] != null) {
      apiTripData['notes'] = processedData['notes'];
    }
    
    print("Formatted API trip data: ${apiTripData.keys.join(', ')}");
    
    try {
      // Create the trip with the formatted data
      final trip = await apiService.createTrip(apiTripData);
      
      print("Trip created successfully with ID: ${trip.id}");
      
      // Store the trip ID for document uploads
      if (trip.id.isNotEmpty) {
        final currentState = ref.read(bookingFormDataProvider);
        ref.read(bookingFormDataProvider.notifier).state = {
          ...currentState,
          'tripId': trip.id,
        };
        
        print("Trip ID stored in provider: ${trip.id}");
    return true;
      } else {
        print("Error: Trip created but ID is empty");
        return false;
      }
    } catch (tripError) {
      print("Error in trip creation: $tripError");
      if (tripError is TypeError) {
        print("Type error details: ${tripError.toString()}");
      }
      return false;
    }
  } catch (e) {
    print("Error submitting booking: $e");
    return false;
  }
});

// Helper function to process nested date objects
void _processNestedDates(dynamic data) {
  if (data is Map<String, dynamic>) {
    // Process each entry in the map
    data.forEach((key, value) {
      if (value is DateTime) {
        data[key] = value.toIso8601String();
      } else if (value is Map) {
        _processNestedDates(value);
      } else if (value is List) {
        _processNestedDates(value);
      }
    });
  } else if (data is List) {
    // Process each item in the list
    for (int i = 0; i < data.length; i++) {
      if (data[i] is DateTime) {
        data[i] = data[i].toIso8601String();
      } else if (data[i] is Map || data[i] is List) {
        _processNestedDates(data[i]);
      }
    }
  }
}

// Provider for calculating freight values
final freightCalculationProvider = Provider.family<Map<String, double>, Map<String, dynamic>>((ref, formData) {
  double clientFreight = double.tryParse(formData['clientFreight']?.toString() ?? '0') ?? 0;
  double supplierFreight = double.tryParse(formData['supplierFreight']?.toString() ?? '0') ?? 0;
  double advancePercentage = double.tryParse(formData['advancePercentage']?.toString() ?? '30') ?? 30;
  
  double margin = clientFreight - supplierFreight;
  double advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
  double balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
  
  print("Freight calculations in provider:");
  print("Client Freight: $clientFreight, Supplier Freight: $supplierFreight, Advance %: $advancePercentage");
  print("Margin: $margin, Advance: $advanceSupplierFreight, Balance: $balanceSupplierFreight");
  
  return {
    'margin': margin,
    'advanceSupplierFreight': advanceSupplierFreight,
    'balanceSupplierFreight': balanceSupplierFreight,
  };
}); 