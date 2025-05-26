import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:freight_flow_flutter/providers/supplier_provider.dart';
import 'package:freight_flow_flutter/models/trip.dart' as trip_model;
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/widgets/ui/status_badge.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'dart:math' as math;

// Streamlined Payment Dashboard for Core Workflow
class PaymentDashboardScreen extends ConsumerStatefulWidget {
  const PaymentDashboardScreen({super.key});

  @override
  ConsumerState<PaymentDashboardScreen> createState() => _PaymentDashboardScreenState();
}

class _PaymentDashboardScreenState extends ConsumerState<PaymentDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isRefreshing = false;
  
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    _cardsAnimationController.forward();
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripListProvider);

    return TopNavbarLayout(
      title: 'Payment Dashboard',
      actions: [],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50.withOpacity(0.3),
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAnimatedHeader(),
            const SizedBox(height: 24),
            // Tab structure
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade500, Colors.indigo.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Advance Pending'),
                  Tab(text: 'Balance Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            Expanded(
              child: tripsAsync.when(
                data: (trips) => _buildPaymentDashboard(trips),
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(err),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  _buildBreadcrumb(),
                  const SizedBox(height: 24),
                  
                  // Title and main actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (0.02 * math.sin(_pulseController.value * 2 * math.pi)),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.indigo.shade600,
                                        Colors.blue.shade500,
                                        Colors.indigo.shade700,
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Payment Dashboard 💳',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage payments and financial tracking',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHeaderActions(),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Filters Section
                  _buildPaymentFilters(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, size: 16, color: Colors.indigo[600]),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.go('/'),
            child: Text(
              'Home',
              style: TextStyle(color: Colors.indigo[600], fontSize: 14),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.indigo[400]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade500, Colors.indigo.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Payments',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: () => _refreshData(),
          isSecondary: true,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.download_rounded,
          label: 'Export',
          onPressed: () {},
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSecondary
                ? null
                : LinearGradient(
                    colors: [Colors.indigo.shade500, Colors.indigo.shade600],
                  ),
            color: isSecondary ? Colors.white : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSecondary ? Colors.grey.shade300 : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: isSecondary 
                    ? Colors.black.withOpacity(0.05)
                    : Colors.indigo.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSecondary ? Colors.grey[700] : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSecondary ? Colors.grey[700] : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFilters() {
    return Column(
      children: [
        // First row - Basic filters (made smaller)
        Row(
          children: [
            // Payment Type Filter
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'All Payments',
                    isExpanded: true,
                    icon: Icon(Icons.payment_rounded, color: Colors.grey[600], size: 18),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(value: 'All Payments', child: Text('All Payment Types')),
                      DropdownMenuItem(value: 'Advance', child: Text('Advance Payments')),
                      DropdownMenuItem(value: 'Balance', child: Text('Balance Payments')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed Payments')),
                    ],
                    onChanged: (value) {
                      // Handle payment type filter
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Status Filter
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'All Status',
                    isExpanded: true,
                    icon: Icon(Icons.assignment_turned_in_rounded, color: Colors.grey[600], size: 18),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                    ],
                    onChanged: (value) {
                      // Handle status filter
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Search Field
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: TextField(
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search payments...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentDashboard(List<trip_model.Trip> trips) {
    // Calculate summary statistics
    final pendingAdvanceAmount = trips
        .where((trip) => trip.advancePaymentStatus != 'Paid')
        .fold<double>(0.0, (sum, trip) => sum + (trip.advanceSupplierFreight ?? 0.0));
    
    final pendingAdvanceCount = trips
        .where((trip) => trip.advancePaymentStatus != 'Paid')
        .length;
    
    final pendingBalanceAmount = trips
        .where((trip) => trip.isInBalanceQueue && trip.balancePaymentStatus != 'Paid' && trip.podUploaded)
        .fold<double>(0.0, (sum, trip) => sum + (trip.balanceSupplierFreight ?? 0.0));
    
    final pendingBalanceCount = trips
        .where((trip) => trip.isInBalanceQueue && trip.balancePaymentStatus != 'Paid' && trip.podUploaded)
        .length;
    
    final todayPayments = 0; // This would come from actual payment data
    final monthlyTotal = 0; // This would come from actual payment data

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Cards Section
          Container(
            padding: const EdgeInsets.all(8),
            child: _buildSummaryCards(
              pendingAdvanceAmount,
              pendingAdvanceCount,
              pendingBalanceAmount,
              pendingBalanceCount,
              todayPayments,
              monthlyTotal,
            ),
          ),
          
          // Main Content Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade500, Colors.indigo.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.all(6),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('Advance Pending'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('Balance Pending'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('Completed'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tab Content with better height management
                Container(
                  constraints: BoxConstraints(
                    minHeight: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAdvancePendingTab(trips),
                      _buildBalancePendingTab(trips),
                      _buildCompletedTab(trips),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    double pendingAdvanceAmount,
    int pendingAdvanceCount,
    double pendingBalanceAmount,
    int pendingBalanceCount,
    int todayPayments,
    int monthlyTotal,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.6,
        children: [
          _buildSummaryCard(
            'Pending Advance',
            '₹${pendingAdvanceAmount.toStringAsFixed(0)}',
            '$pendingAdvanceCount trips',
            Icons.schedule_rounded,
            Colors.orange,
          ),
          _buildSummaryCard(
            'Pending Balance',
            '₹${pendingBalanceAmount.toStringAsFixed(0)}',
            '$pendingBalanceCount trips',
            Icons.pending_actions_rounded,
            Colors.purple,
          ),
          _buildSummaryCard(
            'Today\'s Payments',
            '₹$todayPayments',
            '0 payments',
            Icons.today_rounded,
            Colors.green,
          ),
          _buildSummaryCard(
            'Monthly Total',
            '₹$monthlyTotal',
            '0 payments',
            Icons.calendar_month_rounded,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 6),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.green.shade600, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+5%',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancePendingTab(List<trip_model.Trip> trips) {
    final advancePendingTrips = trips.where((trip) => 
      trip.advancePaymentStatus != 'Paid'
    ).toList();

    return _buildPaymentGrid(advancePendingTrips, 'advance');
  }

  Widget _buildBalancePendingTab(List<trip_model.Trip> trips) {
    // Updated filter logic for balance pending trips
    final balancePendingTrips = trips.where((trip) => 
      // Trip should have advance payment completed
      trip.advancePaymentStatus == 'Paid' &&
      // Balance payment should not be paid yet
      trip.balancePaymentStatus != 'Paid' &&
      // Either POD is uploaded OR trip is in transit/delivered (indicating work is done)
      (trip.podUploaded || trip.status == 'In Transit' || trip.status == 'Delivered' || trip.status == 'Completed')
    ).toList();

    return _buildPaymentGrid(balancePendingTrips, 'balance');
  }

  Widget _buildCompletedTab(List<trip_model.Trip> trips) {
    final completedTrips = trips.where((trip) => 
      trip.advancePaymentStatus == 'Paid' && 
      trip.balancePaymentStatus == 'Paid'
    ).toList();

    return _buildPaymentGrid(completedTrips, 'completed');
  }

  Widget _buildPaymentGrid(List<trip_model.Trip> trips, String type) {
    if (trips.isEmpty) {
      return _buildEmptyState(type);
    }

    return AnimatedBuilder(
      animation: _cardsAnimationController,
      builder: (context, child) {
        return Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildHeaderCell('Trip ID', width: 160),
                    _buildHeaderCell('Client', width: 140),
                    _buildHeaderCell('Route', width: 220),
                    _buildHeaderCell('Amount', width: 120),
                    _buildHeaderCell('Supplier', width: 140),
                    _buildHeaderCell('Status', width: 130),
                    _buildHeaderCell('Due Date', width: 120),
                    _buildHeaderCell('Actions', width: 180),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Table Body with improved styling
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: List.generate(trips.length, (index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: _buildPaymentRow(trips[index], index, type),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCell(String title, {double? width}) {
    Widget cell = Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade700,
      ),
    );
    
    if (width != null) {
      return Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: cell,
      );
    } else {
      return Expanded(child: cell);
    }
  }

  Widget _buildPaymentRow(trip_model.Trip trip, int index, String type) {
    final isEven = index % 2 == 0;
    
    return InkWell(
      onTap: () => _showPaymentDetails(trip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isEven ? Colors.grey.shade50 : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Trip ID
              Container(
                width: 160,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.orderNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'LR: ${trip.lrNumbers.isNotEmpty ? trip.lrNumbers.first : 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Client
              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  trip.clientName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Route
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.source,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey[400]),
                    Expanded(
                      child: Text(
                        trip.destination,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '₹${_getPaymentAmount(trip, type).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Supplier
              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () => _showSupplierDetails(trip),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business_rounded, size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.supplierName ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Status
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(trip, type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getPaymentStatusColor(trip, type).withOpacity(0.3)),
                      ),
                      child: Text(
                        _getPaymentStatus(trip, type),
                        style: TextStyle(
                          color: _getPaymentStatusColor(trip, type),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Workflow indicator
                    _buildWorkflowIndicator(trip, type),
                  ],
                ),
              ),

              // Due Date
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  trip.createdAt != null 
                      ? DateFormat('dd/MM/yyyy').format(trip.createdAt!)
                      : 'N/A',
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              // Actions
              Container(
                width: 180,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildActionIcon(
                      icon: Icons.visibility_rounded,
                      color: Colors.blue,
                      onTap: () => _showPaymentDetails(trip),
                      tooltip: 'View Details',
                    ),
                    const SizedBox(width: 6),
                    _buildActionIcon(
                      icon: Icons.payment_rounded,
                      color: Colors.green,
                      onTap: () => _processPayment(trip, type),
                      tooltip: 'Process Payment',
                    ),
                    const SizedBox(width: 6),
                    _buildActionIcon(
                      icon: Icons.edit_rounded,
                      color: Colors.orange,
                      onTap: () => _editPayment(trip),
                      tooltip: 'Edit Payment',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getPaymentAmount(trip_model.Trip trip, String type) {
    switch (type) {
      case 'advance':
        return trip.advanceSupplierFreight ?? 0.0;
      case 'balance':
        // For balance payments, include the base balance amount plus any additional charges minus deductions
        final baseBalanceAmount = trip.balanceSupplierFreight ?? 0.0;
        final additionalChargesAmount = trip.additionalCharges?.fold<double>(
          0.0, (sum, charge) => sum + charge.amount
        ) ?? 0.0;
        final deductionChargesAmount = trip.deductionCharges?.fold<double>(
          0.0, (sum, charge) => sum + charge.amount
        ) ?? 0.0;
        
        // Balance = Base Balance + Additional Charges - Deduction Charges
        return baseBalanceAmount + additionalChargesAmount - deductionChargesAmount;
      default:
        return trip.supplierFreight ?? 0.0;
    }
  }

  String _getPaymentStatus(trip_model.Trip trip, String type) {
    switch (type) {
      case 'advance':
        return trip.advancePaymentStatus ?? 'Pending';
      case 'balance':
        return trip.balancePaymentStatus ?? 'Pending';
      default:
        return 'Completed';
    }
  }

  Color _getPaymentStatusColor(trip_model.Trip trip, String type) {
    final status = _getPaymentStatus(trip, type);
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _showPaymentDetails(trip_model.Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.payment_rounded, color: Colors.blue.shade600, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Details - ${trip.orderNumber}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Trip payment information and status',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip Overview
                          _buildPaymentSection('Trip Overview', [
                            _buildPaymentInfoRow('Order Number', trip.orderNumber),
                            _buildPaymentInfoRow('Client', trip.clientName),
                            _buildPaymentInfoRow('Supplier', trip.supplierName ?? 'N/A'),
                            _buildPaymentInfoRow('Route', '${trip.source} → ${trip.destination}'),
                          ]),
                          
                          const SizedBox(height: 24),
                          
                          // Financial Details
                          _buildPaymentSection('Financial Details', [
                            _buildPaymentInfoRow('Client Freight', '₹${(trip.clientFreight ?? 0).toStringAsFixed(2)}'),
                            _buildPaymentInfoRow('Supplier Freight', '₹${(trip.supplierFreight ?? 0).toStringAsFixed(2)}'),
                            _buildPaymentInfoRow('Advance Amount', '₹${(trip.advanceSupplierFreight ?? 0).toStringAsFixed(2)}'),
                            _buildPaymentInfoRow('Base Balance Amount', '₹${(trip.balanceSupplierFreight ?? 0).toStringAsFixed(2)}'),
                            if (trip.additionalCharges?.isNotEmpty == true) ...[
                              const Divider(),
                              Text(
                                'Additional Charges',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              ...trip.additionalCharges!.map((charge) => 
                                _buildPaymentInfoRow(charge.description, '+₹${charge.amount.toStringAsFixed(2)}')
                              ),
                              _buildPaymentInfoRow('Total Additional', '+₹${trip.additionalCharges!.fold<double>(0.0, (sum, charge) => sum + charge.amount).toStringAsFixed(2)}'),
                            ],
                            if (trip.deductionCharges?.isNotEmpty == true) ...[
                              const Divider(),
                              Text(
                                'Deduction Charges',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              ...trip.deductionCharges!.map((charge) => 
                                _buildPaymentInfoRow(charge.description, '-₹${charge.amount.toStringAsFixed(2)}')
                              ),
                              _buildPaymentInfoRow('Total Deductions', '-₹${trip.deductionCharges!.fold<double>(0.0, (sum, charge) => sum + charge.amount).toStringAsFixed(2)}'),
                            ],
                            if (trip.additionalCharges?.isNotEmpty == true || trip.deductionCharges?.isNotEmpty == true) ...[
                              const Divider(),
                              _buildPaymentInfoRow('Final Balance Amount', '₹${_getPaymentAmount(trip, 'balance').toStringAsFixed(2)}'),
                            ],
                          ]),
                          
                          const SizedBox(height: 24),
                          
                          // Payment Status
                          _buildPaymentSection('Payment Status', [
                            _buildPaymentInfoRow('Advance Status', trip.advancePaymentStatus ?? 'Not Started'),
                            _buildPaymentInfoRow('Balance Status', trip.balancePaymentStatus ?? 'Not Started'),
                            _buildPaymentInfoRow('POD Uploaded', trip.podUploaded ? 'Yes' : 'No'),
                            _buildPaymentInfoRow('Balance Queue', trip.isInBalanceQueue ? 'Yes' : 'No'),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(trip_model.Trip trip, String type) async {
    try {
      // Show ultra-fast processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.flash_on, color: Colors.indigo.shade600),
              const SizedBox(width: 8),
              Text('Ultra-Fast ${type.capitalize()} Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
              ),
              const SizedBox(height: 16),
              Text('Processing ${type} payment for ${trip.orderNumber}...'),
              const SizedBox(height: 8),
              Text(
                'Ultra-fast processing (~100ms)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );

      // Use ultra-fast payment progression
      final result = await _apiService.progressPaymentStatus(
        trip.id!,
        type,
      );

      Navigator.of(context).pop(); // Close processing dialog
      
      // Refresh the data using optimized providers
      ref.refresh(tripListProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${type.capitalize()} payment processed successfully!\n${result['message'] ?? ''}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close processing dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Error processing payment: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _editPayment(trip_model.Trip trip) {
    // Navigate to payment edit screen or show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit payment functionality for ${trip.orderNumber}'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title, subtitle;
    IconData icon;
    
    switch (type) {
      case 'advance':
        title = 'No advance payments pending';
        subtitle = 'All advance payments are up to date';
        icon = Icons.schedule_rounded;
        break;
      case 'balance':
        title = 'No balance payments pending';
        subtitle = 'All balance payments are completed';
        icon = Icons.pending_actions_rounded;
        break;
      case 'completed':
        title = 'No completed payments';
        subtitle = 'Completed payments will appear here';
        icon = Icons.check_circle_rounded;
        break;
      default:
        title = 'No payments found';
        subtitle = 'Payments will appear here';
        icon = Icons.payment_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading payments...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading payments: $error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _refreshData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      ref.refresh(tripListProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed successfully'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _showSupplierDetails(trip_model.Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.business_rounded, color: Colors.blue.shade600, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supplier Details',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              trip.supplierName ?? 'Loading...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content based on supplier data loading state
                  Consumer(
                    builder: (context, ref, child) {
                      // Get the supplier data using the supplier ID from the trip
                      final supplierAsync = ref.watch(supplierProvider(trip.supplierId));
                      
                      return supplierAsync.when(
                        data: (supplier) => _buildSupplierContent(supplier),
                        loading: () => const Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                        error: (error, stack) => Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade400,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading supplier details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unable to fetch supplier information from database',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to full supplier management page
                            context.go('/suppliers/${trip.supplierId}');
                          },
                          child: const Text('View Full Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupplierContent(Supplier supplier) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            _buildSupplierSection('Basic Information', [
              _buildCopyableField('Supplier ID', supplier.id),
              _buildCopyableField('Name', supplier.name),
              _buildCopyableField('City', supplier.city),
              _buildCopyableField('Address', supplier.address),
              _buildCopyableField('State', supplier.state ?? 'N/A'),
              _buildCopyableField('PIN Code', supplier.pinCode ?? 'N/A'),
            ]),
            
            const SizedBox(height: 24),
            
            // Contact Information
            _buildSupplierSection('Contact Information', [
              _buildCopyableField('Contact Person', supplier.contactName ?? 'N/A'),
              _buildCopyableField('Phone', supplier.contactPhone ?? 'N/A'),
              _buildCopyableField('Email', supplier.contactEmail ?? 'N/A'),
              if (supplier.representativeName != null) ...[
                _buildCopyableField('Representative', supplier.representativeName!),
                _buildCopyableField('Representative Phone', supplier.representativePhone ?? 'N/A'),
                _buildCopyableField('Representative Email', supplier.representativeEmail ?? 'N/A'),
              ],
            ]),
            
            const SizedBox(height: 24),
            
            // Business Information
            _buildSupplierSection('Business Information', [
              _buildCopyableField('GST Number', supplier.gstNumber),
              _buildCopyableField('PAN Number', supplier.panNumber ?? 'N/A'),
              _buildCopyableField('Service Type', supplier.serviceType ?? 'N/A'),
              _buildCopyableField('Status', supplier.isActive ? 'Active' : 'Inactive'),
            ]),
            
            const SizedBox(height: 24),
            
            // Banking Information
            _buildSupplierSection('Banking Information', [
              _buildCopyableField('Bank Name', supplier.bankName ?? 'N/A'),
              _buildCopyableField('Account Holder', supplier.accountHolderName ?? 'N/A'),
              _buildCopyableField('Account Number', supplier.accountNumber ?? 'N/A'),
              _buildCopyableField('Account Type', supplier.accountType ?? 'N/A'),
              _buildCopyableField('IFSC Code', supplier.ifscCode ?? 'N/A'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, size: 16, color: Colors.grey[600]),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied "$label" to clipboard'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowIndicator(trip_model.Trip trip, String type) {
    String indicator = '';
    Color indicatorColor = Colors.grey;
    
    if (type == 'advance') {
      if (trip.advancePaymentStatus == 'Paid') {
        indicator = '✓ Ready for Balance';
        indicatorColor = Colors.green;
      } else {
        indicator = '① Advance Due';
        indicatorColor = Colors.orange;
      }
    } else if (type == 'balance') {
      if (trip.advancePaymentStatus != 'Paid') {
        indicator = 'Advance First';
        indicatorColor = Colors.red;
      } else if (!trip.podUploaded) {
        indicator = 'POD Required';
        indicatorColor = Colors.amber;
      } else {
        indicator = '② Balance Due';
        indicatorColor = Colors.orange;
      }
    } else if (type == 'completed') {
      indicator = '✓ Complete';
      indicatorColor = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Text(
        indicator,
        style: TextStyle(
          fontSize: 10,
          color: indicatorColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 
