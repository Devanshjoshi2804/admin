import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/payment.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/widgets/payments/payment_details_dialog.dart';
import 'package:freight_flow_flutter/widgets/payments/payment_initiation_dialog.dart';
import 'package:freight_flow_flutter/widgets/payments/payment_summary_cards.dart';
import 'package:intl/intl.dart';

// Provider for payment filters
final paymentFiltersProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'status': 'All',
    'dateRange': null,
    'searchQuery': '',
  };
});

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch trips data
    final tripsAsync = ref.watch(tripListProvider);
    
    return TopNavbarLayout(
      title: 'Payment Dashboard',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/'),
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                ),
                const Text('Payment Dashboard'),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            const Text(
              'Payment Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Summary Cards
            tripsAsync.when(
              data: (trips) => PaymentSummaryCards(trips: trips),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error loading data: $error')),
            ),
            const SizedBox(height: 24),
            
            // Payment Management section
            _buildPaymentManagementSection(),
            const SizedBox(height: 16),
            
            // Tab buttons
            _buildTabButtons(),
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  switch (_selectedTabIndex) {
                    case 0:
                      return _buildBalancePaymentsTab(trips);
                    case 1:
                      return _buildAdvancePaymentsTab(trips);
                    case 2:
                      return _buildPaymentHistoryTab(trips);
                    default:
                      return const SizedBox.shrink();
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error loading data: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentManagementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Row(
              children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('Export All Payments'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.refresh(tripListProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Process, track and export advance and balance payments for all trips',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Row(
      children: [
        _buildTabButton(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Balance Payments',
          isSelected: _selectedTabIndex == 0,
          onTap: () {
            _tabController.animateTo(0);
          },
        ),
        const SizedBox(width: 16),
        _buildTabButton(
          icon: Icons.payments_outlined,
          label: 'Advance Payments',
          isSelected: _selectedTabIndex == 1,
          onTap: () {
            _tabController.animateTo(1);
          },
        ),
        const SizedBox(width: 16),
        _buildTabButton(
          icon: Icons.history_outlined,
          label: 'Payment History',
          isSelected: _selectedTabIndex == 2,
          onTap: () {
            _tabController.animateTo(2);
          },
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePaymentsTab(List<Trip> trips) {
    // Filter trips with pending balance payments
    final balancePayments = trips.where((trip) => 
      trip.balanceSupplierFreight != null && 
      trip.balanceSupplierFreight! > 0 &&
      (trip.balancePaymentStatus == null || 
       trip.balancePaymentStatus == 'Pending' || 
       trip.balancePaymentStatus == 'Initiated')
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and filter row
        _buildSearchFilterRow(),
        const SizedBox(height: 16),
        
        // Table header
        _buildTableHeader(),
        
        // Table content
        Expanded(
          child: balancePayments.isEmpty
              ? const Center(
                  child: Text(
                    'No pending balance payments',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: balancePayments.length,
                  itemBuilder: (context, index) {
                    final trip = balancePayments[index];
                    return _buildPaymentRow(
                      trip: trip,
                      paymentType: 'balance',
                      amount: trip.balanceSupplierFreight ?? 0,
                      status: trip.balancePaymentStatus ?? 'Pending',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdvancePaymentsTab(List<Trip> trips) {
    // Filter trips with pending advance payments
    final advancePayments = trips.where((trip) => 
      trip.advanceSupplierFreight != null && 
      trip.advanceSupplierFreight! > 0 &&
      (trip.advancePaymentStatus == null || 
       trip.advancePaymentStatus == 'Pending' || 
       trip.advancePaymentStatus == 'Initiated')
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and filter row
        _buildSearchFilterRow(),
        const SizedBox(height: 16),
        
        // Table header
        _buildTableHeader(),
        
        // Table content
        Expanded(
          child: advancePayments.isEmpty
              ? const Center(
                  child: Text(
                    'No pending advance payments',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: advancePayments.length,
                  itemBuilder: (context, index) {
                    final trip = advancePayments[index];
                    return _buildPaymentRow(
                      trip: trip,
                      paymentType: 'advance',
                      amount: trip.advanceSupplierFreight ?? 0,
                      status: trip.advancePaymentStatus ?? 'Pending',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryTab(List<Trip> trips) {
    // Filter trips with completed payments
    final completedPayments = trips.where((trip) => 
      (trip.advancePaymentStatus == 'Paid' || trip.balancePaymentStatus == 'Paid')
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and filter row
        _buildSearchFilterRow(),
        const SizedBox(height: 16),
        
        // Table header
        _buildTableHeader(isHistory: true),
        
        // Table content
        Expanded(
          child: completedPayments.isEmpty
              ? const Center(
                  child: Text(
                    'No payment history',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: completedPayments.length,
                  itemBuilder: (context, index) {
                    final trip = completedPayments[index];
                    
                    // Show both advance and balance payments if they're paid
                    if (trip.advancePaymentStatus == 'Paid' && trip.balancePaymentStatus == 'Paid') {
                      return Column(
                        children: [
                          _buildPaymentRow(
                            trip: trip,
                            paymentType: 'advance',
                            amount: trip.advanceSupplierFreight ?? 0,
                            status: 'Paid',
                            isHistory: true,
                          ),
                          _buildPaymentRow(
                            trip: trip,
                            paymentType: 'balance',
                            amount: trip.balanceSupplierFreight ?? 0,
                            status: 'Paid',
                            isHistory: true,
                          ),
                        ],
                      );
                    } else if (trip.advancePaymentStatus == 'Paid') {
                      return _buildPaymentRow(
                        trip: trip,
                        paymentType: 'advance',
                        amount: trip.advanceSupplierFreight ?? 0,
                        status: 'Paid',
                        isHistory: true,
                      );
                    } else {
                      return _buildPaymentRow(
                        trip: trip,
                        paymentType: 'balance',
                        amount: trip.balanceSupplierFreight ?? 0,
                        status: 'Paid',
                        isHistory: true,
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by Trip ID, Supplier...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              // Update search filter
              ref.read(paymentFiltersProvider.notifier).update((state) => {
                ...state,
                'searchQuery': value,
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            // Show filter dialog
          },
          icon: const Icon(Icons.filter_list),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader({bool isHistory = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Trip ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Supplier',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          if (isHistory)
            Expanded(
              flex: 1,
              child: Text(
                'Payment Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required Trip trip,
    required String paymentType,
    required double amount,
    required String status,
    bool isHistory = false,
  }) {
    // Create a payment object from the trip data
    final payment = Payment(
      id: '${trip.id}-${paymentType == 'advance' ? 'adv' : 'bal'}',
      tripId: trip.id,
      orderId: trip.orderNumber,
      lrNumber: trip.lrNumbers.isNotEmpty ? trip.lrNumbers.first : 'N/A',
      supplierName: trip.supplierName ?? 'Unknown Supplier',
      amount: amount,
      status: status,
      paymentDate: status == 'Paid' ? DateTime.now() : null,
      utrNumber: trip.utrNumber,
      paymentMethod: trip.paymentMethod,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'LR: ${trip.lrNumbers.isNotEmpty ? trip.lrNumbers.first : 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(trip.supplierName ?? 'Unknown Supplier'),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${NumberFormat('#,##,###').format(amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildStatusBadge(status),
          ),
          if (isHistory)
            Expanded(
              flex: 1,
              child: Text(
                payment.paymentDate != null
                    ? DateFormat('dd/MM/yyyy').format(payment.paymentDate!)
                    : '-',
              ),
            ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (status == 'Pending')
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
                    onPressed: () => _showPaymentInitiationDialog(payment, paymentType),
                    tooltip: 'Initiate Payment',
                  ),
                if (status == 'Initiated')
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () => _showPaymentInitiationDialog(payment, paymentType),
                    tooltip: 'Mark as Paid',
                  ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showPaymentDetailsDialog(payment),
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case 'Pending':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
      case 'Initiated':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'Paid':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showPaymentInitiationDialog(Payment payment, String paymentType) {
    showDialog(
      context: context,
      builder: (context) => PaymentInitiationDialog(
        payment: payment,
        paymentType: paymentType,
      ),
    ).then((result) {
      if (result == true) {
        // Refresh data after successful payment
        ref.refresh(tripListProvider);
      }
    });
  }

  void _showPaymentDetailsDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => PaymentDetailsDialog(payment: payment),
    );
  }
} 