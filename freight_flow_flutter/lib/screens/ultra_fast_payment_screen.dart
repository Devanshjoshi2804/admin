import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/ultra_fast_providers.dart';
import 'package:freight_flow_flutter/providers/optimized_providers.dart';
import 'package:freight_flow_flutter/widgets/ultra_fast_payment_widget.dart';

class UltraFastPaymentScreen extends ConsumerStatefulWidget {
  const UltraFastPaymentScreen({super.key});

  @override
  ConsumerState<UltraFastPaymentScreen> createState() => _UltraFastPaymentScreenState();
}

class _UltraFastPaymentScreenState extends ConsumerState<UltraFastPaymentScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _autoRefreshEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto-refresh every 10 seconds when enabled
    _startAutoRefresh();
  }
  
  void _startAutoRefresh() {
    if (_autoRefreshEnabled) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _autoRefreshEnabled) {
          _refreshData();
          _startAutoRefresh();
        }
      });
    }
  }
  
  void _refreshData() {
    // Invalidate caches to force refresh
    invalidatePaymentsCaches();
    ref.invalidate(advancePaymentQueueProvider);
    ref.invalidate(balancePaymentQueueProvider);
  }
  
  @override
  void dispose() {
    _autoRefreshEnabled = false;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚡ Ultra-Fast Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Auto-refresh toggle
          IconButton(
            icon: Icon(
              _autoRefreshEnabled ? Icons.autorenew : Icons.sync_disabled,
              color: _autoRefreshEnabled ? Colors.white : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _autoRefreshEnabled = !_autoRefreshEnabled;
              });
              if (_autoRefreshEnabled) {
                _startAutoRefresh();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _autoRefreshEnabled 
                        ? 'Auto-refresh enabled (10s)' 
                        : 'Auto-refresh disabled',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          // Manual refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.flash_on),
              text: 'Advance Queue',
            ),
            Tab(
              icon: Icon(Icons.payment),
              text: 'Balance Queue',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdvancePaymentQueue(),
          _buildBalancePaymentQueue(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBatchProcessingDialog,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.flash_on),
        label: const Text('Batch Process'),
      ),
    );
  }
  
  Widget _buildAdvancePaymentQueue() {
    final advanceQueueAsync = ref.watch(advancePaymentQueueProvider);
    
    return advanceQueueAsync.when(
      data: (trips) => _buildPaymentList(trips, 'advance'),
      loading: () => _buildLoadingWidget('Loading advance payments...'),
      error: (error, stack) => _buildErrorWidget('Error loading advance payments: $error'),
    );
  }
  
  Widget _buildBalancePaymentQueue() {
    final balanceQueueAsync = ref.watch(balancePaymentQueueProvider);
    
    return balanceQueueAsync.when(
      data: (trips) => _buildPaymentList(trips, 'balance'),
      loading: () => _buildLoadingWidget('Loading balance payments...'),
      error: (error, stack) => _buildErrorWidget('Error loading balance payments: $error'),
    );
  }
  
  Widget _buildPaymentList(List<Trip> trips, String paymentType) {
    if (trips.isEmpty) {
      return _buildEmptyState(
        paymentType == 'advance' 
            ? 'No advance payments pending' 
            : 'No balance payments pending',
      );
    }
    
    return Column(
      children: [
        // Header with stats
        Container(
          padding: const EdgeInsets.all(16),
          color: paymentType == 'advance' ? Colors.blue.shade50 : Colors.green.shade50,
          child: Row(
            children: [
              Icon(
                paymentType == 'advance' ? Icons.flash_on : Icons.payment,
                color: paymentType == 'advance' ? Colors.blue.shade600 : Colors.green.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trips.length} ${paymentType} payments pending',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: paymentType == 'advance' ? Colors.blue.shade800 : Colors.green.shade800,
                      ),
                    ),
                    Text(
                      'Total amount: ₹${_calculateTotalAmount(trips, paymentType).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: paymentType == 'advance' ? Colors.blue.shade600 : Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_autoRefreshEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.autorenew, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-refresh',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Payment list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return UltraFastPaymentWidget(
                trip: trip,
                paymentType: paymentType,
                onPaymentUpdated: _refreshData,
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
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
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
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
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
  
  double _calculateTotalAmount(List<Trip> trips, String paymentType) {
    return trips.fold(0.0, (sum, trip) {
      final amount = paymentType == 'advance' 
          ? trip.advanceSupplierFreight ?? 0.0
          : trip.balanceSupplierFreight ?? 0.0;
      return sum + amount;
    });
  }
  
  void _showBatchProcessingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Payment Processing'),
        content: const Text(
          'This feature allows you to process multiple payments at once for ultra-fast bulk operations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processBatchPayments();
            },
            child: const Text('Process All'),
          ),
        ],
      ),
    );
  }
  
  void _processBatchPayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Batch processing feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
} 