import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/ultra_fast_service_provider.dart';

class UltraFastPaymentWidget extends ConsumerStatefulWidget {
  final Trip trip;
  final String paymentType; // 'advance' or 'balance'
  final VoidCallback? onPaymentUpdated;

  const UltraFastPaymentWidget({
    super.key,
    required this.trip,
    required this.paymentType,
    this.onPaymentUpdated,
  });

  @override
  ConsumerState<UltraFastPaymentWidget> createState() => _UltraFastPaymentWidgetState();
}

class _UltraFastPaymentWidgetState extends ConsumerState<UltraFastPaymentWidget>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String? _lastProcessingTime;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _currentStatus {
    return widget.paymentType == 'advance'
        ? widget.trip.advancePaymentStatus ?? 'Not Started'
        : widget.trip.balancePaymentStatus ?? 'Not Started';
  }

  double get _paymentAmount {
    return widget.paymentType == 'advance'
        ? widget.trip.advanceSupplierFreight ?? 0
        : widget.trip.balanceSupplierFreight ?? 0;
  }

  String get _nextStatus {
    switch (_currentStatus) {
      case 'Not Started':
        return 'Initiated';
      case 'Initiated':
        return 'Pending';
      case 'Pending':
        return 'Paid';
      default:
        return _currentStatus;
    }
  }

  String get _buttonText {
    if (_isProcessing) {
      return 'Processing...';
    }
    
    switch (_currentStatus) {
      case 'Not Started':
        return 'Initiate Payment';
      case 'Initiated':
        return 'Mark Pending';
      case 'Pending':
        return 'Mark Paid';
      case 'Paid':
        return 'Completed ✓';
      default:
        return 'Update Status';
    }
  }

  Color get _buttonColor {
    if (_isProcessing) {
      return Colors.orange;
    }
    
    switch (_currentStatus) {
      case 'Not Started':
        return Colors.blue;
      case 'Initiated':
        return Colors.orange;
      case 'Pending':
        return Colors.green;
      case 'Paid':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  bool get _canProcess {
    if (_isProcessing || _currentStatus == 'Paid') {
      return false;
    }
    
    // For balance payments, check if advance is paid and POD is uploaded
    if (widget.paymentType == 'balance') {
      return widget.trip.advancePaymentStatus == 'Paid' && 
             (widget.trip.podUploaded ?? false);
    }
    
    return true;
  }

  Future<void> _processPayment() async {
    if (!_canProcess) return;

    setState(() {
      _isProcessing = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Use the ultra-fast payment processor
      await ref.read(ultraFastPaymentProcessor((
        tripId: widget.trip.id!,
        paymentType: widget.paymentType,
        targetStatus: _nextStatus,
        utrNumber: null,
        paymentMethod: null,
      )).future);

      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds;
      
      setState(() {
        _lastProcessingTime = '${processingTime}ms';
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚡ Payment processed in ${processingTime}ms! '
                    '${widget.paymentType == 'advance' ? 'Trip status → In Transit' : 'Trip status → Completed'}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Trigger callback
      widget.onPaymentUpdated?.call();

    } catch (e) {
      stopwatch.stop();
      
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Payment processing failed: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.paymentType == 'advance' 
                      ? Icons.play_arrow 
                      : Icons.check_circle,
                  color: _buttonColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.paymentType == 'advance' ? 'Advance' : 'Balance'} Payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_lastProcessingTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      _lastProcessingTime!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: ₹${_paymentAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _buttonColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status: $_currentStatus',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action button
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SizedBox(
                        width: 120,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _canProcess ? _processPayment : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: _isProcessing ? 0 : 2,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _buttonText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            // Validation messages
            if (!_canProcess && _currentStatus != 'Paid')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.paymentType == 'balance'
                            ? 'Requires advance payment completion and POD upload'
                            : 'Payment processing in progress',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Success indicator for completed payments
            if (_currentStatus == 'Paid')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.paymentType == 'advance'
                            ? 'Trip status updated to "In Transit"'
                            : 'Trip status updated to "Completed"',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
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
  }
}

/// Ultra-fast payment row widget for compact display
class UltraFastPaymentRow extends ConsumerWidget {
  final Trip trip;
  final String paymentType;
  final VoidCallback? onPaymentUpdated;

  const UltraFastPaymentRow({
    super.key,
    required this.trip,
    required this.paymentType,
    this.onPaymentUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = paymentType == 'advance'
        ? trip.advancePaymentStatus ?? 'Not Started'
        : trip.balancePaymentStatus ?? 'Not Started';
    
    final amount = paymentType == 'advance'
        ? trip.advanceSupplierFreight ?? 0
        : trip.balanceSupplierFreight ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Payment type indicator
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: paymentType == 'advance' ? Colors.blue : Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Payment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${paymentType == 'advance' ? 'Advance' : 'Balance'}: ₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Quick action button
          SizedBox(
            width: 80,
            height: 28,
            child: ElevatedButton(
              onPressed: currentStatus == 'Paid' ? null : () async {
                try {
                  await ref.read(oneClickPaymentProvider((
                    tripId: trip.id!,
                    paymentType: paymentType,
                  )).future);
                  
                  onPaymentUpdated?.call();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentStatus == 'Paid' 
                    ? Colors.grey 
                    : (paymentType == 'advance' ? Colors.blue : Colors.green),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                currentStatus == 'Paid' ? '✓' : 'Pay',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 