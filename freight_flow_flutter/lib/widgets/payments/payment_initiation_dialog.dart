import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/payment.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:intl/intl.dart';

class PaymentInitiationDialog extends ConsumerStatefulWidget {
  final Payment payment;
  final String paymentType; // 'advance' or 'balance'

  const PaymentInitiationDialog({
    super.key,
    required this.payment,
    required this.paymentType,
  });

  @override
  ConsumerState<PaymentInitiationDialog> createState() => _PaymentInitiationDialogState();
}

class _PaymentInitiationDialogState extends ConsumerState<PaymentInitiationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _utrController = TextEditingController();
  String _selectedPaymentMethod = 'NEFT';
  bool _isProcessing = false;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Update payment status using the provider
      final params = (
        id: widget.payment.tripId ?? '',
        advancePaymentStatus: widget.paymentType == 'advance' ? 'Paid' : null,
        balancePaymentStatus: widget.paymentType == 'balance' ? 'Paid' : null,
        utrNumber: _utrController.text,
        paymentMethod: _selectedPaymentMethod,
      );

      // Call the provider to update payment status
      final updatedTrip = await ref.read(updatePaymentStatusProvider(params).future);
      
      // Update trip status based on payment status
      String newStatus = updatedTrip.status;
      
      // If advance payment is made, update trip status to "In Transit"
      if (widget.paymentType == 'advance' && 
          updatedTrip.advancePaymentStatus == 'Paid') {
        newStatus = 'In Transit';
      }
      
      // If balance payment is made and POD is uploaded, update trip status to "Completed"
      if (widget.paymentType == 'balance' && 
          updatedTrip.balancePaymentStatus == 'Paid' &&
          updatedTrip.podUploaded) {
        newStatus = 'Completed';
      }
      
      // If status needs to be updated
      if (newStatus != updatedTrip.status) {
        await ref.read(updateTripProvider((
          updatedTrip.id, 
          {'status': newStatus}
        )).future);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String paymentTypeCapitalized = widget.paymentType[0].toUpperCase() + widget.paymentType.substring(1);
    
    return AlertDialog(
      title: Text('Initiate $paymentTypeCapitalized Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip and payment details
            _buildInfoRow('Trip ID', widget.payment.tripId ?? 'N/A'),
            _buildInfoRow('Supplier', widget.payment.supplierName),
            _buildInfoRow('Amount', '₹${NumberFormat('#,##,###').format(widget.payment.amount ?? 0)}'),
            
            const SizedBox(height: 20),
            
            // Payment method dropdown
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'NEFT', child: Text('NEFT')),
                DropdownMenuItem(value: 'RTGS', child: Text('RTGS')),
                DropdownMenuItem(value: 'IMPS', child: Text('IMPS')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a payment method';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // UTR Number field
            TextFormField(
              controller: _utrController,
              decoration: const InputDecoration(
                labelText: 'UTR Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter UTR number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _initiatePayment,
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Process Payment'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
} 