class PaymentParams {
  final String id;
  final String paymentType;
  final String paymentStatus;
  final String? utrNumber;
  final String? paymentMethod;
  
  PaymentParams({
    required this.id,
    required this.paymentType,
    required this.paymentStatus,
    this.utrNumber,
    this.paymentMethod,
  });
} 