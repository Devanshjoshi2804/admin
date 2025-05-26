import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:intl/intl.dart';
import 'package:freight_flow_flutter/widgets/ui/status_badge.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/models/trip.dart';

// Create a provider for filtered trips
final filteredTripsProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'status': 'All',
    'dateRange': null,
    'clientId': null,
    'vehicleType': null,
    'searchQuery': '',
  };
});

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListProvider);
    final filters = ref.watch(filteredTripsProvider);
    
    return TopNavbarLayout(
      title: 'FTL Trips',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.go('/'),
                  child: Text(
                    'Home',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                Text(
                  ' / FTL Trips',
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Page title and action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FTL Trips',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/booking'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Actions Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search trips...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (value) {
                      ref.read(filteredTripsProvider.notifier).update((state) => {
                        ...state,
                        'searchQuery': value,
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Filter button
                OutlinedButton.icon(
                  onPressed: () => _showFilterDialog(context, ref),
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
                const SizedBox(width: 12),
                
                // Export button
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ],
            ),
          ),
          
          // Status filter tabs
          _buildStatusTabs(context, ref, filters),
          
          // Trips list
          Expanded(
            child: tripsAsync.when(
              data: (trips) {
                // Apply filters
                final filteredTrips = _filterTrips(trips, filters);
                
                if (filteredTrips.isEmpty) {
                  return _buildEmptyState();
                }
                
                return _buildTripsList(context, filteredTrips);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error loading trips: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusTabs(BuildContext context, WidgetRef ref, Map<String, dynamic> filters) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatusTab(context, ref, 'All', filters),
          _buildStatusTab(context, ref, 'Booked', filters),
          _buildStatusTab(context, ref, 'In Transit', filters),
          _buildStatusTab(context, ref, 'Delivered', filters),
          _buildStatusTab(context, ref, 'Completed', filters),
        ],
      ),
    );
  }
  
  Widget _buildStatusTab(BuildContext context, WidgetRef ref, String status, Map<String, dynamic> filters) {
    final isActive = filters['status'] == status;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          ref.read(filteredTripsProvider.notifier).update((state) => {
            ...state,
            'status': status,
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.transparent,
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            status,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No trips found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create a new trip',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTripsList(BuildContext context, List<Trip> trips) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _buildTripCard(context, trip);
      },
    );
  }
  
  Widget _buildTripCard(BuildContext context, Trip trip) {
    final pickupDate = trip.pickupDate != null 
        ? DateFormat('dd MMM yyyy').format(trip.pickupDate!) 
        : 'N/A';
    
    final margin = (trip.clientFreight ?? 0) - (trip.supplierFreight ?? 0);
    final marginPercentage = trip.clientFreight != null && trip.clientFreight! > 0
        ? (margin / trip.clientFreight! * 100).toStringAsFixed(1)
        : '0.0';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order number, status, and date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.orderNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: trip.status),
                ],
              ),
              
              // LR Number
              if (trip.lrNumbers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'LR: ${trip.lrNumbers.join(", ")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              
              const Divider(height: 24),
              
              // Trip details
              Row(
                children: [
                  // Route and date
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.clientCity ?? trip.source} → ${trip.destinationCity ?? trip.destination}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '$pickupDate ${trip.pickupTime ?? ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Client and supplier
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trip.clientName ?? 'N/A',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trip.vehicleNumber ?? 'N/A',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Freight and margin
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##,###').format(trip.clientFreight ?? 0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$marginPercentage% margin',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Payment status
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Advance Payment',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: trip.advancePaymentStatus ?? 'Not Started'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balance Payment',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: trip.balancePaymentStatus ?? 'Not Started'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => context.go('/trips/${trip.id}'),
                          tooltip: 'View Details',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {},
                          tooltip: 'Edit Trip',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Trip> _filterTrips(List<Trip> trips, Map<String, dynamic> filters) {
    return trips.where((trip) {
      // Filter by status
      if (filters['status'] != 'All' && trip.status != filters['status']) {
        return false;
      }
      
      // Filter by search query
      if (filters['searchQuery'].isNotEmpty) {
        final query = filters['searchQuery'].toLowerCase();
        final orderNumber = trip.orderNumber.toLowerCase();
        final clientName = (trip.clientName ?? '').toLowerCase();
        final vehicleNumber = (trip.vehicleNumber ?? '').toLowerCase();
        final lrNumbers = trip.lrNumbers.join(' ').toLowerCase();
        
        if (!orderNumber.contains(query) && 
            !clientName.contains(query) && 
            !vehicleNumber.contains(query) &&
            !lrNumbers.contains(query)) {
          return false;
        }
      }
      
      // Filter by client ID
      if (filters['clientId'] != null && trip.clientId != filters['clientId']) {
        return false;
      }
      
      // Filter by vehicle type
      if (filters['vehicleType'] != null && trip.vehicleType != filters['vehicleType']) {
        return false;
      }
      
      // Filter by date range
      if (filters['dateRange'] != null && trip.pickupDate != null) {
        final dateRange = filters['dateRange'] as DateTimeRange;
        final pickupDate = trip.pickupDate!;
        
        if (pickupDate.isBefore(dateRange.start) || pickupDate.isAfter(dateRange.end)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trips'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter options would go here
              Text('Filter options coming soon'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filters
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
} 