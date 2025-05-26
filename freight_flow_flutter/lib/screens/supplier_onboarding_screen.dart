import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/providers/supplier_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

class SupplierOnboardingScreen extends ConsumerStatefulWidget {
  const SupplierOnboardingScreen({super.key});

  @override
  ConsumerState<SupplierOnboardingScreen> createState() => _SupplierOnboardingScreenState();
}

class _SupplierOnboardingScreenState extends ConsumerState<SupplierOnboardingScreen>
    with TickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Basic Information Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  
  // GST Information
  bool _hasGST = true;
  final _gstNumberController = TextEditingController();
  
  // Identity Documents
  final _aadharNumberController = TextEditingController();
  final _panNumberController = TextEditingController();
  
  // Contact Information
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  
  // Representative Information
  final _repNameController = TextEditingController();
  final _repDesignationController = TextEditingController();
  final _repPhoneController = TextEditingController();
  final _repEmailController = TextEditingController();
  
  // Bank Details
  final _bankNameController = TextEditingController();
  final _accountTypeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ifscController = TextEditingController();
  
  // Service Type
  String _serviceType = 'Full Truck Load (FTL)';
  
  // Document Management
  final Map<String, List<SupplierDocument>> _uploadedDocuments = {};
  
  // Required document types based on GST status
  List<String> get _requiredDocuments {
    if (_hasGST) {
      return [
        'aadhar_card',
        'pan_card',
        'gst_certificate',
        'bank_passbook',
        'cancelled_cheque',
      ];
    } else {
      return [
        'aadhar_card',
        'pan_card',
        'non_gst_declaration',
        'itr_year_1',
        'itr_year_2',
        'itr_year_3',
        'lr_copy',
        'loading_slip',
        'bank_passbook',
        'cancelled_cheque',
      ];
    }
  }
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    // Dispose all controllers
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _gstNumberController.dispose();
    _aadharNumberController.dispose();
    _panNumberController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _repNameController.dispose();
    _repDesignationController.dispose();
    _repPhoneController.dispose();
    _repEmailController.dispose();
    _bankNameController.dispose();
    _accountTypeController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Supplier Onboarding',
      actions: [],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50.withOpacity(0.3),
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildBasicInfoStep(),
                  _buildGSTAndIdentityStep(),
                  _buildContactStep(),
                  _buildBankDetailsStep(),
                  _buildDocumentUploadStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business_rounded, color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supplier Onboarding',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete supplier registration with KYC and documentation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'Basic Info',
      'GST & Identity',
      'Contact Details',
      'Bank Details',
      'Documents',
      'Review'
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive 
                              ? Colors.blue.shade600 
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.green.shade600
                              : isActive 
                                  ? Colors.blue.shade600 
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? Colors.blue.shade600 : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: index < _currentStep 
                        ? Colors.blue.shade600 
                        : Colors.grey.shade300,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return _buildStepContainer(
      title: 'Basic Information',
      icon: Icons.info_rounded,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Supplier Name',
            hint: 'Enter supplier/company name',
            icon: Icons.business_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Supplier name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter complete address',
            icon: Icons.location_on_rounded,
            maxLines: 3,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter city',
                  icon: Icons.location_city_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'Enter state',
                  icon: Icons.map_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _pinCodeController,
                  label: 'PIN Code',
                  hint: 'Enter PIN code',
                  icon: Icons.pin_drop_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'PIN code is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _serviceType,
                  label: 'Service Type',
                  icon: Icons.local_shipping_rounded,
                  items: const [
                    'Full Truck Load (FTL)',
                    'Less Than Truck Load (LTL)',
                    'Container Transport',
                    'Express Delivery',
                    'Specialized Transport',
                  ],
                  onChanged: (value) {
                    setState(() {
                      _serviceType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGSTAndIdentityStep() {
    return _buildStepContainer(
      title: 'GST & Identity Information',
      icon: Icons.verified_user_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GST Status Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GST Registration Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('GST Registered'),
                        subtitle: const Text('Has valid GST registration'),
                        value: true,
                        groupValue: _hasGST,
                        onChanged: (value) {
                          setState(() {
                            _hasGST = value!;
                            if (!_hasGST) {
                              _gstNumberController.clear();
                            }
                          });
                        },
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Non-GST'),
                        subtitle: const Text('Not registered for GST'),
                        value: false,
                        groupValue: _hasGST,
                        onChanged: (value) {
                          setState(() {
                            _hasGST = value!;
                            if (!_hasGST) {
                              _gstNumberController.clear();
                            }
                          });
                        },
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // GST Number (conditional)
          if (_hasGST) ...[
            _buildTextField(
              controller: _gstNumberController,
              label: 'GST Number',
              hint: 'Enter GST number',
              icon: Icons.receipt_long_rounded,
              validator: (value) {
                if (_hasGST && (value?.isEmpty ?? true)) {
                  return 'GST number is required for GST registered suppliers';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Identity Documents
          Text(
            'Identity Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _aadharNumberController,
                  label: 'Aadhar Card Number',
                  hint: 'Enter Aadhar number',
                  icon: Icons.credit_card_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Aadhar number is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _panNumberController,
                  label: 'PAN Card Number',
                  hint: 'Enter PAN number',
                  icon: Icons.account_balance_wallet_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'PAN number is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Document Requirements Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Required Documents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasGST
                      ? 'For GST suppliers: Aadhar Card, PAN Card, GST Certificate, Bank Passbook, Cancelled Cheque'
                      : 'For Non-GST suppliers: Aadhar Card, PAN Card, Non-GST Declaration, ITR (3 years), LR Copy, Loading Slip, Bank Passbook, Cancelled Cheque',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return _buildStepContainer(
      title: 'Contact Information',
      icon: Icons.contacts_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Contact Person',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _contactNameController,
            label: 'Contact Person Name',
            hint: 'Enter contact person name',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Contact person name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _contactPhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _contactEmailController,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Email address is required';
                    }
                    if (!value!.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Representative (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _repNameController,
                  label: 'Representative Name',
                  hint: 'Enter representative name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _repDesignationController,
                  label: 'Designation',
                  hint: 'Enter designation',
                  icon: Icons.work_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _repPhoneController,
                  label: 'Representative Phone',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _repEmailController,
                  label: 'Representative Email',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsStep() {
    return _buildStepContainer(
      title: 'Bank Account Details',
      icon: Icons.account_balance_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'Enter bank name',
                  icon: Icons.account_balance_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Bank name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _accountTypeController.text.isEmpty ? 'Savings' : _accountTypeController.text,
                  label: 'Account Type',
                  icon: Icons.account_box_rounded,
                  items: const ['Savings', 'Current', 'Overdraft'],
                  onChanged: (value) {
                    _accountTypeController.text = value!;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: 'Enter account number',
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Account number is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _ifscController,
                  label: 'IFSC Code',
                  hint: 'Enter IFSC code',
                  icon: Icons.code_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'IFSC code is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _accountHolderController,
            label: 'Account Holder Name',
            hint: 'Enter account holder name as per bank records',
            icon: Icons.person_pin_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Account holder name is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadStep() {
    return _buildStepContainer(
      title: 'Document Upload',
      icon: Icons.upload_file_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Required Documents',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload all required documents. Supported formats: PDF, JPG, PNG (Max 10MB each)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: _requiredDocuments.length,
              itemBuilder: (context, index) {
                final docType = _requiredDocuments[index];
                return _buildDocumentUploadCard(docType);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(String docType) {
    final documents = _uploadedDocuments[docType] ?? [];
    final isUploaded = documents.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? Colors.green.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(docType),
                  color: isUploaded ? Colors.green.shade600 : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDocumentDisplayName(docType),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getDocumentDescription(docType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isUploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _uploadDocument(docType),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(isUploaded ? 'Replace Document' : 'Upload Document'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (isUploaded) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _viewDocument(documents.first),
                  icon: const Icon(Icons.visibility_rounded),
                  tooltip: 'View Document',
                ),
                IconButton(
                  onPressed: () => _removeDocument(docType),
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove Document',
                  color: Colors.red.shade600,
                ),
              ],
            ],
          ),
          
          if (isUploaded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      documents.first.filename,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    documents.first.humanReadableSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepContainer(
      title: 'Review & Submit',
      icon: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary sections
          _buildReviewSection('Basic Information', [
            'Name: ${_nameController.text}',
            'Address: ${_addressController.text}',
            'City: ${_cityController.text}, ${_stateController.text} - ${_pinCodeController.text}',
            'Service Type: $_serviceType',
          ]),
          
          _buildReviewSection('GST & Identity', [
            'GST Status: ${_hasGST ? "GST Registered" : "Non-GST"}',
            if (_hasGST) 'GST Number: ${_gstNumberController.text}',
            'Aadhar Number: ${_aadharNumberController.text}',
            'PAN Number: ${_panNumberController.text}',
          ]),
          
          _buildReviewSection('Contact Information', [
            'Contact Person: ${_contactNameController.text}',
            'Phone: ${_contactPhoneController.text}',
            'Email: ${_contactEmailController.text}',
            if (_repNameController.text.isNotEmpty)
              'Representative: ${_repNameController.text}',
          ]),
          
          _buildReviewSection('Bank Details', [
            'Bank: ${_bankNameController.text}',
            'Account Type: ${_accountTypeController.text}',
            'Account Number: ${_accountNumberController.text}',
            'IFSC Code: ${_ifscController.text}',
            'Account Holder: ${_accountHolderController.text}',
          ]),
          
          _buildReviewSection('Documents', [
            '${_uploadedDocuments.length} of ${_requiredDocuments.length} required documents uploaded',
            ...(_uploadedDocuments.keys.map((type) => '✓ ${_getDocumentDisplayName(type)}')),
          ]),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All required information and documents have been provided. Click Submit to complete the onboarding process.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(_slideController),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.blue.shade600, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : (_currentStep == 5 ? _submitForm : _nextStep),
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_currentStep == 5 ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(_currentStep == 5 ? 'Submit' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 5) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        if (_nameController.text.isEmpty) {
          _showSnackBar('Please enter supplier name', Colors.red);
          return false;
        }
        if (_addressController.text.isEmpty) {
          _showSnackBar('Please enter address', Colors.red);
          return false;
        }
        if (_cityController.text.isEmpty) {
          _showSnackBar('Please enter city', Colors.red);
          return false;
        }
        if (_stateController.text.isEmpty) {
          _showSnackBar('Please enter state', Colors.red);
          return false;
        }
        if (_pinCodeController.text.isEmpty) {
          _showSnackBar('Please enter PIN code', Colors.red);
          return false;
        }
        return true;
        
      case 1: // GST & Identity
        if (_hasGST && _gstNumberController.text.isEmpty) {
          _showSnackBar('Please enter GST number for GST registered suppliers', Colors.red);
          return false;
        }
        if (_aadharNumberController.text.isEmpty) {
          _showSnackBar('Please enter Aadhar number', Colors.red);
          return false;
        }
        if (_panNumberController.text.isEmpty) {
          _showSnackBar('Please enter PAN number', Colors.red);
          return false;
        }
        return true;
        
      case 2: // Contact
        if (_contactNameController.text.isEmpty) {
          _showSnackBar('Please enter contact person name', Colors.red);
          return false;
        }
        if (_contactPhoneController.text.isEmpty) {
          _showSnackBar('Please enter phone number', Colors.red);
          return false;
        }
        if (!_contactEmailController.text.contains('@')) {
          _showSnackBar('Please enter a valid email address', Colors.red);
          return false;
        }
        return true;
        
      case 3: // Bank Details
        if (_bankNameController.text.isEmpty) {
          _showSnackBar('Please enter bank name', Colors.red);
          return false;
        }
        if (_accountNumberController.text.isEmpty) {
          _showSnackBar('Please enter account number', Colors.red);
          return false;
        }
        if (_ifscController.text.isEmpty) {
          _showSnackBar('Please enter IFSC code', Colors.red);
          return false;
        }
        if (_accountHolderController.text.isEmpty) {
          _showSnackBar('Please enter account holder name', Colors.red);
          return false;
        }
        return true;
        
      case 4: // Documents
        // Documents are now optional - no validation required
        return true;
        
      case 5: // Review
        return true;
        
      default:
        return true;
    }
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create supplier object
      final supplier = Supplier(
        id: 'SP${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pinCode: _pinCodeController.text,
        hasGST: _hasGST,
        gstNumber: _hasGST ? _gstNumberController.text : '',
        aadharCardNumber: _aadharNumberController.text,
        panCardNumber: _panNumberController.text,
        contactName: _contactNameController.text,
        contactPhone: _contactPhoneController.text,
        contactEmail: _contactEmailController.text,
        representativeName: _repNameController.text.isNotEmpty ? _repNameController.text : null,
        representativeDesignation: _repDesignationController.text.isNotEmpty ? _repDesignationController.text : null,
        representativePhone: _repPhoneController.text.isNotEmpty ? _repPhoneController.text : null,
        representativeEmail: _repEmailController.text.isNotEmpty ? _repEmailController.text : null,
        bankName: _bankNameController.text,
        accountType: _accountTypeController.text,
        accountNumber: _accountNumberController.text,
        accountHolderName: _accountHolderController.text,
        ifscCode: _ifscController.text,
        serviceType: _serviceType,
        documents: _uploadedDocuments.values.expand((docs) => docs).toList(),
        isActive: true,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      // Submit to API
      await ref.read(supplierNotifierProvider.notifier).createSupplier(supplier);

      _showSnackBar('Supplier onboarded successfully!', Colors.green);
      
      // Navigate to supplier management page
      if (mounted) {
        context.go('/suppliers');
      }
    } catch (e) {
      _showSnackBar('Error submitting supplier: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadDocument(String docType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) return;

        // Create document object
        final document = SupplierDocument(
          type: docType,
          url: 'temp_url', // Will be updated after upload
          filename: file.name,
          originalName: file.name,
          mimeType: _getMimeType(file.extension ?? ''),
          size: file.size,
          number: _getDocumentNumber(docType),
          year: _getDocumentYear(docType),
          uploadedAt: DateTime.now(),
        );

        setState(() {
          _uploadedDocuments[docType] = [document];
        });

        _showSnackBar('Document uploaded successfully', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error uploading document: $e', Colors.red);
    }
  }

  void _viewDocument(SupplierDocument document) {
    _showSnackBar('Document viewing functionality will be implemented', Colors.blue);
  }

  void _removeDocument(String docType) {
    setState(() {
      _uploadedDocuments.remove(docType);
    });
    _showSnackBar('Document removed', Colors.orange);
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  String? _getDocumentNumber(String docType) {
    switch (docType) {
      case 'aadhar_card':
        return _aadharNumberController.text;
      case 'pan_card':
        return _panNumberController.text;
      case 'gst_certificate':
        return _gstNumberController.text;
      default:
        return null;
    }
  }

  int? _getDocumentYear(String docType) {
    switch (docType) {
      case 'itr_year_1':
        return DateTime.now().year - 1;
      case 'itr_year_2':
        return DateTime.now().year - 2;
      case 'itr_year_3':
        return DateTime.now().year - 3;
      default:
        return null;
    }
  }

  IconData _getDocumentIcon(String docType) {
    switch (docType) {
      case 'aadhar_card':
        return Icons.credit_card_rounded;
      case 'pan_card':
        return Icons.account_balance_wallet_rounded;
      case 'gst_certificate':
        return Icons.receipt_long_rounded;
      case 'non_gst_declaration':
        return Icons.description_rounded;
      case 'itr_year_1':
      case 'itr_year_2':
      case 'itr_year_3':
        return Icons.assessment_rounded;
      case 'lr_copy':
        return Icons.local_shipping_rounded;
      case 'loading_slip':
        return Icons.inventory_2_rounded;
      case 'bank_passbook':
        return Icons.account_balance_rounded;
      case 'cancelled_cheque':
        return Icons.payment_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getDocumentDisplayName(String docType) {
    switch (docType) {
      case 'aadhar_card':
        return 'Aadhar Card';
      case 'pan_card':
        return 'PAN Card';
      case 'gst_certificate':
        return 'GST Certificate';
      case 'non_gst_declaration':
        return 'Non-GST Declaration Form';
      case 'itr_year_1':
        return 'ITR - Year 1';
      case 'itr_year_2':
        return 'ITR - Year 2';
      case 'itr_year_3':
        return 'ITR - Year 3';
      case 'lr_copy':
        return 'LR Copy';
      case 'loading_slip':
        return 'Loading Slip';
      case 'bank_passbook':
        return 'Bank Passbook';
      case 'cancelled_cheque':
        return 'Cancelled Cheque';
      default:
        return 'Other Document';
    }
  }

  String _getDocumentDescription(String docType) {
    switch (docType) {
      case 'aadhar_card':
        return 'Government issued identity proof';
      case 'pan_card':
        return 'Permanent Account Number card';
      case 'gst_certificate':
        return 'GST registration certificate';
      case 'non_gst_declaration':
        return 'Declaration for non-GST registration';
      case 'itr_year_1':
        return 'Income Tax Return - Previous year';
      case 'itr_year_2':
        return 'Income Tax Return - 2 years ago';
      case 'itr_year_3':
        return 'Income Tax Return - 3 years ago';
      case 'lr_copy':
        return 'Lorry Receipt copy for reference';
      case 'loading_slip':
        return 'Loading/unloading slip';
      case 'bank_passbook':
        return 'Bank account passbook copy';
      case 'cancelled_cheque':
        return 'Cancelled cheque for account verification';
      default:
        return 'Additional supporting document';
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 