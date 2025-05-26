import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/providers/optimized_providers.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class OptimizedPaymentDashboard extends ConsumerStatefulWidget {
  const OptimizedPaymentDashboard({super.key});

  @override
  ConsumerState<OptimizedPaymentDashboard> createState() => _OptimizedPaymentDashboardState();
}

class _OptimizedPaymentDashboardState extends ConsumerState<OptimizedPaymentDashboard> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;
  
  // Real-time update listeners
  StreamSubscription? _tripUpdatesSubscription;
  StreamSubscription? _paymentUpdatesSubscription;
  StreamSubscription? _balanceChangesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Setup real-time listeners
    _setupRealTimeListeners();
    
    // Setup auto-refresh for critical data
    _setupAutoRefresh();
  }

  void _setupRealTimeListeners() {
    // Listen for trip updates
    _tripUpdatesSubscription = ref.read(tripUpdatesProvider.stream).listen((trip) {
      if (mounted) {
        _handleTripUpdate(trip);
      }
    });

    // Listen for payment updates
    _paymentUpdatesSubscription = ref.read(paymentUpdatesProvider.stream).listen((update) {
      if (mounted) {
        _handlePaymentUpdate(update);
      }
    });

    // Listen for balance amount changes
    _balanceChangesSubscription = ref.read(balanceChangeProvider.stream).listen((change) {
      if (mounted) {
        _handleBalanceChange(change);
      }
    });
  }

  void _setupAutoRefresh() {
    // Refresh critical payment data every 10 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isRefreshing) {
        _refreshPaymentData();
      }
    });
  }

  void _handleTripUpdate(Trip trip) {
    // Invalidate relevant caches and show notification
    invalidateTripsCaches();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip ${trip.orderNumber} updated'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  void _handlePaymentUpdate(Map<String, dynamic> update) {
    // Invalidate payment caches and show notification
    invalidatePaymentsCaches();
    
    final tripId = update['tripId'];
    final paymentType = update['paymentType'];
    final newStatus = update['newStatus'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$paymentType payment updated to $newStatus for trip $tripId'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  void _handleBalanceChange(Map<String, dynamic> change) {
    // Show notification for balance amount changes
    final tripId = change['tripId'];
    final oldAmount = change['oldAmount'];
    final newAmount = change['newAmount'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Balance amount changed from ₹$oldAmount to ₹$newAmount for trip $tripId'),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange.shade600,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to trip details
          },
        ),
      ),
    );
  }

  Future<void> _refreshPaymentData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Invalidate all payment-related caches
      invalidatePaymentsCaches();
      
      // Trigger refresh of current tab data
      switch (_selectedTabIndex) {
        case 0:
          ref.refresh(advancePaymentQueueProvider);
          break;
        case 1:
          ref.refresh(balancePaymentQueueProvider);
          break;
        case 2:
          // Payment history
          ref.refresh(optimizedTripsProvider(1));
          break;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    _tripUpdatesSubscription?.cancel();
    _paymentUpdatesSubscription?.cancel();
    _balanceChangesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Payments',
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdvancePaymentTab(),
                _buildBalancePaymentTab(),
                _buildPaymentHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Real-time payment processing & monitoring',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Refresh button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isRefreshing ? null : _refreshPaymentData,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.account_balance_wallet_rounded),
            text: 'Advance Payments',
          ),
          Tab(
            icon: Icon(Icons.receipt_long_rounded),
            text: 'Balance Payments',
          ),
          Tab(
            icon: Icon(Icons.history_rounded),
            text: 'Payment History',
          ),
        ],
        labelColor: Colors.blue.shade600,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildAdvancePaymentTab() {
    final advanceQueueAsync = ref.watch(advancePaymentQueueProvider);
    
    return advanceQueueAsync.when(
      data: (trips) => _buildPaymentQueue(
        trips: trips,
        title: 'Advance Payment Queue',
        paymentType: 'advance',
        emptyMessage: 'No trips waiting for advance payment',
      ),
      loading: () => _buildLoadingWidget(),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildBalancePaymentTab() {
    final balanceQueueAsync = ref.watch(balancePaymentQueueProvider);
    
    return balanceQueueAsync.when(
      data: (trips) => _buildPaymentQueue(
        trips: trips,
        title: 'Balance Payment Queue',
        paymentType: 'balance',
        emptyMessage: 'No trips waiting for balance payment',
      ),
      loading: () => _buildLoadingWidget(),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildPaymentHistoryTab() {
    final tripsAsync = ref.watch(optimizedTripsProvider(1));
    
    return tripsAsync.when(
      data: (paginatedData) {
        final completedTrips = paginatedData.items
            .where((trip) => 
                trip.advancePaymentStatus == 'Paid' || 
                trip.balancePaymentStatus == 'Paid')
            .toList();
        
        return _buildPaymentHistory(completedTrips);
      },
      loading: () => _buildLoadingWidget(),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildPaymentQueue({
    required List<Trip> trips,
    required String title,
    required String paymentType,
    required String emptyMessage,
  }) {
    if (trips.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _refreshPaymentData,
      child: Column(
        children: [
          // Queue summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.queue_rounded, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$title (${trips.length} trips)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Total Amount: ₹${_calculateTotalAmount(trips, paymentType).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Trip list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(trip, paymentType);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip, String paymentType) {
    final amount = paymentType == 'advance' 
        ? trip.advanceSupplierFreight ?? 0.0
        : trip.balanceSupplierFreight ?? 0.0;
    
    final status = paymentType == 'advance' 
        ? trip.advancePaymentStatus
        : trip.balancePaymentStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${trip.clientName} → ${trip.supplierName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(
                    status ?? 'Not Started',
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Amount: ₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                
                // Quick action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status != 'Paid') ...[
                      _buildQuickActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: _getNextActionLabel(status),
                        onPressed: () => _processPayment(trip.id, paymentType),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    _buildQuickActionButton(
                      icon: Icons.visibility_rounded,
                      label: 'View',
                      onPressed: () => _viewTripDetails(trip.id),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(List<Trip> trips) {
    if (trips.isEmpty) {
      return _buildEmptyState('No payment history available');
    }

    return RefreshIndicator(
      onRefresh: _refreshPaymentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildHistoryCard(trip);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                _buildPaymentStatusChip('Advance', trip.advancePaymentStatus),
                const SizedBox(width: 8),
                _buildPaymentStatusChip('Balance', trip.balancePaymentStatus),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Total: ₹${((trip.advanceSupplierFreight ?? 0) + (trip.balanceSupplierFreight ?? 0)).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String type, String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        '$type: ${status ?? 'Not Started'}',
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading payment data...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshPaymentData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateTotalAmount(List<Trip> trips, String paymentType) {
    return trips.fold(0.0, (sum, trip) {
      final amount = paymentType == 'advance' 
          ? trip.advanceSupplierFreight ?? 0.0
          : trip.balanceSupplierFreight ?? 0.0;
      return sum + amount;
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Initiated':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getNextActionLabel(String? status) {
    switch (status) {
      case 'Not Started':
        return 'Initiate';
      case 'Initiated':
        return 'Mark Pending';
      case 'Pending':
        return 'Mark Paid';
      default:
        return 'Update';
    }
  }

  Future<void> _processPayment(String tripId, String paymentType) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing payment...'),
            ],
          ),
        ),
      );

      // Use the fast payment update provider
      String? newStatus;
      if (paymentType == 'advance') {
        newStatus = 'Initiated'; // You can determine the next status based on current status
      } else {
        newStatus = 'Initiated';
      }

      await ref.read(fastPaymentUpdateProvider(
        (
          tripId: tripId,
          advanceStatus: paymentType == 'advance' ? newStatus : null,
          balanceStatus: paymentType == 'balance' ? newStatus : null,
          utrNumber: null,
          paymentMethod: null,
        )
      ).future);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Refresh the data
        _refreshPaymentData();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment status updated successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment status: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _viewTripDetails(String tripId) {
    // Navigate to trip details screen
    // This would typically use go_router or Navigator
    print('Navigate to trip details: $tripId');
  }
} 