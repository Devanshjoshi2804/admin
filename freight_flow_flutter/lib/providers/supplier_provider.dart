import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/supplier.dart';

// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Supplier notifier for managing supplier state
class SupplierNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  SupplierNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadSuppliers();
  }

  final ApiService _apiService;

  Future<void> loadSuppliers() async {
    try {
      state = const AsyncValue.loading();
      final suppliers = await _apiService.getSuppliers();
      state = AsyncValue.data(suppliers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSupplier(Supplier supplier) async {
    try {
      await _apiService.createSupplier(supplier.toJson());
      await loadSuppliers(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _apiService.updateSupplier(supplier.id, supplier.toJson());
      await loadSuppliers(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _apiService.deleteSupplier(supplierId);
      await loadSuppliers(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }
}

// Provider for the supplier notifier
final supplierNotifierProvider = StateNotifierProvider<SupplierNotifier, AsyncValue<List<Supplier>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SupplierNotifier(apiService);
});

// Provider for all suppliers (using the notifier)
final suppliersProvider = Provider<AsyncValue<List<Supplier>>>((ref) {
  return ref.watch(supplierNotifierProvider);
});

// Provider for a single supplier by ID
final supplierProvider = FutureProvider.family<Supplier, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSupplierById(id);
});

// Provider for filtered suppliers
final filteredSuppliersProvider = Provider.family<List<Supplier>, Map<String, dynamic>>((ref, filters) {
  final suppliersAsyncValue = ref.watch(suppliersProvider);
  
  return suppliersAsyncValue.when(
    data: (suppliers) {
      return suppliers.where((supplier) {
        // Filter by search query (name, ID, city)
        if (filters['searchQuery'] != null && filters['searchQuery'].isNotEmpty) {
          final query = filters['searchQuery'].toLowerCase();
          if (!supplier.name.toLowerCase().contains(query) && 
              !supplier.id.toLowerCase().contains(query) && 
              !supplier.city.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // Filter by city
        if (filters['city'] != null && filters['city'].isNotEmpty) {
          if (supplier.city != filters['city']) {
            return false;
          }
        }
        
        // Filter by supplier ID
        if (filters['supplierId'] != null && filters['supplierId'].isNotEmpty) {
          if (supplier.id != filters['supplierId']) {
            return false;
          }
        }
        
        // Filter by GST number
        if (filters['gstNumber'] != null && filters['gstNumber'].isNotEmpty) {
          if (supplier.gstNumber != filters['gstNumber']) {
            return false;
          }
        }
        
        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
}); 