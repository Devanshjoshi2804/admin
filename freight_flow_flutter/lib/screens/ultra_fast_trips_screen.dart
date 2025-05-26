import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/ultra_fast_service_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UltraFastTripsScreen extends ConsumerStatefulWidget {
  const UltraFastTripsScreen({super.key});

  @override
  ConsumerState<UltraFastTripsScreen> createState() => _UltraFastTripsScreenState();
}

class _UltraFastTripsScreenState extends ConsumerState<UltraFastTripsScreen> {
  bool _isLoading = false;
  int _loadTime = 0;
  List<Trip> _trips = [];
  String _selectedFilter = 'All';

  final List<String> _statusFilters = [
    'All', 'Booked', 'In Transit', 'Delivered', 'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _loadTripsUltraFast();
  }

  Future<void> _loadTripsUltraFast() async {
    setState(() {
      _isLoading = true;
      _loadTime = 0;
    });

    final stopwatch = Stopwatch()..start();
    
    try {
      // Try ultra-fast method using the provider
      try {
        final tripsAsync = ref.read(ultraFastTripsProvider((
          page: 1,
          limit: 50,
          status: _selectedFilter == 'All' ? null : _selectedFilter,
          clientId: null,
        )).future);
        
        final trips = await tripsAsync;
        
        setState(() {
          _trips = trips;
        });
        
        print("✅ Ultra-fast provider loaded ${trips.length} trips");
      } catch (providerError) {
        print("Provider method failed, trying direct API call: $providerError");
        
        // Fallback to direct API call
        try {
          final response = await http.get(
            Uri.parse('http://localhost:3000/api/trips/ultra-fast?limit=50'),
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
                  final trip = Trip.fromJson(tripData);
                  trips.add(trip);
                } catch (e) {
                  print("Error processing trip: $e");
                  continue;
                }
              }
              
              setState(() {
                _trips = trips;
              });
              
              print("✅ Direct API call loaded ${trips.length} trips");
            } else {
              throw Exception('Invalid response format');
            }
          } else {
            throw Exception('API returned ${response.statusCode}');
          }
        } catch (directApiError) {
          print("Direct API call failed, using fallback: $directApiError");
          
          // Final fallback to existing optimized method
          final service = ref.read(ultraFastApiServiceProvider);
          final trips = await service.getTripsUltraFast(limit: 50);
          setState(() {
            _trips = trips;
          });
          
          print("✅ Fallback method loaded ${trips.length} trips");
        }
      }
    } catch (e) {
      print("Error loading trips: $e");
      // Show error in UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadTime = stopwatch.elapsedMilliseconds;
        });
      }
    }
  }

  List<Trip> get _filteredTrips {
    if (_selectedFilter == 'All') {
      return _trips;
    }
    return _trips.where((trip) => trip.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚡ Ultra-Fast Trips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTripsUltraFast,
          ),
        ],
      ),
      body: Column(
        children: [
          // Performance indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _loadTime > 0 
                ? (_loadTime < 1000 ? Colors.green.shade50 : Colors.orange.shade50)
                : Colors.grey.shade50,
            child: Row(
              children: [
                Icon(
                  _loadTime > 0 
                      ? (_loadTime < 1000 ? Icons.flash_on : Icons.speed)
                      : Icons.timer,
                  color: _loadTime > 0 
                      ? (_loadTime < 1000 ? Colors.green.shade600 : Colors.orange.shade600)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoading 
                            ? 'Loading trips...' 
                            : _loadTime > 0 
                                ? 'Loaded in ${_loadTime}ms'
                                : 'Ready to load',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _loadTime > 0 
                              ? (_loadTime < 1000 ? Colors.green.shade700 : Colors.orange.shade700)
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (_loadTime > 0)
                        Text(
                          _loadTime < 500 
                              ? '🚀 Ultra-fast performance!'
                              : _loadTime < 1000 
                                  ? '⚡ Fast performance'
                                  : '📊 Standard performance',
                          style: TextStyle(
                            fontSize: 12,
                            color: _loadTime < 1000 ? Colors.green.shade600 : Colors.orange.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Status filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((status) {
                  final isSelected = _selectedFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = status;
                        });
                        // Reload trips with new filter
                        _loadTripsUltraFast();
                      },
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: Colors.deepPurple.shade600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Trips list
          Expanded(
            child: _buildTripsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadTripsUltraFast,
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.flash_on),
        label: const Text('Ultra-Fast Load'),
      ),
    );
  }

  Widget _buildTripsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading trips at ultra-fast speed...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    final filteredTrips = _filteredTrips;

    if (filteredTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No trips found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All' 
                  ? 'No trips in the system'
                  : 'No trips with status: $_selectedFilter',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = filteredTrips[index];
        return _buildTripCard(trip);
      },
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.orderNumber ?? 'Unknown Order',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(trip.status ?? 'Unknown'),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Trip details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.business,
                        'Client',
                        trip.clientName ?? 'Unknown Client',
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        Icons.local_shipping,
                        'Vehicle',
                        trip.vehicleNumber ?? 'Unknown Vehicle',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.location_on,
                        'Route',
                        '${trip.source ?? 'Unknown'} → ${trip.destination ?? 'Unknown'}',
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        Icons.currency_rupee,
                        'Freight',
                        '₹${(trip.clientFreight ?? 0).toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment status row
            Row(
              children: [
                Expanded(
                  child: _buildPaymentStatus(
                    'Advance',
                    trip.advancePaymentStatus ?? 'Not Started',
                    trip.advanceSupplierFreight ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentStatus(
                    'Balance',
                    trip.balancePaymentStatus ?? 'Not Started',
                    trip.balanceSupplierFreight ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'in transit':
        color = Colors.blue;
        break;
      case 'delivered':
        color = Colors.orange;
        break;
      case 'booked':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatus(String type, String status, double amount) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'initiated':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 