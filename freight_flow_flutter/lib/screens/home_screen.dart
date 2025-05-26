import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/widgets/ui/dashboard_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListProvider);
    
    return TopNavbarLayout(
      title: 'Dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            const Row(
              children: [
                Text('Home', style: TextStyle(color: Colors.grey)),
                Text(' / Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Dashboard header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.refresh(tripListProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Dashboard tabs
            DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Trip Analytics'),
                      Tab(text: 'Financial'),
                      Tab(text: 'Performance'),
                    ],
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats cards
                  tripsAsync.when(
                    data: (trips) {
                      final tripsInTransit = trips.where((t) => t.status == 'In Transit').length;
                      final pendingPayments = trips.where((t) => 
                        t.balancePaymentStatus != 'Paid' || t.advancePaymentStatus != 'Paid'
                      ).length;
                      final podPending = trips.where((t) => !t.podUploaded).length;
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DashboardCard(
                                  title: 'Total Trips',
                                  count: trips.length,
                                  subtitle: 'Trips created in system',
                                  iconData: Icons.directions_bus,
                                  iconColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardCard(
                                  title: 'In Transit',
                                  count: tripsInTransit,
                                  subtitle: 'Trips currently in transit',
                                  iconData: Icons.local_shipping,
                                  iconColor: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardCard(
                                  title: 'Pending Payments',
                                  count: pendingPayments,
                                  subtitle: 'Payments waiting for processing',
                                  iconData: Icons.payments,
                                  iconColor: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardCard(
                                  title: 'POD Pending',
                                  count: podPending,
                                  subtitle: 'Trips waiting for POD upload',
                                  iconData: Icons.description,
                                  iconColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Status Summary Cards
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trip Status Summary
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Trip Status Summary',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'Overview of current trip statuses',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Status list
                                        _buildStatusRow(
                                          'Booked', 
                                          trips.where((t) => t.status == 'Booked').length, 
                                          Colors.blue
                                        ),
                                        _buildStatusRow(
                                          'In Transit', 
                                          trips.where((t) => t.status == 'In Transit').length, 
                                          Colors.orange
                                        ),
                                        _buildStatusRow(
                                          'Completed', 
                                          trips.where((t) => t.status == 'Completed').length, 
                                          Colors.green
                                        ),
                                        _buildStatusRow(
                                          'Issues Reported', 
                                          0, 
                                          Colors.red
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Trip completion progress
                                        const Text(
                                          'TRIP COMPLETION',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: trips.isEmpty ? 0 : 
                                            trips.where((t) => t.status == 'Completed').length / trips.length,
                                          backgroundColor: Colors.grey.shade200,
                                          color: Colors.blue,
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${trips.isEmpty ? 0 : (trips.where((t) => t.status == 'Completed').length * 100 ~/ trips.length)}%',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 24),
                              
                              // Payment Status
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Payment Status',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'Summary of payment statuses',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Payment status list
                                        _buildStatusRow(
                                          'Advance Payments (Pending)', 
                                          trips.where((t) => t.advancePaymentStatus == 'Pending').length, 
                                          Colors.blue
                                        ),
                                        _buildStatusRow(
                                          'Balance Payments (Pending)', 
                                          trips.where((t) => t.balancePaymentStatus == 'Pending').length, 
                                          Colors.red
                                        ),
                                        _buildStatusRow(
                                          'Payments Completed', 
                                          trips.where((t) => 
                                            t.advancePaymentStatus == 'Paid' && 
                                            t.balancePaymentStatus == 'Paid'
                                          ).length, 
                                          Colors.green
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Revenue and margin cards
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'TOTAL REVENUE',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '₹${_calculateTotalRevenue(trips)}',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'TOTAL MARGIN',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '₹${_calculateTotalMargin(trips)}',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green.shade700,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_calculateMarginPercentage(trips)}% of revenue',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Summary Cards (Clients, Suppliers, Vehicles)
                          Row(
                            children: [
                              // Clients Card
                              Expanded(
                                child: _buildEntityCard(
                                  'Clients',
                                  1,
                                  'Onboarded clients',
                                  'View All Clients',
                                  '/clients',
                                  Icons.business,
                                  Colors.blue,
                                  context,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Suppliers Card
                              Expanded(
                                child: _buildEntityCard(
                                  'Suppliers',
                                  1,
                                  'Registered suppliers',
                                  'View All Suppliers',
                                  '/suppliers',
                                  Icons.local_shipping,
                                  Colors.purple,
                                  context,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Vehicles Card
                              Expanded(
                                child: _buildEntityCard(
                                  'Vehicles',
                                  trips.where((t) => t.vehicleId.isNotEmpty).length,
                                  'Registered vehicles',
                                  'View All Vehicles',
                                  '/vehicles',
                                  Icons.directions_bus,
                                  Colors.cyan,
                                  context,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEntityCard(
    String title,
    int count,
    String subtitle,
    String linkText,
    String route,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go(route),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: Text(linkText),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                foregroundColor: color,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Calculate metrics
  String _calculateTotalRevenue(List<dynamic> trips) {
    double total = 0;
    for (var trip in trips) {
      total += trip.clientFreight;
    }
    return _formatCurrency(total);
  }
  
  String _calculateTotalMargin(List<dynamic> trips) {
    double totalRevenue = 0;
    double totalCost = 0;
    for (var trip in trips) {
      totalRevenue += trip.clientFreight;
      totalCost += trip.supplierFreight;
    }
    return _formatCurrency(totalRevenue - totalCost);
  }
  
  String _calculateMarginPercentage(List<dynamic> trips) {
    double totalRevenue = 0;
    double totalCost = 0;
    for (var trip in trips) {
      totalRevenue += trip.clientFreight;
      totalCost += trip.supplierFreight;
    }
    if (totalRevenue == 0) return '0.0';
    return ((totalRevenue - totalCost) / totalRevenue * 100).toStringAsFixed(1);
  }
  
  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
} 