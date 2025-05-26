import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:intl/intl.dart';
import 'package:freight_flow_flutter/widgets/ui/status_badge.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/models/trip.dart' as trip_model;
import 'package:freight_flow_flutter/widgets/dialogs/additional_charges_dialog.dart';
import 'package:freight_flow_flutter/widgets/dialogs/document_management_dialog.dart';
import 'dart:math' as math;

// Extension for string operations
extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}

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

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with TickerProviderStateMixin {
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    // Listen to search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripListProvider);

    return TopNavbarLayout(
      title: 'Trip Management',
      actions: [],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50.withOpacity(0.3),
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAnimatedHeader(),
              tripsAsync.when(
                data: (trips) => _buildTripsList(trips),
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(err),
              ),
            ],
          ),
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
                                        Colors.orange.shade600,
                                        Colors.red.shade500,
                                        Colors.orange.shade700,
                                      ],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Trip Management 🚛',
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
                              'Track and manage your freight shipments',
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
                  
                  // Search and filters
                  _buildSearchAndFilters(),
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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, size: 16, color: Colors.orange[600]),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.go('/'),
            child: Text(
              'Home',
              style: TextStyle(color: Colors.orange[600], fontSize: 14),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.orange[400]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade500, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Trips',
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
          onPressed: () {
            ref.refresh(tripListProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Refreshing trips...'),
                backgroundColor: Colors.orange.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          isSecondary: true,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.download_rounded,
          label: 'Export',
          onPressed: () {},
          isSecondary: true,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.add_rounded,
          label: 'Create Trip',
          onPressed: () {
            context.go('/booking');
          },
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
                    colors: [Colors.orange.shade500, Colors.orange.shade600],
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
                    : Colors.orange.withOpacity(0.3),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSecondary ? Colors.grey[700] : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // First row - Search and basic filters
        Row(
          children: [
            // Search bar
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search trips by order ID, LR, client...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Status Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(value: 'Booked', child: Text('Booked')),
                    DropdownMenuItem(value: 'In Transit', child: Text('In Transit')),
                    DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Client Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'All Clients',
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
                  items: const [
                    DropdownMenuItem(value: 'All Clients', child: Text('All Clients')),
                    DropdownMenuItem(value: 'Devansh', child: Text('Devansh')),
                    DropdownMenuItem(value: 'Other', child: Text('Other Clients')),
                  ],
                  onChanged: (value) {
                    // Handle client filter
                  },
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Second row - Date filters
        Row(
          children: [
            // Date Range Filter
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'All Time',
                    isExpanded: true,
                    icon: Icon(Icons.calendar_today_rounded, color: Colors.grey[600]),
                    items: const [
                      DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                      DropdownMenuItem(value: 'Today', child: Text('Today')),
                      DropdownMenuItem(value: 'Yesterday', child: Text('Yesterday')),
                      DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                      DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                      DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                      DropdownMenuItem(value: 'This Year', child: Text('This Year')),
                      DropdownMenuItem(value: 'Custom Range', child: Text('Custom Date Range')),
                    ],
                    onChanged: (value) {
                      // Handle date filter
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Vehicle Type Filter
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'All Vehicles',
                    isExpanded: true,
                    icon: Icon(Icons.local_shipping_rounded, color: Colors.grey[600]),
                    items: const [
                      DropdownMenuItem(value: 'All Vehicles', child: Text('All Vehicle Types')),
                      DropdownMenuItem(value: 'Truck', child: Text('Truck')),
                      DropdownMenuItem(value: 'Container', child: Text('Container')),
                      DropdownMenuItem(value: 'Trailer', child: Text('Trailer')),
                    ],
                    onChanged: (value) {
                      // Handle vehicle type filter
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Route Filter
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'All Routes',
                    isExpanded: true,
                    icon: Icon(Icons.route_rounded, color: Colors.grey[600]),
                    items: const [
                      DropdownMenuItem(value: 'All Routes', child: Text('All Routes')),
                      DropdownMenuItem(value: 'Panvel-Lokhandwala', child: Text('Panvel → Lokhandwala')),
                      DropdownMenuItem(value: 'Pune-Delhi', child: Text('Pune → Delhi')),
                      DropdownMenuItem(value: 'Mumbai-Bangalore', child: Text('Mumbai → Bangalore')),
                    ],
                    onChanged: (value) {
                      // Handle route filter
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripsList(List<trip_model.Trip> trips) {
    // Filter trips based on search and filter
    final filteredTrips = trips.where((trip) {
      final matchesSearch = _searchQuery.isEmpty ||
          trip.orderNumber.toLowerCase().contains(_searchQuery) ||
          trip.lrNumbers.any((lr) => lr.toLowerCase().contains(_searchQuery)) ||
          trip.clientName.toLowerCase().contains(_searchQuery);
      
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Booked' && trip.status == 'Booked') ||
          (_selectedFilter == 'In Transit' && trip.status == 'In Transit') ||
          (_selectedFilter == 'Delivered' && trip.status == 'Delivered') ||
          (_selectedFilter == 'Completed' && trip.status == 'Completed');
      
      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredTrips.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _cardsAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Container(
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
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.orange.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeaderCell('Trip Date', width: 110),
                        _buildHeaderCell('Order ID', width: 150),
                        _buildHeaderCell('LR Number', width: 110),
                        _buildHeaderCell('Client', width: 130),
                        _buildHeaderCell('Client (₹)', width: 110),
                        _buildHeaderCell('Supplier (₹)', width: 120),
                        _buildHeaderCell('Margin (₹)', width: 110),
                        _buildHeaderCell('Route', width: 220),
                        _buildHeaderCell('Vehicle', width: 130),
                        _buildHeaderCell('Status', width: 130),
                        _buildHeaderCell('Advance', width: 110),
                        _buildHeaderCell('Balance', width: 110),
                        _buildHeaderCell('Actions', width: 220),
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
                    children: List.generate(filteredTrips.length, (index) {
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(30 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: _buildTripRow(filteredTrips[index], index),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1, double? width}) {
    Widget cell = Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.orange.shade700,
      ),
    );
    
    if (width != null) {
      return Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: cell,
      );
    } else {
      return Expanded(
        flex: flex,
        child: cell,
      );
    }
  }

  Widget _buildTripRow(trip_model.Trip trip, int index) {
    final isEven = index % 2 == 0;
    final margin = (trip.clientFreight ?? 0) - (trip.supplierFreight ?? 0);
    
    return InkWell(
      onTap: () => _showTripDetailsDialog(trip),
      onHover: (isHovered) {
        // Optional: Add hover effects
      },
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
              // Trip Date
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _formatDate(trip.startDate),
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              // Order ID
              Container(
                width: 150,
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
                  ],
                ),
              ),

              // LR Number
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  trip.lrNumbers.isNotEmpty ? trip.lrNumbers.first : 'N/A',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Client
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  trip.clientName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Client Value (₹)
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '₹${(trip.clientFreight ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ),

              // Supplier Value (₹)
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '₹${(trip.supplierFreight ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              ),

              // Margin (₹)
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '₹${margin.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: margin >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
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

              // Vehicle
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  trip.vehicleNumber ?? 'N/A',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Status
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(trip.status).withOpacity(0.3)),
                  ),
                  child: Text(
                    trip.status,
                    style: TextStyle(
                      color: _getStatusColor(trip.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Advance Payment Status
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(trip.advancePaymentStatus ?? 'None').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trip.advancePaymentStatus ?? 'NONE',
                    style: TextStyle(
                      color: _getPaymentStatusColor(trip.advancePaymentStatus ?? 'None'),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Balance Payment Status
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(trip.balancePaymentStatus ?? 'None').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trip.balancePaymentStatus ?? 'NONE',
                    style: TextStyle(
                      color: _getPaymentStatusColor(trip.balancePaymentStatus ?? 'None'),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Actions
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildActionIcon(
                      icon: Icons.visibility_rounded,
                      color: Colors.blue,
                      onTap: () => _showTripDetailsDialog(trip),
                      tooltip: 'View Details',
                    ),
                    const SizedBox(width: 6),
                    _buildActionIcon(
                      icon: Icons.edit_rounded,
                      color: Colors.orange,
                      onTap: () => context.go('/trips/edit/${trip.id}'),
                      tooltip: 'Edit Trip',
                    ),
                    const SizedBox(width: 6),
                    _buildActionIcon(
                      icon: Icons.add_circle_outline_rounded,
                      color: Colors.green,
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => AdditionalChargesDialog(
                          trip: trip,
                          onChargesUpdated: (updatedTrip) {
                            ref.refresh(tripListProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Additional charges updated successfully'),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      tooltip: 'Additional Charges',
                    ),
                    const SizedBox(width: 6),
                    _buildActionIcon(
                      icon: Icons.description_rounded,
                      color: Colors.purple,
                      onTap: () => _showDocumentsDialog(trip),
                      tooltip: 'Documents',
                    ),
                    const SizedBox(width: 6),
                    _buildActionIcon(
                      icon: Icons.more_vert_rounded,
                      color: Colors.grey.shade600,
                      onTap: () => _showTripActions(trip),
                      tooltip: 'More Actions',
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Colors.blue;
      case 'in transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'none':
        return Colors.grey;
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

  Widget _buildEmptyState() {
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
              Icons.local_shipping_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No trips found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/booking'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading trips...',
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
              'Error loading trips: $error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.refresh(tripListProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
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

  // Dialog methods
  void _showTripDetailsDialog(trip_model.Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade500, Colors.orange.shade600],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FTL Trip Details - ${trip.orderNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Complete trip information and status',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: trip.status),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trip Overview Section
                        _buildTripSection(
                          'Trip Overview',
                          Icons.info_rounded,
                          [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailCard('Order Number', trip.orderNumber, Icons.confirmation_number_rounded),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailCard('LR Numbers', trip.lrNumbers.join(', '), Icons.receipt_long_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailCard('Trip Date', _formatDate(trip.startDate), Icons.calendar_today_rounded),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailCard('Status', trip.status, Icons.info_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Route Information
                        _buildTripSection(
                          'Route Information',
                          Icons.route_rounded,
                          [
                            _buildRouteCard(trip.source, trip.destination),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailCard('Distance', '${trip.distance ?? 0} KM', Icons.straighten_rounded),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailCard('Vehicle Type', trip.vehicleType ?? 'N/A', Icons.local_shipping_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Client & Supplier Information
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTripSection(
                                'Client Information',
                                Icons.business_rounded,
                                [
                                  _buildDetailCard('Client Name', trip.clientName, Icons.person_rounded),
                                  const SizedBox(height: 12),
                                  _buildDetailCard('Client Freight', '₹${(trip.clientFreight ?? 0).toStringAsFixed(2)}', Icons.currency_rupee_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTripSection(
                                'Supplier Information',
                                Icons.local_shipping_rounded,
                                [
                                  _buildDetailCard('Supplier', trip.supplierName ?? 'N/A', Icons.factory_rounded),
                                  const SizedBox(height: 12),
                                  _buildDetailCard('Supplier Freight', '₹${(trip.supplierFreight ?? 0).toStringAsFixed(2)}', Icons.currency_rupee_rounded),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Vehicle Information
                        _buildTripSection(
                          'Vehicle Information',
                          Icons.directions_bus_rounded,
                          [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailCard('Vehicle Number', trip.vehicleNumber ?? 'N/A', Icons.confirmation_number_rounded),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailCard('Driver Name', trip.driverName ?? 'N/A', Icons.person_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailCard('Driver Phone', trip.driverPhone ?? 'N/A', Icons.phone_rounded),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDetailCard('Vehicle Type', trip.vehicleType ?? 'N/A', Icons.local_shipping_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Financial Summary
                        _buildTripSection(
                          'Financial Summary',
                          Icons.account_balance_wallet_rounded,
                          [
                            _buildFinancialSummaryCard(trip),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Payment Status
                        _buildTripSection(
                          'Payment Status',
                          Icons.payment_rounded,
                          [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPaymentStatusCard(
                                    'Advance Payment',
                                    trip.advancePaymentStatus ?? 'Not Started',
                                    '₹${(trip.advanceSupplierFreight ?? 0).toStringAsFixed(2)}',
                                    trip.advancePaymentStatus == 'Paid' ? Colors.green : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildPaymentStatusCard(
                                    'Balance Payment',
                                    trip.balancePaymentStatus ?? 'Not Started',
                                    '₹${(trip.balanceSupplierFreight ?? 0).toStringAsFixed(2)}',
                                    trip.balancePaymentStatus == 'Paid' ? Colors.green : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Document Status
                        _buildTripSection(
                          'Document Status',
                          Icons.description_rounded,
                          [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDocumentStatusCard(
                                    'POD Status',
                                    trip.podUploaded ? 'Uploaded' : 'Pending',
                                    trip.podUploaded ? Icons.check_circle_rounded : Icons.pending_rounded,
                                    trip.podUploaded ? Colors.green : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDocumentStatusCard(
                                    'Balance Queue',
                                    trip.isInBalanceQueue ? 'Yes' : 'No',
                                    trip.isInBalanceQueue ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    trip.isInBalanceQueue ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        if (trip.additionalCharges?.isNotEmpty == true || trip.deductionCharges?.isNotEmpty == true) ...[
                          const SizedBox(height: 24),
                          _buildTripSection(
                            'Additional Charges',
                            Icons.add_circle_outline_rounded,
                            [
                              _buildChargesCard(trip),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/trips/edit/${trip.id}');
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => AdditionalChargesDialog(
                                trip: trip,
                                onChargesUpdated: (updatedTrip) {
                                  ref.refresh(tripListProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Additional charges updated successfully'),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Charges'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildTripSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.orange.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(String source, String destination) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FROM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  source,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.blue[700]),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(trip_model.Trip trip) {
    final margin = (trip.margin ?? 0);
    final additionalTotal = trip.additionalCharges?.fold<double>(0.0, (sum, charge) => sum + charge.amount) ?? 0.0;
    final deductionTotal = trip.deductionCharges?.fold<double>(0.0, (sum, charge) => sum + charge.amount) ?? 0.0;
    final netBalance = (trip.balanceSupplierFreight ?? 0) + additionalTotal - deductionTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFinancialItem('Client Freight', '₹${(trip.clientFreight ?? 0).toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildFinancialItem('Supplier Freight', '₹${(trip.supplierFreight ?? 0).toStringAsFixed(2)}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinancialItem('Margin', '₹${margin.toStringAsFixed(2)}', 
                  margin >= 0 ? Colors.green : Colors.red),
              ),
              Expanded(
                child: _buildFinancialItem('Net Balance', '₹${netBalance.toStringAsFixed(2)}', Colors.blue),
              ),
            ],
          ),
          if (additionalTotal > 0 || deductionTotal > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialItem('Additional Charges', '+₹${additionalTotal.toStringAsFixed(2)}', Colors.orange),
                ),
                Expanded(
                  child: _buildFinancialItem('Deductions', '-₹${deductionTotal.toStringAsFixed(2)}', Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, String value, [Color? valueColor]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard(String title, String status, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusCard(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesCard(trip_model.Trip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trip.additionalCharges?.isNotEmpty == true) ...[
            Text(
              'Additional Charges',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 8),
            ...trip.additionalCharges!.map((charge) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(charge.description, style: const TextStyle(fontSize: 13)),
                  Text('+₹${charge.amount.toStringAsFixed(2)}', 
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[600])),
                ],
              ),
            )),
          ],
          if (trip.additionalCharges?.isNotEmpty == true && trip.deductionCharges?.isNotEmpty == true)
            const SizedBox(height: 12),
          if (trip.deductionCharges?.isNotEmpty == true) ...[
            Text(
              'Deduction Charges',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            ...trip.deductionCharges!.map((charge) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(charge.description, style: const TextStyle(fontSize: 13)),
                  Text('-₹${charge.amount.toStringAsFixed(2)}', 
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red[600])),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _showTripActions(trip_model.Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Trip Actions',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildActionTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Additional Charges',
                subtitle: 'Add or modify charges',
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => AdditionalChargesDialog(
                      trip: trip,
                      onChargesUpdated: (updatedTrip) {
                        // Refresh the trips list when charges are updated
                        ref.refresh(tripListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Additional charges updated successfully'),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              _buildActionTile(
                icon: Icons.upload_file_rounded,
                title: 'Upload POD',
                subtitle: 'Upload proof of delivery',
                onTap: () {
                  Navigator.of(context).pop();
                  // Handle POD upload
                },
              ),
              _buildActionTile(
                icon: Icons.payment_rounded,
                title: 'Payment Status',
                subtitle: 'Update payment information',
                onTap: () {
                  Navigator.of(context).pop();
                  // Handle payment status update
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.orange.shade600),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showDocumentsDialog(trip_model.Trip trip) {
    showDialog(
      context: context,
      builder: (context) => DocumentManagementDialog(
        trip: trip,
        onDocumentUploaded: (updatedTrip) {
          ref.refresh(tripListProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Document uploaded successfully'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
} 