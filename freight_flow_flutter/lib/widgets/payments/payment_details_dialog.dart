import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/models/payment.dart';
import 'package:intl/intl.dart';

class PaymentDetailsDialog extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsDialog({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Details - ${payment.orderId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Order and Trip Details
            _buildSectionHeader('Order and Trip Details'),
            const SizedBox(height: 12),
            _buildDetailsGrid([
              DetailItem(label: 'Order ID', value: payment.orderId),
              DetailItem(label: 'LR Number', value: payment.lrNumber),
              DetailItem(label: 'Trip Date', value: payment.tripDate != null 
                ? DateFormat('dd MMM yyyy').format(payment.tripDate!) 
                : 'N/A'),
              DetailItem(label: 'Trip Status', value: payment.tripStatus ?? 'N/A'),
              DetailItem(label: 'POD Date', value: payment.podDate != null 
                ? DateFormat('dd MMM yyyy').format(payment.podDate!) 
                : 'N/A'),
              DetailItem(label: 'POD Status', value: 'Received'),
            ]),
            const SizedBox(height: 24),
            
            // Supplier Details
            _buildSectionHeader('Supplier Details'),
            const SizedBox(height: 12),
            _buildDetailsGrid([
              DetailItem(label: 'Supplier ID', value: payment.supplierId ?? 'N/A'),
              DetailItem(label: 'Supplier Name', value: payment.supplierName),
              DetailItem(label: 'Account Number', value: '123456789012'),
              DetailItem(label: 'Bank Name', value: 'HDFC Bank'),
              DetailItem(label: 'IFSC Code', value: 'HDFC0001234'),
              DetailItem(label: 'Account Holder', value: payment.supplierName),
            ]),
            const SizedBox(height: 24),
            
            // Payment Details
            _buildSectionHeader('Payment Details'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentCard(
                    'Advance Payment',
                    '₹${payment.advanceAmount?.toStringAsFixed(0) ?? '0'}',
                    '${payment.percentOfTotal?.toStringAsFixed(1) ?? '0.0'}% of total',
                    payment.advanceStatus ?? 'Not Started',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPaymentCard(
                    'Balance Payment',
                    '₹${payment.balanceAmount?.toStringAsFixed(0) ?? '0'}',
                    '${(100 - (payment.percentOfTotal ?? 0)).toStringAsFixed(1)}% of total',
                    payment.balanceStatus ?? 'Not Started',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPaymentCard(
                    'Total Amount',
                    '₹${payment.totalAmount?.toStringAsFixed(0) ?? '0'}',
                    '100% of total',
                    'Total',
                    isTotal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Documents'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payment),
                  label: const Text('Process Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid(List<DetailItem> items) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: items.map((item) => _buildDetailItem(item)).toList(),
    );
  }

  Widget _buildDetailItem(DetailItem item) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    String title,
    String amount,
    String percentage,
    String status, {
    bool isTotal = false,
  }) {
    Color statusColor;
    Color bgColor;
    
    if (isTotal) {
      statusColor = Colors.blue;
      bgColor = Colors.blue.withAlpha(25);
    } else if (status == 'Paid') {
      statusColor = Colors.green;
      bgColor = Colors.green.withAlpha(25);
    } else if (status == 'Initiated') {
      statusColor = Colors.orange;
      bgColor = Colors.orange.withAlpha(25);
    } else {
      statusColor = Colors.grey;
      bgColor = Colors.grey.withAlpha(25);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (!isTotal)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DetailItem {
  final String label;
  final String value;

  DetailItem({
    required this.label,
    required this.value,
  });
} 