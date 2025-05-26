import 'package:flutter/material.dart';

class PaymentDetailScreen extends StatelessWidget {
  final String tripId;
  
  const PaymentDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Payment Details for Trip $tripId - To be implemented'),
    );
  }
} 