import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:intl/intl.dart';

class PaymentSummaryCards extends StatelessWidget {
  final List<Trip> trips;

  const PaymentSummaryCards({
    super.key,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate payment statistics
    final stats = _calculatePaymentStats(trips);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pending Advances',
                  amount: stats['pendingAdvanceAmount'],
                  count: stats['pendingAdvanceCount'],
                  color: Colors.blue,
                  icon: Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pending Balances',
                  amount: stats['pendingBalanceAmount'],
                  count: stats['pendingBalanceCount'],
                  color: Colors.orange,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Payments Made Today',
                  amount: stats['todayPaymentAmount'],
                  count: stats['todayPaymentCount'],
                  color: Colors.green,
                  icon: Icons.payments,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Payments This Month',
                  amount: stats['monthlyPaymentAmount'],
                  count: stats['monthlyPaymentCount'],
                  color: Colors.purple,
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count payments',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculatePaymentStats(List<Trip> trips) {
    // Initialize stats
    double pendingAdvanceAmount = 0;
    int pendingAdvanceCount = 0;
    double pendingBalanceAmount = 0;
    int pendingBalanceCount = 0;
    double todayPaymentAmount = 0;
    int todayPaymentCount = 0;
    double monthlyPaymentAmount = 0;
    int monthlyPaymentCount = 0;
    
    // Get today's date and first day of month
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // Process each trip
    for (final trip in trips) {
      // Pending advance payments
      if (trip.advanceSupplierFreight != null && 
          trip.advanceSupplierFreight! > 0 &&
          (trip.advancePaymentStatus == null || 
           trip.advancePaymentStatus == 'Pending' || 
           trip.advancePaymentStatus == 'Initiated')) {
        pendingAdvanceAmount += trip.advanceSupplierFreight!;
        pendingAdvanceCount++;
      }
      
      // Pending balance payments
      if (trip.balanceSupplierFreight != null && 
          trip.balanceSupplierFreight! > 0 &&
          (trip.balancePaymentStatus == null || 
           trip.balancePaymentStatus == 'Pending' || 
           trip.balancePaymentStatus == 'Initiated')) {
        pendingBalanceAmount += trip.balanceSupplierFreight!;
        pendingBalanceCount++;
      }
      
      // Payments made today
      if (trip.updatedAt != null && 
          trip.updatedAt!.isAfter(today) &&
          (trip.advancePaymentStatus == 'Paid' || trip.balancePaymentStatus == 'Paid')) {
        if (trip.advancePaymentStatus == 'Paid' && trip.advanceSupplierFreight != null) {
          todayPaymentAmount += trip.advanceSupplierFreight!;
          todayPaymentCount++;
        }
        if (trip.balancePaymentStatus == 'Paid' && trip.balanceSupplierFreight != null) {
          todayPaymentAmount += trip.balanceSupplierFreight!;
          todayPaymentCount++;
        }
      }
      
      // Payments made this month
      if (trip.updatedAt != null && 
          trip.updatedAt!.isAfter(firstDayOfMonth) &&
          (trip.advancePaymentStatus == 'Paid' || trip.balancePaymentStatus == 'Paid')) {
        if (trip.advancePaymentStatus == 'Paid' && trip.advanceSupplierFreight != null) {
          monthlyPaymentAmount += trip.advanceSupplierFreight!;
          monthlyPaymentCount++;
        }
        if (trip.balancePaymentStatus == 'Paid' && trip.balanceSupplierFreight != null) {
          monthlyPaymentAmount += trip.balanceSupplierFreight!;
          monthlyPaymentCount++;
        }
      }
    }
    
    return {
      'pendingAdvanceAmount': pendingAdvanceAmount,
      'pendingAdvanceCount': pendingAdvanceCount,
      'pendingBalanceAmount': pendingBalanceAmount,
      'pendingBalanceCount': pendingBalanceCount,
      'todayPaymentAmount': todayPaymentAmount,
      'todayPaymentCount': todayPaymentCount,
      'monthlyPaymentAmount': monthlyPaymentAmount,
      'monthlyPaymentCount': monthlyPaymentCount,
    };
  }
} 