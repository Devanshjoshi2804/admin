import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:intl/intl.dart';

class AdditionalChargesDialog extends ConsumerStatefulWidget {
  final Trip trip;
  final Function(Trip) onChargesUpdated;

  const AdditionalChargesDialog({
    super.key,
    required this.trip,
    required this.onChargesUpdated,
  });

  @override
  ConsumerState<AdditionalChargesDialog> createState() => _AdditionalChargesDialogState();
}

class _AdditionalChargesDialogState extends ConsumerState<AdditionalChargesDialog> {
  final List<ChargeItem> _additionalCharges = [];
  final List<ChargeItem> _deductionCharges = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCharges();
  }

  void _loadExistingCharges() {
    // Load existing additional charges
    if (widget.trip.additionalCharges != null) {
      for (final charge in widget.trip.additionalCharges!) {
        _additionalCharges.add(ChargeItem(
          description: charge.description,
          amount: charge.amount,
          reason: 'Existing charge', // Default reason for existing charges
        ));
      }
    }

    // Load existing deduction charges
    if (widget.trip.deductionCharges != null) {
      for (final charge in widget.trip.deductionCharges!) {
        _deductionCharges.add(ChargeItem(
          description: charge.description,
          amount: charge.amount,
          reason: 'Existing charge', // Default reason for existing charges
        ));
      }
    }

    // Add default deduction charges with their specific amounts
    final defaultDeductions = [
      {'desc': 'LR Charges', 'amount': widget.trip.lrCharges ?? 0.0},
      {'desc': 'Platform Charges', 'amount': widget.trip.platformFees ?? 0.0},
    ];

    for (final deduction in defaultDeductions) {
      final existingIndex = _deductionCharges.indexWhere(
        (charge) => charge.description == deduction['desc']
      );
      
      if (existingIndex == -1 && (deduction['amount'] as double) > 0) {
        _deductionCharges.add(ChargeItem(
          description: deduction['desc'] as String,
          amount: deduction['amount'] as double,
          reason: 'System default',
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalSupplierFreight = widget.trip.supplierFreight ?? 0.0;
    final advanceAmount = widget.trip.advanceSupplierFreight ?? 0.0;
    final originalBalanceAmount = widget.trip.balanceSupplierFreight ?? 0.0;
    
    final totalAdditionalCharges = _additionalCharges.fold<double>(
      0.0, 
      (sum, charge) => sum + charge.amount
    );
    
    final totalDeductionCharges = _deductionCharges.fold<double>(
      0.0, 
      (sum, charge) => sum + charge.amount
    );
    
    final newBalanceAmount = originalBalanceAmount + totalAdditionalCharges - totalDeductionCharges;
    final newTotalSupplierAmount = advanceAmount + newBalanceAmount;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Additional Charges',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trip: ${widget.trip.orderNumber} - Only affects supplier balance payment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - Charges management
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Additional Charges Section
                          Expanded(
                            child: _buildChargesSection(
                              title: 'Additional Charges (Supplier)',
                              subtitle: 'Extra charges to be added to supplier balance',
                              charges: _additionalCharges,
                              color: Colors.green,
                              icon: Icons.add_circle_outline,
                              isDeduction: false,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Deduction Charges Section
                          Expanded(
                            child: _buildChargesSection(
                              title: 'Deduction Charges (Supplier)',
                              subtitle: 'Charges to be deducted from supplier balance',
                              charges: _deductionCharges,
                              color: Colors.red,
                              icon: Icons.remove_circle_outline,
                              isDeduction: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Right side - Summary
                    Expanded(
                      flex: 2,
                      child: _buildSummarySection(
                        originalSupplierFreight: originalSupplierFreight,
                        advanceAmount: advanceAmount,
                        originalBalanceAmount: originalBalanceAmount,
                        totalAdditionalCharges: totalAdditionalCharges,
                        totalDeductionCharges: totalDeductionCharges,
                        newBalanceAmount: newBalanceAmount,
                        newTotalSupplierAmount: newTotalSupplierAmount,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Balance Payment: ${_formatCurrency(newBalanceAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: newBalanceAmount > originalBalanceAmount 
                          ? Colors.red.shade700 
                          : Colors.green.shade700,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveCharges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargesSection({
    required String title,
    required String subtitle,
    required List<ChargeItem> charges,
    required Color color,
    required IconData icon,
    required bool isDeduction,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDeduction ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addCharge(isDeduction),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeduction ? Colors.red.shade50 : Colors.green.shade50,
                    foregroundColor: isDeduction ? Colors.red.shade700 : Colors.green.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Charges list
            Expanded(
              child: charges.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDeduction ? Icons.money_off : Icons.attach_money,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isDeduction 
                                ? 'No deduction charges added'
                                : 'No additional charges added',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: charges.length,
                      itemBuilder: (context, index) {
                        final charge = charges[index];
                        return _buildChargeItem(charge, index, isDeduction, color);
                      },
                    ),
            ),
            
            // Total
            if (charges.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDeduction ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDeduction ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ${isDeduction ? 'Deductions' : 'Additional'}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDeduction ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      _formatCurrency(charges.fold<double>(0.0, (sum, charge) => sum + charge.amount)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDeduction ? Colors.red.shade700 : Colors.green.shade700,
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

  Widget _buildChargeItem(ChargeItem charge, int index, bool isDeduction, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    charge.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${charge.reason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                _formatCurrency(charge.amount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDeduction ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  if (isDeduction) {
                    _deductionCharges.removeAt(index);
                  } else {
                    _additionalCharges.removeAt(index);
                  }
                });
              },
              icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
              tooltip: 'Remove charge',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection({
    required double originalSupplierFreight,
    required double advanceAmount,
    required double originalBalanceAmount,
    required double totalAdditionalCharges,
    required double totalDeductionCharges,
    required double newBalanceAmount,
    required double newTotalSupplierAmount,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Payment Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Original amounts
            _buildSummaryRow('Original Supplier Freight:', originalSupplierFreight, Colors.grey.shade700),
            _buildSummaryRow('Advance Payment (Paid):', advanceAmount, Colors.green.shade600),
            _buildSummaryRow('Original Balance:', originalBalanceAmount, Colors.grey.shade700),
            
            const Divider(height: 24),
            
            // Adjustments
            if (totalAdditionalCharges > 0)
              _buildSummaryRow('+ Additional Charges:', totalAdditionalCharges, Colors.green.shade600),
            if (totalDeductionCharges > 0)
              _buildSummaryRow('- Deduction Charges:', totalDeductionCharges, Colors.red.shade600),
            
            if (totalAdditionalCharges > 0 || totalDeductionCharges > 0)
              const Divider(height: 24),
            
            // New amounts
            _buildSummaryRow(
              'New Balance Payment:', 
              newBalanceAmount, 
              newBalanceAmount > originalBalanceAmount ? Colors.red.shade700 : Colors.green.shade700,
              isTotal: true,
            ),
            
            const SizedBox(height: 8),
            
            _buildSummaryRow(
              'Total Supplier Payment:', 
              newTotalSupplierAmount, 
              Colors.blue.shade700,
              isTotal: true,
            ),
            
            const SizedBox(height: 16),
            
            // Impact indicator
            if (newBalanceAmount != originalBalanceAmount)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: newBalanceAmount > originalBalanceAmount 
                      ? Colors.red.shade50 
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: newBalanceAmount > originalBalanceAmount 
                        ? Colors.red.shade200 
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          newBalanceAmount > originalBalanceAmount 
                              ? Icons.trending_up 
                              : Icons.trending_down,
                          color: newBalanceAmount > originalBalanceAmount 
                              ? Colors.red.shade600 
                              : Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Impact',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: newBalanceAmount > originalBalanceAmount 
                                ? Colors.red.shade700 
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newBalanceAmount > originalBalanceAmount
                          ? 'Balance payment increased by ${_formatCurrency(newBalanceAmount - originalBalanceAmount)}'
                          : 'Balance payment reduced by ${_formatCurrency(originalBalanceAmount - newBalanceAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: newBalanceAmount > originalBalanceAmount 
                            ? Colors.red.shade600 
                            : Colors.green.shade600,
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

  Widget _buildSummaryRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _addCharge(bool isDeduction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChargeDialog(
          isDeduction: isDeduction,
          onChargeAdded: (ChargeItem charge) {
            setState(() {
              if (isDeduction) {
                _deductionCharges.add(charge);
              } else {
                _additionalCharges.add(charge);
              }
            });
          },
        );
      },
    );
  }

  Future<void> _saveCharges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert ChargeItems to Charge objects
      final additionalCharges = _additionalCharges
          .map((item) => {'description': item.description, 'amount': item.amount})
          .toList();
      
      final deductionCharges = _deductionCharges
          .map((item) => {'description': item.description, 'amount': item.amount})
          .toList();

      // Calculate new balance amount
      final totalAdditionalCharges = _additionalCharges.fold<double>(
        0.0, 
        (sum, charge) => sum + charge.amount
      );
      
      final totalDeductionCharges = _deductionCharges.fold<double>(
        0.0, 
        (sum, charge) => sum + charge.amount
      );

      final originalBalanceAmount = widget.trip.balanceSupplierFreight ?? 0.0;
      final newBalanceAmount = originalBalanceAmount + totalAdditionalCharges - totalDeductionCharges;

      // Update trip with new charges using the dedicated provider
      await ref.read(updateAdditionalChargesProvider((
        tripId: widget.trip.id,
        additionalCharges: additionalCharges,
        deductionCharges: deductionCharges,
        newBalanceAmount: newBalanceAmount,
      )).future);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Additional charges updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent about the update
        widget.onChargesUpdated(widget.trip);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update charges: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }
}

// Helper class for managing charge items with reasons
class ChargeItem {
  final String description;
  final double amount;
  final String reason;

  ChargeItem({
    required this.description,
    required this.amount,
    required this.reason,
  });
}

// Dialog for adding new charges
class AddChargeDialog extends StatefulWidget {
  final bool isDeduction;
  final Function(ChargeItem) onChargeAdded;

  const AddChargeDialog({
    super.key,
    required this.isDeduction,
    required this.onChargeAdded,
  });

  @override
  State<AddChargeDialog> createState() => _AddChargeDialogState();
}

class _AddChargeDialogState extends State<AddChargeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedChargeType;

  final List<String> _additionalChargeTypes = [
    'Fuel Surcharge',
    'Loading/Unloading Charges',
    'Detention Charges',
    'Extra Distance Charges',
    'Special Handling Charges',
    'Insurance Charges',
    'Documentation Charges',
    'Toll Charges',
    'Other'
  ];

  final List<String> _deductionChargeTypes = [
    'LR Charges',
    'Platform Charges',
    'Damage Charges',
    'Late Delivery Penalty',
    'Non-compliance Penalty',
    'Quality Issues',
    'Customer Complaint Charges',
    'Return Freight',
    'Miscellaneous',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final chargeTypes = widget.isDeduction ? _deductionChargeTypes : _additionalChargeTypes;
    
    return AlertDialog(
      title: Text(
        widget.isDeduction ? 'Add Deduction Charge' : 'Add Additional Charge',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Charge type dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Charge Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedChargeType,
                items: chargeTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedChargeType = newValue;
                    if (newValue != 'Other') {
                      _descriptionController.text = newValue ?? '';
                    } else {
                      _descriptionController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a charge type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description field (editable if "Other" is selected)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                enabled: _selectedChargeType == 'Other' || _selectedChargeType == null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Reason field
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Enter reason for this charge',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason for this charge';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addCharge,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDeduction ? Colors.red.shade600 : Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Charge'),
        ),
      ],
    );
  }

  void _addCharge() {
    if (_formKey.currentState!.validate()) {
      final charge = ChargeItem(
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        reason: _reasonController.text.trim(),
      );
      
      widget.onChargeAdded(charge);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
} 