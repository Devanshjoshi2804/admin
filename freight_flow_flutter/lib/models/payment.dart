import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String? tripId;
  final String orderId;
  final String lrNumber;
  final String? supplierId;
  final String supplierName;
  final String? clientId;
  final String? clientName;
  final double? advanceAmount;
  final double? balanceAmount;
  final String? advanceStatus;
  final String? balanceStatus;
  final String? tripStatus;
  final DateTime? podDate;
  final DateTime? tripDate;
  final double? totalAmount;
  final double? percentOfTotal;
  final bool? isPaid;
  final bool? isInitiated;
  final double? amount;
  final String? status;
  final DateTime? paymentDate;
  final String? utrNumber;
  final String? paymentMethod;

  Payment({
    required this.id,
    this.tripId,
    required this.orderId,
    required this.lrNumber,
    this.supplierId,
    required this.supplierName,
    this.clientId,
    this.clientName,
    this.advanceAmount,
    this.balanceAmount,
    this.advanceStatus,
    this.balanceStatus,
    this.tripStatus,
    this.podDate,
    this.tripDate,
    this.totalAmount,
    this.percentOfTotal,
    this.isPaid,
    this.isInitiated,
    this.amount,
    this.status,
    this.paymentDate,
    this.utrNumber,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [
    id, tripId, orderId, lrNumber, supplierId, supplierName, 
    clientId, clientName, advanceAmount, balanceAmount,
    advanceStatus, balanceStatus, tripStatus, podDate, tripDate,
    totalAmount, percentOfTotal, isPaid, isInitiated,
    amount, status, paymentDate, utrNumber, paymentMethod
  ];

  // Sample data for balance payments
  static List<Payment> getSampleBalancePayments() {
    return [
      Payment(
        id: 'PAY001',
        tripId: 'TRIP001',
        orderId: 'FTL-20250420-001',
        lrNumber: 'LR12345678',
        supplierId: 'SUP001',
        supplierName: 'Logistics Pro Carriers',
        clientId: 'CLI001',
        clientName: 'Tech Solutions Ltd',
        advanceAmount: 15000,
        balanceAmount: 35000,
        advanceStatus: 'Paid',
        balanceStatus: 'Not Started',
        tripStatus: 'Completed',
        podDate: DateTime.now().subtract(const Duration(days: 2)),
        tripDate: DateTime.now().subtract(const Duration(days: 5)),
        totalAmount: 50000,
        percentOfTotal: 30,
        isPaid: false,
        isInitiated: false,
        amount: 35000,
        status: 'Not Started',
      ),
      Payment(
        id: 'PAY002',
        tripId: 'TRIP002',
        orderId: 'FTL-20250420-002',
        lrNumber: 'LR12345679',
        supplierId: 'SUP002',
        supplierName: 'Fast Track Logistics',
        clientId: 'CLI002',
        clientName: 'Global Traders Inc',
        advanceAmount: 12000,
        balanceAmount: 28000,
        advanceStatus: 'Paid',
        balanceStatus: 'Not Started',
        tripStatus: 'Completed',
        podDate: DateTime.now().subtract(const Duration(days: 3)),
        tripDate: DateTime.now().subtract(const Duration(days: 7)),
        totalAmount: 40000,
        percentOfTotal: 30,
        isPaid: false,
        isInitiated: false,
        amount: 28000,
        status: 'Not Started',
      ),
    ];
  }

  // Sample data for advance payments
  static List<Payment> getSampleAdvancePayments() {
    return [
      Payment(
        id: 'PAY003',
        tripId: 'TRIP003',
        orderId: 'FTL-20250420-003',
        lrNumber: 'LR12345680',
        supplierId: 'SUP003',
        supplierName: 'Express Freight Services',
        clientId: 'CLI003',
        clientName: 'Retail Distributors Ltd',
        advanceAmount: 18000,
        balanceAmount: 42000,
        advanceStatus: 'Not Started',
        balanceStatus: 'Not Started',
        tripStatus: 'Scheduled',
        podDate: DateTime.now().add(const Duration(days: 7)),
        tripDate: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 60000,
        percentOfTotal: 30,
        isPaid: false,
        isInitiated: false,
        amount: 18000,
        status: 'Not Started',
      ),
      Payment(
        id: 'PAY004',
        tripId: 'TRIP004',
        orderId: 'FTL-20250420-004',
        lrNumber: 'LR12345681',
        supplierId: 'SUP004',
        supplierName: 'Highway Carriers',
        clientId: 'CLI004',
        clientName: 'Manufacturing Solutions',
        advanceAmount: 15000,
        balanceAmount: 35000,
        advanceStatus: 'Not Started',
        balanceStatus: 'Not Started',
        tripStatus: 'Scheduled',
        podDate: DateTime.now().add(const Duration(days: 8)),
        tripDate: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 50000,
        percentOfTotal: 30,
        isPaid: false,
        isInitiated: false,
        amount: 15000,
        status: 'Not Started',
      ),
    ];
  }

  // Sample data for payment history
  static List<Payment> getSamplePaymentHistory() {
    return [
      Payment(
        id: 'PAY005',
        tripId: 'TRIP005',
        orderId: 'FTL-20250419-001',
        lrNumber: 'LR12345670',
        supplierId: 'SUP005',
        supplierName: 'Prime Logistics',
        clientId: 'CLI005',
        clientName: 'Consumer Goods Ltd',
        advanceAmount: 12000,
        balanceAmount: 28000,
        advanceStatus: 'Paid',
        balanceStatus: 'Not Started',
        tripStatus: 'In Transit',
        podDate: DateTime.now().add(const Duration(days: 3)),
        tripDate: DateTime.now().subtract(const Duration(days: 1)),
        totalAmount: 40000,
        percentOfTotal: 30,
        isPaid: true,
        isInitiated: true,
        amount: 12000,
        status: 'Paid',
        paymentDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Payment(
        id: 'PAY006',
        tripId: 'TRIP006',
        orderId: 'FTL-20250419-002',
        lrNumber: 'LR12345671',
        supplierId: 'SUP006',
        supplierName: 'Speedy Transport',
        clientId: 'CLI006',
        clientName: 'Pharma Distributors',
        advanceAmount: 15000,
        balanceAmount: 35000,
        advanceStatus: 'Paid',
        balanceStatus: 'Not Started',
        tripStatus: 'In Transit',
        podDate: DateTime.now().add(const Duration(days: 4)),
        tripDate: DateTime.now().subtract(const Duration(days: 2)),
        totalAmount: 50000,
        percentOfTotal: 30,
        isPaid: true,
        isInitiated: true,
        amount: 15000,
        status: 'Paid',
        paymentDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
} 