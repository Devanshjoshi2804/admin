import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';
import 'package:freight_flow_flutter/models/supplier.dart';

// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Vehicle notifier for managing vehicle state
class VehicleNotifier extends StateNotifier<AsyncValue<List<Vehicle>>> {
  VehicleNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadVehicles();
  }

  final ApiService _apiService;

  Future<void> loadVehicles() async {
    try {
      state = const AsyncValue.loading();
      final vehicles = await _apiService.getVehicles();
      state = AsyncValue.data(vehicles);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    try {
      await _apiService.createVehicle(vehicle.toJson());
      await loadVehicles(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _apiService.updateVehicle(vehicle.id, vehicle.toJson());
      await loadVehicles(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _apiService.deleteVehicle(vehicleId);
      await loadVehicles(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }
}

// Provider for the vehicle notifier
final vehicleNotifierProvider = StateNotifierProvider<VehicleNotifier, AsyncValue<List<Vehicle>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VehicleNotifier(apiService);
});

// Provider for all vehicles (using the notifier)
final vehiclesProvider = Provider<AsyncValue<List<Vehicle>>>((ref) {
  return ref.watch(vehicleNotifierProvider);
});

// Provider for a single vehicle by ID
final vehicleProvider = FutureProvider.family<Vehicle, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getVehicleById(id);
});

// Provider for creating a vehicle
final createVehicleProvider = FutureProvider.family<Vehicle, Map<String, dynamic>>((ref, vehicleData) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    final newVehicle = await apiService.createVehicle(vehicleData);
    
    // Refresh the vehicles list after creating a new vehicle
    ref.invalidate(vehiclesProvider);
    
    return newVehicle;
  } catch (e) {
    print("Error creating vehicle: $e");
    throw Exception('Failed to create vehicle: $e');
  }
});

// Provider for updating a vehicle
final updateVehicleProvider = FutureProvider.family<Vehicle, ({String id, Map<String, dynamic> data})>(
  (ref, params) async {
    final apiService = ref.watch(apiServiceProvider);
    
    try {
      final updatedVehicle = await apiService.updateVehicle(params.id, params.data);
      
      // Refresh the vehicles list and vehicle detail providers
      ref.invalidate(vehiclesProvider);
      ref.invalidate(vehicleProvider(params.id));
      
      return updatedVehicle;
    } catch (e) {
      print("Error updating vehicle: $e");
      throw Exception('Failed to update vehicle: $e');
    }
  },
);

// Provider for deleting a vehicle
final deleteVehicleProvider = FutureProvider.family<void, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    await apiService.deleteVehicle(id);
    
    // Refresh the vehicles list after deleting a vehicle
    ref.invalidate(vehiclesProvider);
  } catch (e) {
    print("Error deleting vehicle: $e");
    throw Exception('Failed to delete vehicle: $e');
  }
});

// Provider for uploading vehicle documents
final uploadVehicleDocumentProvider = FutureProvider.family<void, ({
  String vehicleId,
  Map<String, dynamic> docData,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    await apiService.uploadVehicleDocument(params.vehicleId, params.docData);
    
    // Refresh the vehicle detail provider
    ref.invalidate(vehicleProvider(params.vehicleId));
  } catch (e) {
    print("Error uploading vehicle document: $e");
    throw Exception('Failed to upload vehicle document: $e');
  }
});

// Provider to get all suppliers for vehicle assignment
final vehicleSuppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSuppliers();
}); 