import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/optimized_providers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Ultra-fast payment processing with instant UI updates
final ultraFastPaymentProcessor = FutureProvider.family<Map<String, dynamic>, ({
  String tripId,
  String paymentType, // 'advance' or 'balance'
  String targetStatus, // 'Initiated', 'Pending', 'Paid'
  String? utrNumber,
  String? paymentMethod,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint("🚀 Ultra-fast payment processing: ${params.tripId} - ${params.paymentType} -> ${params.targetStatus}");
    
    // Use the ultra-fast payment update endpoint
    final result = await apiService.ultraFastPaymentUpdate(
      params.tripId,
      {
        'paymentType': params.paymentType,
        'targetStatus': params.targetStatus,
        'utrNumber': params.utrNumber,
        'paymentMethod': params.paymentMethod,
      },
    );
    
    // Instantly invalidate relevant caches for immediate refresh
    invalidatePaymentsCaches();
    invalidateTripsCaches();
    
    debugPrint("✅ Ultra-fast payment update completed in ~${result['processingTime'] ?? 'unknown'}ms");
    
    return result;
  } catch (e) {
    debugPrint("❌ Ultra-fast payment processing failed: $e");
    rethrow;
  }
});

// Lightning-fast batch payment processing
final batchPaymentProcessor = FutureProvider.family<List<Map<String, dynamic>>, List<({
  String tripId,
  String paymentType,
  String targetStatus,
  String? utrNumber,
  String? paymentMethod,
})>>((ref, updates) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint("🚀 Batch processing ${updates.length} payments");
    
    // Convert to the format expected by the API
    final bulkUpdates = updates.map((update) => {
      'tripId': update.tripId,
      'paymentType': update.paymentType,
      'targetStatus': update.targetStatus,
      if (update.utrNumber != null) 'utrNumber': update.utrNumber,
      if (update.paymentMethod != null) 'paymentMethod': update.paymentMethod,
    }).toList();
    
    // Use batch ultra-fast update API for maximum speed
    final results = await apiService.batchUltraFastPaymentUpdate(bulkUpdates);
    
    // Invalidate caches for immediate refresh
    invalidatePaymentsCaches();
    invalidateTripsCaches();
    
    debugPrint("✅ Batch payment processing completed");
    
    return results;
  } catch (e) {
    debugPrint("❌ Batch payment processing failed: $e");
    rethrow;
  }
});

// Instant payment status determiner (determines next status without API call)
String getNextPaymentStatus(String? currentStatus) {
  switch (currentStatus) {
    case 'Not Started':
    case null:
      return 'Initiated';
    case 'Initiated':
      return 'Pending';
    case 'Pending':
      return 'Paid';
    default:
      return currentStatus; // Already at final status
  }
}

// Lightning-fast single-click payment processor
final oneClickPaymentProcessor = FutureProvider.family<Map<String, dynamic>, ({
  String tripId,
  String paymentType,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint("⚡ One-click payment processing: ${params.tripId} - ${params.paymentType}");
    
    // Use the lightning-fast payment progression endpoint
    final result = await apiService.progressPaymentStatus(
      params.tripId,
      params.paymentType,
    );
    
    // Instantly invalidate relevant caches for immediate refresh
    invalidatePaymentsCaches();
    invalidateTripsCaches();
    
    debugPrint("✅ One-click payment processing completed in ~${result['processingTime'] ?? 'unknown'}ms");
    
    return result;
  } catch (e) {
    debugPrint("❌ One-click payment processing failed: $e");
    rethrow;
  }
});

// Instant payment validation (check if payment can be processed)
bool canProcessPayment(Trip trip, String paymentType) {
  if (paymentType == 'balance') {
    // Balance payment requires advance payment to be completed and POD uploaded
    return trip.advancePaymentStatus == 'Paid' && (trip.podUploaded ?? false);
  }
  
  // Advance payment can always be processed if not already paid
  return trip.advancePaymentStatus != 'Paid';
}

// Get payment processing button text
String getPaymentButtonText(String? currentStatus) {
  switch (currentStatus) {
    case 'Not Started':
    case null:
      return 'Initiate Payment';
    case 'Initiated':
      return 'Mark Pending';
    case 'Pending':
      return 'Mark Paid';
    case 'Paid':
      return 'Completed';
    default:
      return 'Update Status';
  }
}

// Get payment processing button color
Map<String, dynamic> getPaymentButtonStyle(String? currentStatus) {
  switch (currentStatus) {
    case 'Not Started':
    case null:
      return {'color': 'blue', 'enabled': true};
    case 'Initiated':
      return {'color': 'orange', 'enabled': true};
    case 'Pending':
      return {'color': 'green', 'enabled': true};
    case 'Paid':
      return {'color': 'grey', 'enabled': false};
    default:
      return {'color': 'blue', 'enabled': true};
  }
}

// Instant payment validation provider
final paymentValidationProvider = FutureProvider.family<Map<String, dynamic>, ({
  String tripId,
  String paymentType,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    final validation = await apiService.canProcessPayment(
      params.tripId,
      params.paymentType,
    );
    
    return validation;
  } catch (e) {
    debugPrint("❌ Payment validation failed: $e");
    return {
      'canProcess': false,
      'reason': 'Validation failed: $e',
    };
  }
});

// ⚡ Ultra-fast trip loading providers
final ultraFastTripsProvider = FutureProvider.family<List<Trip>, ({
  int page,
  int limit,
  String? status,
  String? clientId,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint("⚡ Ultra-fast trip loading: page=${params.page}, limit=${params.limit}");
    
    // Build query string
    String queryString = 'page=${params.page}&limit=${params.limit}';
    if (params.status != null && params.status!.isNotEmpty) {
      queryString += '&status=${params.status}';
    }
    if (params.clientId != null && params.clientId!.isNotEmpty) {
      queryString += '&clientId=${params.clientId}';
    }
    
    // Use the public method to make the request
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/trips/ultra-fast?$queryString'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> tripsData = responseData['data'];
        
        List<Trip> trips = [];
        for (final tripData in tripsData) {
          try {
            // Use Trip.fromJson directly since data should be properly formatted
            final trip = Trip.fromJson(tripData);
            trips.add(trip);
          } catch (e) {
            debugPrint("Error processing ultra-fast trip: $e");
            continue;
          }
        }
        
        debugPrint("✅ Ultra-fast trip loading completed: ${trips.length} trips");
        return trips;
      } else {
        throw Exception('Invalid response format from ultra-fast endpoint');
      }
    } else {
      throw Exception('Ultra-fast endpoint returned ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("❌ Ultra-fast trip loading failed: $e");
    
    // Fallback to existing optimized method
    try {
      return await apiService.getTripsPaginated(params.page, params.limit);
    } catch (fallbackError) {
      debugPrint("❌ Fallback also failed: $fallbackError");
      rethrow;
    }
  }
});

// Ultra-fast single trip provider
final ultraFastTripProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint("⚡ Ultra-fast single trip loading: $tripId");
    
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/trips/$tripId/ultra-fast'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final tripData = responseData['data'];
        
        final trip = Trip.fromJson(tripData);
        debugPrint("✅ Ultra-fast trip loading completed: ${trip.id}");
        return trip;
      } else {
        throw Exception('Invalid response format from ultra-fast endpoint');
      }
    } else {
      throw Exception('Ultra-fast trip endpoint returned ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("❌ Ultra-fast trip loading failed: $e");
    
    // Fallback to existing method
    return await apiService.getTripById(tripId);
  }
});

// Ultra-fast dashboard provider
final ultraFastDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    debugPrint("⚡ Ultra-fast dashboard loading");
    
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/trips/dashboard/ultra-fast'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      if (responseData['success'] == true && responseData['data'] != null) {
        debugPrint("✅ Ultra-fast dashboard loading completed");
        return responseData['data'];
      } else {
        throw Exception('Invalid response format from ultra-fast dashboard endpoint');
      }
    } else {
      throw Exception('Ultra-fast dashboard endpoint returned ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("❌ Ultra-fast dashboard loading failed: $e");
    
    // Fallback to manual calculation
    final trips = await apiService.getTrips();
    return {
      'stats': {
        'totalTrips': trips.length,
        'bookedTrips': trips.where((t) => t.status == 'Booked').length,
        'inTransitTrips': trips.where((t) => t.status == 'In Transit').length,
        'completedTrips': trips.where((t) => t.status == 'Completed').length,
        'pendingAdvancePayments': trips.where((t) => t.advancePaymentStatus != 'Paid').length,
        'pendingBalancePayments': trips.where((t) => t.balancePaymentStatus != 'Paid' && t.advancePaymentStatus == 'Paid').length,
      },
      'recentTrips': trips.take(10).toList(),
    };
  }
}); 