import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AdvancedAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  ConsumerState<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends ConsumerState<AdvancedAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedPeriod = 'This Month';
  final List<String> periods = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                items: periods.map((period) => DropdownMenuItem(
                  value: period,
                  child: Text(period, style: TextStyle(color: Colors.blue.shade700)),
                )).toList(),
                onChanged: (value) => setState(() => selectedPeriod = value!),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade700),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Operations'),
            Tab(icon: Icon(Icons.attach_money), text: 'Financial'),
            Tab(icon: Icon(Icons.speed), text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildOperationsTab(),
          _buildFinancialTab(),
          _buildPerformanceTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // KPI Cards
            _buildKPIGrid(),
            const SizedBox(height: 24),
            
            // Revenue Trend Chart
            _buildChartCard(
              title: 'Revenue Trend',
              subtitle: 'Monthly revenue growth',
              child: _buildRevenueTrendChart(),
            ),
            const SizedBox(height: 24),
            
            // Trip Status Distribution
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    title: 'Trip Status',
                    subtitle: 'Current status distribution',
                    child: _buildTripStatusPieChart(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard(
                    title: 'Route Efficiency',
                    subtitle: 'Performance metrics',
                    child: _buildRouteEfficiencyChart(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Live Activity Feed
            _buildActivityFeed(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid() {
    final kpis = [
      KPIData('Total Revenue', '₹2,45,000', '+12.5%', Colors.green, Icons.trending_up),
      KPIData('Active Trips', '48', '+8', Colors.blue, Icons.local_shipping),
      KPIData('Avg. Delivery Time', '4.2h', '-15min', Colors.orange, Icons.access_time),
      KPIData('Customer Rating', '4.8/5', '+0.2', Colors.purple, Icons.star),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) => _buildKPICard(kpis[index]).animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: 0.2, delay: Duration(milliseconds: 100 * index)),
    );
  }

  Widget _buildKPICard(KPIData kpi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kpi.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kpi.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kpi.change,
                  style: TextStyle(
                    color: kpi.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            kpi.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendChart() {
    final data = [
      ChartData('Jan', 180000),
      ChartData('Feb', 195000),
      ChartData('Mar', 210000),
      ChartData('Apr', 225000),
      ChartData('May', 235000),
      ChartData('Jun', 245000),
    ];

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(color: Colors.grey[200]!),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        numberFormat: const NumberFormat.currency(locale: 'en_IN', symbol: '₹'),
      ),
      series: <ChartSeries>[
        AreaSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.3),
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: Colors.blue,
          borderWidth: 3,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget _buildTripStatusPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 35,
            title: 'Completed\n35%',
            color: Colors.green,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 25,
            title: 'In Transit\n25%',
            color: Colors.blue,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 20,
            title: 'Pending\n20%',
            color: Colors.orange,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: 20,
            title: 'Delayed\n20%',
            color: Colors.red,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildRouteEfficiencyChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const routes = ['R1', 'R2', 'R3', 'R4', 'R5'];
                return Text(
                  routes[value.toInt()],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 85, Colors.blue),
          _makeGroupData(1, 92, Colors.green),
          _makeGroupData(2, 78, Colors.orange),
          _makeGroupData(3, 95, Colors.purple),
          _makeGroupData(4, 88, Colors.teal),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildOperationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChartCard(
          title: 'Daily Trip Volume',
          subtitle: 'Trips completed per day',
          child: _buildDailyTripChart(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                title: 'Vehicle Utilization',
                subtitle: 'Fleet efficiency',
                child: _buildVehicleUtilizationChart(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                title: 'Route Performance',
                subtitle: 'Top performing routes',
                child: _buildRoutePerformanceChart(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                title: 'Profit Margin',
                subtitle: 'Monthly profit trends',
                child: _buildProfitMarginChart(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                title: 'Cost Breakdown',
                subtitle: 'Operational costs',
                child: _buildCostBreakdownChart(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Payment Analytics',
          subtitle: 'Payment status and trends',
          child: _buildPaymentAnalyticsChart(),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChartCard(
          title: 'Delivery Performance',
          subtitle: 'On-time delivery metrics',
          child: _buildDeliveryPerformanceChart(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                title: 'Customer Satisfaction',
                subtitle: 'Rating trends',
                child: _buildCustomerSatisfactionChart(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                title: 'Issue Resolution',
                subtitle: 'Problem tracking',
                child: _buildIssueResolutionChart(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Additional chart implementations would go here...
  Widget _buildDailyTripChart() {
    return const Center(child: Text('Daily Trip Chart'));
  }

  Widget _buildVehicleUtilizationChart() {
    return const Center(child: Text('Vehicle Utilization Chart'));
  }

  Widget _buildRoutePerformanceChart() {
    return const Center(child: Text('Route Performance Chart'));
  }

  Widget _buildProfitMarginChart() {
    return const Center(child: Text('Profit Margin Chart'));
  }

  Widget _buildCostBreakdownChart() {
    return const Center(child: Text('Cost Breakdown Chart'));
  }

  Widget _buildPaymentAnalyticsChart() {
    return const Center(child: Text('Payment Analytics Chart'));
  }

  Widget _buildDeliveryPerformanceChart() {
    return const Center(child: Text('Delivery Performance Chart'));
  }

  Widget _buildCustomerSatisfactionChart() {
    return const Center(child: Text('Customer Satisfaction Chart'));
  }

  Widget _buildIssueResolutionChart() {
    return const Center(child: Text('Issue Resolution Chart'));
  }

  Widget _buildActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Activity Feed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildActivityItem(index)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      ('Trip #TRP001 completed successfully', Icons.check_circle, Colors.green),
      ('New booking received from Client ABC', Icons.add_circle, Colors.blue),
      ('Payment received for Trip #TRP002', Icons.payment, Colors.orange),
      ('Vehicle V001 maintenance scheduled', Icons.build, Colors.red),
      ('Route optimization completed', Icons.route, Colors.purple),
    ];

    final activity = activities[index % activities.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.$3.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.$2, color: activity.$3, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.$1,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            '${index + 1}m ago',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class KPIData {
  final String title;
  final String value;
  final String change;
  final Color color;
  final IconData icon;

  KPIData(this.title, this.value, this.change, this.color, this.icon);
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
} 