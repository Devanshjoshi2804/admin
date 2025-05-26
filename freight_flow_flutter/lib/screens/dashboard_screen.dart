import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'dart:html' as html;
import 'dart:math' as math;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late List<AnimationController> _cardControllers;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Create individual controllers for staggered card animations
    _cardControllers = List.generate(
      8, // Number of cards
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );

    _animationController.forward();
    _pulseController.repeat();
    
    // Start card animations with staggered delays
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripListProvider);
    
    return TopNavbarLayout(
      title: 'Dashboard',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              Colors.blue.shade50.withOpacity(0.3),
              Colors.purple.shade50.withOpacity(0.2),
            ],
          ),
        ),
        child: tripsAsync.when(
          data: (trips) {
            final tripsInTransit = trips.where((t) => t.status == 'In Transit').length;
            final pendingPayments = trips.where((t) => 
              t.balancePaymentStatus != 'Paid' || t.advancePaymentStatus != 'Paid'
            ).length;
            final podPending = trips.where((t) => !t.podUploaded).length;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedHeader(),
                  const SizedBox(height: 32),
                  _buildKPICards(trips.length, tripsInTransit, pendingPayments, podPending),
                  const SizedBox(height: 32),
                  _buildMainContent(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                ],
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb with improved styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Home',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade500, Colors.blue.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Header with greeting and actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                      Colors.blue.shade600,
                                      Colors.purple.shade500,
                                      Colors.blue.shade700,
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Good Morning! 👋',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Freight Management Dashboard',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monitor your logistics operations in real-time',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildHeaderActions(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: () {
            ref.refresh(tripListProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Refreshing dashboard...'),
                backgroundColor: Colors.blue.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.download_rounded,
          label: 'Export',
          onPressed: () {
            // Export functionality
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards(int totalTrips, int inTransit, int pendingPayments, int podPending) {
    final kpis = [
      _KPIData(
        title: 'Total Trips',
        value: totalTrips.toString(),
        subtitle: 'All trips in system',
        icon: Icons.local_shipping_rounded,
        gradient: [Colors.blue.shade400, Colors.blue.shade600],
        trend: '+12%',
        trendPositive: true,
      ),
      _KPIData(
        title: 'In Transit',
        value: inTransit.toString(),
        subtitle: 'Currently moving',
        icon: Icons.route_rounded,
        gradient: [Colors.orange.shade400, Colors.orange.shade600],
        trend: '+5%',
        trendPositive: true,
      ),
      _KPIData(
        title: 'Pending Payments',
        value: pendingPayments.toString(),
        subtitle: 'Awaiting payment',
        icon: Icons.payments_rounded,
        gradient: [Colors.purple.shade400, Colors.purple.shade600],
        trend: '-8%',
        trendPositive: false,
      ),
      _KPIData(
        title: 'POD Pending',
        value: podPending.toString(),
        subtitle: 'Documents needed',
        icon: Icons.description_rounded,
        gradient: [Colors.red.shade400, Colors.red.shade600],
        trend: '-3%',
        trendPositive: false,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                               constraints.maxWidth > 800 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.4,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _cardControllers[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _cardControllers[index].value,
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - _cardControllers[index].value)),
                    child: Opacity(
                      opacity: _cardControllers[index].value,
                      child: _buildKPICard(kpis[index]),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKPICard(_KPIData kpi) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: kpi.gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kpi.gradient.first.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    kpi.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kpi.trendPositive 
                        ? Colors.green.shade50 
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kpi.trendPositive 
                            ? Icons.trending_up_rounded 
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: kpi.trendPositive 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kpi.trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kpi.trendPositive 
                              ? Colors.green.shade600 
                              : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              kpi.value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kpi.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kpi.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecentActivity(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildQuickStats(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return AnimatedBuilder(
      animation: _cardControllers[4],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardControllers[4].value)),
          child: Opacity(
            opacity: _cardControllers[4].value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade500, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/trips'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(5, (index) => _buildActivityItem(index)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {'title': 'Trip TRFDBCCCC0 completed', 'time': '2 hours ago', 'type': 'success'},
      {'title': 'Payment pending for Trip TR001', 'time': '4 hours ago', 'type': 'warning'},
      {'title': 'New client added: Tata Steel Ltd', 'time': '6 hours ago', 'type': 'info'},
      {'title': 'Vehicle MH02AB1234 maintenance due', 'time': '1 day ago', 'type': 'warning'},
      {'title': 'POD uploaded for Trip TR005', 'time': '2 days ago', 'type': 'success'},
    ];

    final activity = activities[index];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: activity['type'] == 'success' 
                  ? Colors.green.shade500
                  : activity['type'] == 'warning'
                      ? Colors.orange.shade500
                      : Colors.blue.shade500,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return AnimatedBuilder(
      animation: _cardControllers[5],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardControllers[5].value)),
          child: Opacity(
            opacity: _cardControllers[5].value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple.shade500, Colors.purple.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Quick Stats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStatItem('Revenue', '₹2,07,92,586', Colors.green),
                    _buildStatItem('Margin', '₹1,61,84,038', Colors.blue),
                    _buildStatItem('Clients', '4', Colors.orange),
                    _buildStatItem('Suppliers', '3', Colors.purple),
                    _buildStatItem('Vehicles', '5', Colors.cyan),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AnimatedBuilder(
      animation: _cardControllers[6],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardControllers[6].value)),
          child: Opacity(
            opacity: _cardControllers[6].value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildQuickActionCard(
                          'Book Trip',
                          Icons.add_box_rounded,
                          Colors.blue,
                          () => context.go('/booking'),
                        ),
                        _buildQuickActionCard(
                          'View Trips',
                          Icons.local_shipping_rounded,
                          Colors.green,
                          () => context.go('/trips'),
                        ),
                        _buildQuickActionCard(
                          'Payments',
                          Icons.payments_rounded,
                          Colors.purple,
                          () => context.go('/payments'),
                        ),
                        _buildQuickActionCard(
                          'Fleet',
                          Icons.directions_bus_rounded,
                          Colors.orange,
                          () => context.go('/vehicles'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading dashboard...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text('Error loading dashboard: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(tripListProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _KPIData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String trend;
  final bool trendPositive;

  const _KPIData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.trend,
    required this.trendPositive,
  });
} 