import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/services/ultra_fast_api_service.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';

// ==================== ULTRA-FAST SERVICE PROVIDER ====================

/// Ultra-fast API service singleton provider
final ultraFastApiServiceProvider = Provider<UltraFastApiService>((ref) {
  final service = UltraFastApiService();
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// ==================== ULTRA-FAST TRIP PROVIDERS ====================

/// Ultra-fast trips provider with pagination and filtering
final ultraFastTripsProvider = FutureProvider.family<List<Trip>, ({
  int page,
  int limit,
  String? status,
  String? clientId,
})>((ref, params) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getTripsUltraFast(
    page: params.page,
    limit: params.limit,
    status: params.status,
    clientId: params.clientId,
  );
});

/// Ultra-fast single trip provider
final ultraFastTripProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getTripUltraFast(tripId);
});

/// Ultra-fast dashboard provider
final ultraFastDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getDashboardUltraFast();
});

/// Ultra-fast advance payment queue provider
final ultraFastAdvanceQueueProvider = FutureProvider<List<Trip>>((ref) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getPaymentQueueUltraFast('advance');
});

/// Ultra-fast balance payment queue provider
final ultraFastBalanceQueueProvider = FutureProvider<List<Trip>>((ref) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getPaymentQueueUltraFast('balance');
});

// ==================== ULTRA-FAST PAYMENT PROVIDERS ====================

/// Ultra-fast payment processor
final ultraFastPaymentProcessor = FutureProvider.family<Map<String, dynamic>, ({
  String tripId,
  String paymentType,
  String targetStatus,
  String? utrNumber,
  String? paymentMethod,
})>((ref, params) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.processPaymentUltraFast(
    tripId: params.tripId,
    paymentType: params.paymentType,
    targetStatus: params.targetStatus,
    utrNumber: params.utrNumber,
    paymentMethod: params.paymentMethod,
  );
  
  // Invalidate related providers for instant UI updates
  ref.invalidate(ultraFastTripsProvider);
  ref.invalidate(ultraFastTripProvider(params.tripId));
  ref.invalidate(ultraFastAdvanceQueueProvider);
  ref.invalidate(ultraFastBalanceQueueProvider);
  ref.invalidate(ultraFastDashboardProvider);
  
  return result;
});

/// One-click payment progression provider
final oneClickPaymentProvider = FutureProvider.family<Map<String, dynamic>, ({
  String tripId,
  String paymentType,
})>((ref, params) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  // Determine next status based on current status
  String targetStatus = 'Paid'; // Default to paid for one-click
  
  final result = await service.processPaymentUltraFast(
    tripId: params.tripId,
    paymentType: params.paymentType,
    targetStatus: targetStatus,
  );
  
  // Invalidate related providers
  ref.invalidate(ultraFastTripsProvider);
  ref.invalidate(ultraFastTripProvider(params.tripId));
  ref.invalidate(ultraFastAdvanceQueueProvider);
  ref.invalidate(ultraFastBalanceQueueProvider);
  ref.invalidate(ultraFastDashboardProvider);
  
  return result;
});

// ==================== ULTRA-FAST CLIENT PROVIDERS ====================

/// Ultra-fast clients provider
final ultraFastClientsProvider = FutureProvider<List<Client>>((ref) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getClientsUltraFast();
});

/// Ultra-fast single client provider
final ultraFastClientProvider = FutureProvider.family<Client, String>((ref, clientId) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getClientUltraFast(clientId);
});

/// Ultra-fast client creator
final ultraFastClientCreator = FutureProvider.family<Client, Map<String, dynamic>>((ref, clientData) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.createClientUltraFast(clientData);
  
  // Invalidate clients list for instant UI updates
  ref.invalidate(ultraFastClientsProvider);
  
  return result;
});

/// Ultra-fast client updater
final ultraFastClientUpdater = FutureProvider.family<Client, ({
  String clientId,
  Map<String, dynamic> clientData,
})>((ref, params) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.updateClientUltraFast(params.clientId, params.clientData);
  
  // Invalidate related providers
  ref.invalidate(ultraFastClientsProvider);
  ref.invalidate(ultraFastClientProvider(params.clientId));
  
  return result;
});

// ==================== ULTRA-FAST SUPPLIER PROVIDERS ====================

/// Ultra-fast suppliers provider
final ultraFastSuppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getSuppliersUltraFast();
});

/// Ultra-fast single supplier provider
final ultraFastSupplierProvider = FutureProvider.family<Supplier, String>((ref, supplierId) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getSupplierUltraFast(supplierId);
});

/// Ultra-fast supplier creator
final ultraFastSupplierCreator = FutureProvider.family<Supplier, Map<String, dynamic>>((ref, supplierData) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.createSupplierUltraFast(supplierData);
  
  // Invalidate suppliers list for instant UI updates
  ref.invalidate(ultraFastSuppliersProvider);
  
  return result;
});

/// Ultra-fast supplier updater
final ultraFastSupplierUpdater = FutureProvider.family<Supplier, ({
  String supplierId,
  Map<String, dynamic> supplierData,
})>((ref, params) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.updateSupplierUltraFast(params.supplierId, params.supplierData);
  
  // Invalidate related providers
  ref.invalidate(ultraFastSuppliersProvider);
  ref.invalidate(ultraFastSupplierProvider(params.supplierId));
  
  return result;
});

// ==================== ULTRA-FAST VEHICLE PROVIDERS ====================

/// Ultra-fast vehicles provider
final ultraFastVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getVehiclesUltraFast();
});

/// Ultra-fast single vehicle provider
final ultraFastVehicleProvider = FutureProvider.family<Vehicle, String>((ref, vehicleId) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getVehicleUltraFast(vehicleId);
});

/// Ultra-fast vehicle creator
final ultraFastVehicleCreator = FutureProvider.family<Vehicle, Map<String, dynamic>>((ref, vehicleData) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.createVehicleUltraFast(vehicleData);
  
  // Invalidate vehicles list for instant UI updates
  ref.invalidate(ultraFastVehiclesProvider);
  
  return result;
});

/// Ultra-fast vehicle updater
final ultraFastVehicleUpdater = FutureProvider.family<Vehicle, ({
  String vehicleId,
  Map<String, dynamic> vehicleData,
})>((ref, params) async {
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final result = await service.updateVehicleUltraFast(params.vehicleId, params.vehicleData);
  
  // Invalidate related providers
  ref.invalidate(ultraFastVehiclesProvider);
  ref.invalidate(ultraFastVehicleProvider(params.vehicleId));
  
  return result;
});

// ==================== PERFORMANCE & UTILITY PROVIDERS ====================

/// Performance metrics provider
final performanceMetricsProvider = Provider<Map<String, double>>((ref) {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getPerformanceMetrics();
});

/// Connection status provider
final connectionStatusProvider = Provider<bool>((ref) {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.isConnected;
});

/// Cache status provider
final cacheStatusProvider = Provider<int>((ref) {
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.cacheSize;
});

/// Cache clearer provider
final cacheClearProvider = Provider<void Function()>((ref) {
  final service = ref.watch(ultraFastApiServiceProvider);
  return () {
    service.clearCache();
    // Invalidate all providers to force refresh
    ref.invalidate(ultraFastTripsProvider);
    ref.invalidate(ultraFastClientsProvider);
    ref.invalidate(ultraFastSuppliersProvider);
    ref.invalidate(ultraFastVehiclesProvider);
    ref.invalidate(ultraFastDashboardProvider);
    ref.invalidate(ultraFastAdvanceQueueProvider);
    ref.invalidate(ultraFastBalanceQueueProvider);
  };
});

// ==================== AUTO-REFRESH PROVIDERS ====================

/// Auto-refresh timer for real-time updates
final autoRefreshProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (count) => count);
});

/// Auto-refresh trips when timer ticks
final autoRefreshTripsProvider = FutureProvider<List<Trip>>((ref) async {
  // Watch the auto-refresh timer
  ref.watch(autoRefreshProvider);
  
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getTripsUltraFast(limit: 50);
});

/// Auto-refresh payment queues when timer ticks
final autoRefreshPaymentQueuesProvider = FutureProvider<Map<String, List<Trip>>>((ref) async {
  // Watch the auto-refresh timer
  ref.watch(autoRefreshProvider);
  
  final service = ref.watch(ultraFastApiServiceProvider);
  
  final advanceQueue = await service.getPaymentQueueUltraFast('advance');
  final balanceQueue = await service.getPaymentQueueUltraFast('balance');
  
  return {
    'advance': advanceQueue,
    'balance': balanceQueue,
  };
});

/// Auto-refresh dashboard when timer ticks
final autoRefreshDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Watch the auto-refresh timer
  ref.watch(autoRefreshProvider);
  
  final service = ref.watch(ultraFastApiServiceProvider);
  return service.getDashboardUltraFast();
});

// ==================== HELPER FUNCTIONS ====================

/// Invalidate all trip-related providers
void invalidateAllTripProviders(WidgetRef ref) {
  ref.invalidate(ultraFastTripsProvider);
  ref.invalidate(ultraFastAdvanceQueueProvider);
  ref.invalidate(ultraFastBalanceQueueProvider);
  ref.invalidate(ultraFastDashboardProvider);
  ref.invalidate(autoRefreshTripsProvider);
  ref.invalidate(autoRefreshPaymentQueuesProvider);
  ref.invalidate(autoRefreshDashboardProvider);
}

/// Invalidate all client-related providers
void invalidateAllClientProviders(WidgetRef ref) {
  ref.invalidate(ultraFastClientsProvider);
}

/// Invalidate all supplier-related providers
void invalidateAllSupplierProviders(WidgetRef ref) {
  ref.invalidate(ultraFastSuppliersProvider);
}

/// Invalidate all vehicle-related providers
void invalidateAllVehicleProviders(WidgetRef ref) {
  ref.invalidate(ultraFastVehiclesProvider);
}

/// Invalidate all providers (nuclear option)
void invalidateAllProviders(WidgetRef ref) {
  invalidateAllTripProviders(ref);
  invalidateAllClientProviders(ref);
  invalidateAllSupplierProviders(ref);
  invalidateAllVehicleProviders(ref);
} 