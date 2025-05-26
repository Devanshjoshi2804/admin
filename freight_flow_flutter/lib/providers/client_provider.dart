import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/client.dart';

// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Client notifier for managing client state
class ClientNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  ClientNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadClients();
  }

  final ApiService _apiService;

  Future<void> loadClients() async {
    try {
      state = const AsyncValue.loading();
      final clients = await _apiService.getClients();
      state = AsyncValue.data(clients);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createClient(Client client) async {
    try {
      await _apiService.createClient(client.toJson());
      await loadClients(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _apiService.updateClient(client.id, client.toJson());
      await loadClients(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _apiService.deleteClient(clientId);
      await loadClients(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }
}

// Provider for the client notifier
final clientNotifierProvider = StateNotifierProvider<ClientNotifier, AsyncValue<List<Client>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ClientNotifier(apiService);
});

// Provider for all clients (using the notifier)
final clientsProvider = Provider<AsyncValue<List<Client>>>((ref) {
  return ref.watch(clientNotifierProvider);
});

// Provider for a single client by ID
final clientProvider = FutureProvider.family<Client, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getClientById(id);
});

// Provider for filtered clients
final filteredClientsProvider = Provider.family<List<Client>, Map<String, dynamic>>((ref, filters) {
  final clientsAsyncValue = ref.watch(clientsProvider);
  
  return clientsAsyncValue.when(
    data: (clients) {
      return clients.where((client) {
        // Filter by search query (name, ID, city)
        if (filters['searchQuery'] != null && filters['searchQuery'].isNotEmpty) {
          final query = filters['searchQuery'].toLowerCase();
          if (!client.name.toLowerCase().contains(query) && 
              !client.id.toLowerCase().contains(query) && 
              !client.city.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // Filter by city
        if (filters['city'] != null && filters['city'].isNotEmpty) {
          if (client.city != filters['city']) {
            return false;
          }
        }
        
        // Filter by client ID
        if (filters['clientId'] != null && filters['clientId'].isNotEmpty) {
          if (client.id != filters['clientId']) {
            return false;
          }
        }
        
        // Filter by address type
        if (filters['addressType'] != null && filters['addressType'].isNotEmpty) {
          if (client.addressType != filters['addressType']) {
            return false;
          }
        }
        
        // Filter by invoicing type
        if (filters['invoicingType'] != null && filters['invoicingType'].isNotEmpty) {
          if (client.invoicingType != filters['invoicingType']) {
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