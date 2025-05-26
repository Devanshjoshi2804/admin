import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

// Cache configuration
const Duration _cacheTimeout = Duration(minutes: 5);
const int _pageSize = 50;

// Cached data models
class CachedData<T> {
  final List<T> data;
  final DateTime cachedAt;
  final bool isStale;

  CachedData({
    required this.data,
    required this.cachedAt,
    bool? isStale,
  }) : isStale = isStale ?? DateTime.now().difference(cachedAt) > _cacheTimeout;

  bool get isValid => !isStale && DateTime.now().difference(cachedAt) < _cacheTimeout;
}

class PaginatedData<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedData({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}

// Real-time data notifier for WebSocket updates
class RealTimeDataNotifier extends StateNotifier<Map<String, dynamic>> {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  StreamSubscription? _subscription;
  
  RealTimeDataNotifier() : super({}) {
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      // Connect to WebSocket for real-time updates
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:3001/ws'), // Adjust URL as needed
      );
      
      _subscription = _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          _handleWebSocketMessage(decoded);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final data = message['data'];

    switch (type) {
      case 'TRIP_UPDATED':
        _notifyTripUpdate(data);
        break;
      case 'PAYMENT_STATUS_CHANGED':
        _notifyPaymentUpdate(data);
        break;
      case 'NEW_TRIP_CREATED':
        _notifyNewTrip(data);
        break;
      case 'BALANCE_AMOUNT_CHANGED':
        _notifyBalanceChange(data);
        break;
    }
  }

  void _notifyTripUpdate(Map<String, dynamic> tripData) {
    state = {...state, 'tripUpdate': tripData, 'timestamp': DateTime.now()};
  }

  void _notifyPaymentUpdate(Map<String, dynamic> paymentData) {
    state = {...state, 'paymentUpdate': paymentData, 'timestamp': DateTime.now()};
  }

  void _notifyNewTrip(Map<String, dynamic> tripData) {
    state = {...state, 'newTrip': tripData, 'timestamp': DateTime.now()};
  }

  void _notifyBalanceChange(Map<String, dynamic> balanceData) {
    state = {...state, 'balanceChange': balanceData, 'timestamp': DateTime.now()};
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}

// Optimized cache manager
class CacheManager {
  static final Map<String, CachedData> _cache = {};
  static Timer? _cleanupTimer;

  static void _startCleanupTimer() {
    _cleanupTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanup();
    });
  }

  static void _cleanup() {
    final keysToRemove = <String>[];
    for (final entry in _cache.entries) {
      if (!entry.value.isValid) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  static void set<T>(String key, List<T> data) {
    _startCleanupTimer();
    _cache[key] = CachedData(data: data, cachedAt: DateTime.now());
  }

  static CachedData<T>? get<T>(String key) {
    final cached = _cache[key];
    if (cached != null && cached.isValid) {
      return CachedData<T>(
        data: List<T>.from(cached.data),
        cachedAt: cached.cachedAt,
      );
    }
    return null;
  }

  static void invalidate(String key) {
    _cache.remove(key);
  }

  static void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
}

// Providers
final realTimeDataProvider = StateNotifierProvider<RealTimeDataNotifier, Map<String, dynamic>>((ref) {
  return RealTimeDataNotifier();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Optimized trips provider with caching and pagination
final optimizedTripsProvider = FutureProvider.family<PaginatedData<Trip>, int>((ref, page) async {
  final apiService = ref.watch(apiServiceProvider);
  final cacheKey = 'trips_page_$page';
  
  // Check cache first
  final cached = CacheManager.get<Trip>(cacheKey);
  if (cached != null) {
    return PaginatedData<Trip>(
      items: cached.data,
      currentPage: page,
      totalPages: (cached.data.length / _pageSize).ceil(),
      totalItems: cached.data.length,
      hasNextPage: page < (cached.data.length / _pageSize).ceil(),
      hasPreviousPage: page > 1,
    );
  }

  try {
    // Fetch only the page we need
    final allTrips = await apiService.getTrips();
    
    // Store in cache
    CacheManager.set(cacheKey, allTrips);
    
    // Paginate
    final startIndex = (page - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, allTrips.length);
    final pageItems = allTrips.sublist(startIndex, endIndex);
    
    return PaginatedData<Trip>(
      items: pageItems,
      currentPage: page,
      totalPages: (allTrips.length / _pageSize).ceil(),
      totalItems: allTrips.length,
      hasNextPage: endIndex < allTrips.length,
      hasPreviousPage: page > 1,
    );
  } catch (e) {
    debugPrint("Error in optimizedTripsProvider: $e");
    return PaginatedData<Trip>(
      items: [],
      currentPage: page,
      totalPages: 0,
      totalItems: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
});

// Fast balance payment queue provider
final balancePaymentQueueProvider = FutureProvider<List<Trip>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  const cacheKey = 'balance_queue';
  
  // Check cache first
  final cached = CacheManager.get<Trip>(cacheKey);
  if (cached != null) {
    return cached.data;
  }

  try {
    // Use direct API call for balance queue
    final response = await apiService.getBalancePaymentQueue();
    
    // Cache the result
    CacheManager.set(cacheKey, response);
    
    return response;
  } catch (e) {
    debugPrint("Error in balancePaymentQueueProvider: $e");
    return [];
  }
});

// Fast advance payment queue provider
final advancePaymentQueueProvider = FutureProvider<List<Trip>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  const cacheKey = 'advance_queue';
  
  // Check cache first
  final cached = CacheManager.get<Trip>(cacheKey);
  if (cached != null) {
    return cached.data;
  }

  try {
    // Use direct API call for advance queue
    final response = await apiService.getAdvancePaymentQueue();
    
    // Cache the result
    CacheManager.set(cacheKey, response);
    
    return response;
  } catch (e) {
    debugPrint("Error in advancePaymentQueueProvider: $e");
    return [];
  }
});

// Optimized clients provider with caching
final optimizedClientsProvider = FutureProvider<List<Client>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  const cacheKey = 'clients';
  
  // Check cache first
  final cached = CacheManager.get<Client>(cacheKey);
  if (cached != null) {
    return cached.data;
  }

  try {
    final clients = await apiService.getClientsOptimized();
    
    // Cache the result
    CacheManager.set(cacheKey, clients);
    
    return clients;
  } catch (e) {
    debugPrint("Error in optimizedClientsProvider: $e");
    return [];
  }
});

// Optimized suppliers provider with caching
final optimizedSuppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  const cacheKey = 'suppliers';
  
  // Check cache first
  final cached = CacheManager.get<Supplier>(cacheKey);
  if (cached != null) {
    return cached.data;
  }

  try {
    final suppliers = await apiService.getSuppliersOptimized();
    
    // Cache the result
    CacheManager.set(cacheKey, suppliers);
    
    return suppliers;
  } catch (e) {
    debugPrint("Error in optimizedSuppliersProvider: $e");
    return [];
  }
});

// Optimized vehicles provider with caching
final optimizedVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  const cacheKey = 'vehicles';
  
  // Check cache first
  final cached = CacheManager.get<Vehicle>(cacheKey);
  if (cached != null) {
    return cached.data;
  }

  try {
    final vehicles = await apiService.getVehiclesOptimized();
    
    // Cache the result
    CacheManager.set(cacheKey, vehicles);
    
    return vehicles;
  } catch (e) {
    debugPrint("Error in optimizedVehiclesProvider: $e");
    return [];
  }
});

// Ultra-fast payment status update provider
final fastPaymentUpdateProvider = FutureProvider.family<Trip, ({
  String tripId,
  String? advanceStatus,
  String? balanceStatus,
  String? utrNumber,
  String? paymentMethod,
})>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  
  try {
    // Use the fast update method
    final updatedTrip = await apiService.updatePaymentStatusFast(
      params.tripId,
      {
        'advancePaymentStatus': params.advanceStatus,
        'balancePaymentStatus': params.balanceStatus,
        'utrNumber': params.utrNumber,
        'paymentMethod': params.paymentMethod,
      },
    );
    
    // Invalidate cache for affected data
    CacheManager.invalidatePattern('trips');
    CacheManager.invalidatePattern('queue');
    
    return updatedTrip;
  } catch (e) {
    debugPrint("Error in fastPaymentUpdateProvider: $e");
    rethrow;
  }
});

// Real-time trip updates listener
final tripUpdatesProvider = StreamProvider<Trip>((ref) {
  final realTimeData = ref.watch(realTimeDataProvider);
  
  return Stream.periodic(const Duration(milliseconds: 500), (count) {
    // Check for trip updates from WebSocket
    if (realTimeData.containsKey('tripUpdate')) {
      final tripData = realTimeData['tripUpdate'];
      try {
        return Trip.fromJson(tripData);
      } catch (e) {
        debugPrint("Error parsing trip update: $e");
        return null;
      }
    }
    return null;
  }).where((trip) => trip != null).cast<Trip>();
});

// Real-time payment updates listener
final paymentUpdatesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final realTimeData = ref.watch(realTimeDataProvider);
  
  return Stream.periodic(const Duration(milliseconds: 500), (count) {
    // Check for payment updates from WebSocket
    if (realTimeData.containsKey('paymentUpdate')) {
      return realTimeData['paymentUpdate'] as Map<String, dynamic>;
    }
    return null;
  }).where((update) => update != null).cast<Map<String, dynamic>>();
});

// Balance amount change notifications
final balanceChangeProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final realTimeData = ref.watch(realTimeDataProvider);
  
  return Stream.periodic(const Duration(milliseconds: 500), (count) {
    // Check for balance changes from WebSocket
    if (realTimeData.containsKey('balanceChange')) {
      return realTimeData['balanceChange'] as Map<String, dynamic>;
    }
    return null;
  }).where((change) => change != null).cast<Map<String, dynamic>>();
});

// Cache invalidation utility
void invalidateAllCaches() {
  CacheManager._cache.clear();
}

void invalidateTripsCaches() {
  CacheManager.invalidatePattern('trips');
  CacheManager.invalidatePattern('queue');
}

void invalidatePaymentsCaches() {
  CacheManager.invalidatePattern('balance_queue');
  CacheManager.invalidatePattern('advance_queue');
} 