import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/ultra_fast_service_provider.dart';
import 'package:freight_flow_flutter/widgets/ultra_fast_payment_widget.dart';

class UltraFastDashboardScreen extends ConsumerStatefulWidget {
  const UltraFastDashboardScreen({super.key});

  @override
  ConsumerState<UltraFastDashboardScreen> createState() => _UltraFastDashboardScreenState();
}

class _UltraFastDashboardScreenState extends ConsumerState<UltraFastDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;
  int _lastRefreshTime = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Clear cache and refresh all data
      final clearCache = ref.read(cacheClearProvider);
      clearCache();

      // Wait for all providers to refresh
      await Future.wait([
        ref.refresh(ultraFastDashboardProvider.future),
        ref.refresh(ultraFastTripsProvider((
          page: 1,
          limit: 20,
          status: null,
          clientId: null,
        )).future),
        ref.refresh(ultraFastAdvanceQueueProvider.future),
        ref.refresh(ultraFastBalanceQueueProvider.future),
      ]);

      stopwatch.stop();
      setState(() {
        _lastRefreshTime = stopwatch.elapsedMilliseconds;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 8),
                Text('⚡ Dashboard refreshed in ${_lastRefreshTime}ms'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚡ Ultra-Fast Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Trips'),
            Tab(icon: Icon(Icons.payment), text: 'Advance'),
            Tab(icon: Icon(Icons.account_balance), text: 'Balance'),
          ],
        ),
        actions: [
          // Performance indicator
          if (_lastRefreshTime > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_lastRefreshTime}ms',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Refresh button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTripsTab(),
          _buildAdvancePaymentsTab(),
          _buildBalancePaymentsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final dashboardAsync = ref.watch(ultraFastDashboardProvider);
        final connectionStatus = ref.watch(connectionStatusProvider);
        final cacheSize = ref.watch(cacheStatusProvider);
        final performanceMetrics = ref.watch(performanceMetricsProvider);

        return dashboardAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading dashboard at ultra-fast speed...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading dashboard: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(ultraFastDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (dashboardData) {
            final stats = dashboardData['stats'] as Map<String, dynamic>? ?? {};
            final recentTrips = (dashboardData['recentTrips'] as List?)
                ?.map((data) => Trip.fromJson(data))
                .toList() ?? [];

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System status card
                    _buildSystemStatusCard(connectionStatus, cacheSize, performanceMetrics),
                    
                    const SizedBox(height: 16),
                    
                    // Stats grid
                    _buildStatsGrid(stats),
                    
                    const SizedBox(height: 16),
                    
                    // Recent trips
                    _buildRecentTripsSection(recentTrips),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSystemStatusCard(bool isConnected, int cacheSize, Map<String, double> metrics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(width: 8),
                const Text(
                  'System Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Connection',
                    isConnected ? 'Online' : 'Offline',
                    isConnected ? Colors.green : Colors.red,
                    isConnected ? Icons.wifi : Icons.wifi_off,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Cache',
                    '$cacheSize items',
                    Colors.blue,
                    Icons.storage,
                  ),
                ),
              ],
            ),
            
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Average Response Times:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: metrics.entries.map((entry) {
                  final avgTime = entry.value.round();
                  final color = avgTime < 500 ? Colors.green : 
                               avgTime < 1000 ? Colors.orange : Colors.red;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      '${entry.key}: ${avgTime}ms',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final statItems = [
      _StatItem('Total Trips', stats['totalTrips'] ?? 0, Icons.local_shipping, Colors.blue),
      _StatItem('Booked', stats['bookedTrips'] ?? 0, Icons.book, Colors.purple),
      _StatItem('In Transit', stats['inTransitTrips'] ?? 0, Icons.directions_car, Colors.orange),
      _StatItem('Completed', stats['completedTrips'] ?? 0, Icons.check_circle, Colors.green),
      _StatItem('Pending Advance', stats['pendingAdvancePayments'] ?? 0, Icons.payment, Colors.red),
      _StatItem('Pending Balance', stats['pendingBalancePayments'] ?? 0, Icons.account_balance, Colors.amber),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final item = statItems[index];
        return _buildStatCard(item);
      },
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 32,
              color: item.color,
            ),
            const SizedBox(height: 8),
            Text(
              '${item.value}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTripsSection(List<Trip> recentTrips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Trips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (recentTrips.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No recent trips found'),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTrips.length,
            itemBuilder: (context, index) {
              final trip = recentTrips[index];
              return _buildTripCard(trip);
            },
          ),
      ],
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.orderNumber ?? 'Unknown Order',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(trip.status)),
                  ),
                  child: Text(
                    trip.status ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(trip.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: UltraFastPaymentRow(
                    trip: trip,
                    paymentType: 'advance',
                    onPaymentUpdated: () {
                      ref.refresh(ultraFastDashboardProvider);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: UltraFastPaymentRow(
                    trip: trip,
                    paymentType: 'balance',
                    onPaymentUpdated: () {
                      ref.refresh(ultraFastDashboardProvider);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final tripsAsync = ref.watch(ultraFastTripsProvider((
          page: 1,
          limit: 50,
          status: null,
          clientId: null,
        )));

        return tripsAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading trips at ultra-fast speed...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading trips: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(ultraFastTripsProvider((
                    page: 1,
                    limit: 50,
                    status: null,
                    clientId: null,
                  ))),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (trips) => RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildDetailedTripCard(trip);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancePaymentsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final queueAsync = ref.watch(ultraFastAdvanceQueueProvider);

        return queueAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading advance payment queue...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading advance payments: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(ultraFastAdvanceQueueProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (trips) => RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return UltraFastPaymentWidget(
                  trip: trip,
                  paymentType: 'advance',
                  onPaymentUpdated: () {
                    ref.refresh(ultraFastAdvanceQueueProvider);
                    ref.refresh(ultraFastDashboardProvider);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalancePaymentsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final queueAsync = ref.watch(ultraFastBalanceQueueProvider);

        return queueAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading balance payment queue...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading balance payments: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(ultraFastBalanceQueueProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (trips) => RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return UltraFastPaymentWidget(
                  trip: trip,
                  paymentType: 'balance',
                  onPaymentUpdated: () {
                    ref.refresh(ultraFastBalanceQueueProvider);
                    ref.refresh(ultraFastDashboardProvider);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedTripCard(Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(trip.status)),
                  ),
                  child: Text(
                    trip.status ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(trip.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: UltraFastPaymentWidget(
                    trip: trip,
                    paymentType: 'advance',
                    onPaymentUpdated: () {
                      ref.refresh(ultraFastTripsProvider((
                        page: 1,
                        limit: 50,
                        status: null,
                        clientId: null,
                      )));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: UltraFastPaymentWidget(
                    trip: trip,
                    paymentType: 'balance',
                    onPaymentUpdated: () {
                      ref.refresh(ultraFastTripsProvider((
                        page: 1,
                        limit: 50,
                        status: null,
                        clientId: null,
                      )));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in transit':
        return Colors.blue;
      case 'delivered':
        return Colors.orange;
      case 'booked':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
} 