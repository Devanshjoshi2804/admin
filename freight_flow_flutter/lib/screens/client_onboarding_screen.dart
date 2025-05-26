import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:freight_flow_flutter/providers/client_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

class ClientOnboardingScreen extends ConsumerStatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  ConsumerState<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends ConsumerState<ClientOnboardingScreen>
    with TickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Basic Information Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressTypeController = TextEditingController();
  String _invoicingType = 'GST';
  final _gstNumberController = TextEditingController();
  final _panNumberController = TextEditingController();
  
  // Logistics Point of Contact
  final _logisticsNameController = TextEditingController();
  final _logisticsPhoneController = TextEditingController();
  final _logisticsEmailController = TextEditingController();
  
  // Finance Point of Contact
  final _financeNameController = TextEditingController();
  final _financePhoneController = TextEditingController();
  final _financeEmailController = TextEditingController();
  
  // Sales Representative
  final _salesRepNameController = TextEditingController();
  final _salesRepDesignationController = TextEditingController();
  final _salesRepPhoneController = TextEditingController();
  final _salesRepEmailController = TextEditingController();
  
  // Document Management
  final Map<String, List<PlatformFile>> _uploadedDocuments = {};
  
  // Required document types
  List<String> get _requiredDocuments {
    return [
      'gst_certificate',
      'pan_card',
      'cancelled_cheque',
      'msme_certificate',
      'client_onboarding_form',
    ];
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
    _addressTypeController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    _logisticsNameController.dispose();
    _logisticsPhoneController.dispose();
    _logisticsEmailController.dispose();
    _financeNameController.dispose();
    _financePhoneController.dispose();
    _financeEmailController.dispose();
    _salesRepNameController.dispose();
    _salesRepDesignationController.dispose();
    _salesRepPhoneController.dispose();
    _salesRepEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Client Onboarding',
      actions: [],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50.withOpacity(0.3),
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
                  _buildContactsStep(),
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business_rounded, color: Colors.green.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Onboarding',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete client registration with comprehensive information and documentation',
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
      'Contacts',
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
                              ? Colors.green.shade600 
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
                                  ? Colors.green.shade600 
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
                          color: isActive ? Colors.green.shade600 : Colors.grey[600],
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
                        ? Colors.green.shade600 
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
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nameController,
                  label: 'Client Name',
                  hint: 'Enter client/company name',
                  icon: Icons.business_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Client name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
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
            ],
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
                  controller: _addressTypeController,
                  label: 'Address Type',
                  hint: 'E.g., Head Office, Factory, Warehouse',
                  icon: Icons.home_work_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Address type is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _invoicingType,
                  label: 'Invoicing Type',
                  hint: 'Select invoicing type',
                  icon: Icons.receipt_long_rounded,
                  items: const [
                    'GST',
                    'Non-GST',
                    'International',
                    'Digital',
                    'Physical',
                  ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _invoicingType = value!;
                    });
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
                  controller: _gstNumberController,
                  label: 'GST Number',
                  hint: 'Enter GST number',
                  icon: Icons.receipt_rounded,
                  validator: (value) {
                    if (_invoicingType == 'GST' && (value?.isEmpty ?? true)) {
                      return 'GST number is required for GST invoicing';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _panNumberController,
                  label: 'PAN Number',
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
        ],
      ),
    );
  }

  Widget _buildContactsStep() {
    return _buildStepContainer(
      title: 'Contact Information',
      icon: Icons.contacts_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logistics Point of Contact
          Text(
            'Logistics Point of Contact',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _logisticsNameController,
            label: 'Name',
            hint: 'Enter contact person name',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Logistics contact name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _logisticsPhoneController,
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
                  controller: _logisticsEmailController,
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
          
          // Finance Point of Contact
          Text(
            'Finance Point of Contact',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _financeNameController,
            label: 'Name',
            hint: 'Enter contact person name',
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Finance contact name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _financePhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
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
                  controller: _financeEmailController,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
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
          
          // Sales Representative
          Text(
            'Sales Representative',
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
                  controller: _salesRepNameController,
                  label: 'Name',
                  hint: 'Enter representative name',
                  icon: Icons.work_outline_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Sales representative name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _salesRepDesignationController,
                  label: 'Designation',
                  hint: 'Enter designation',
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Designation is required';
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
                  controller: _salesRepPhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone_in_talk_outlined,
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
                  controller: _salesRepEmailController,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.mark_email_read_outlined,
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Required Documents',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload all required documents. Supported formats: PDF, JPG, PNG (Max 10MB each)',
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
                      documents.first.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _getFileSize(documents.first.size),
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
            'Client Name: ${_nameController.text}',
            'Address: ${_addressController.text}',
            'City: ${_cityController.text}',
            'Address Type: ${_addressTypeController.text}',
            'Invoicing Type: $_invoicingType',
            'GST Number: ${_gstNumberController.text}',
            'PAN Number: ${_panNumberController.text}',
          ]),
          
          _buildReviewSection('Contact Information', [
            'Logistics POC: ${_logisticsNameController.text}',
            'Logistics Phone: ${_logisticsPhoneController.text}',
            'Logistics Email: ${_logisticsEmailController.text}',
            'Finance POC: ${_financeNameController.text}',
            'Finance Phone: ${_financePhoneController.text}',
            'Finance Email: ${_financeEmailController.text}',
            'Sales Rep: ${_salesRepNameController.text}',
            'Sales Rep Designation: ${_salesRepDesignationController.text}',
            'Sales Rep Phone: ${_salesRepPhoneController.text}',
            'Sales Rep Email: ${_salesRepEmailController.text}',
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
                        'All required information and documents have been provided. Click Submit to complete the client onboarding.',
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.green.shade600, size: 20),
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
          borderSide: BorderSide(color: Colors.green.shade600),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
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
          borderSide: BorderSide(color: Colors.green.shade600),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildNavigationButtons() {
    final isCurrentStepValid = _isCurrentStepValid();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Validation status indicator
          if (!isCurrentStepValid && _currentStep < 3)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please fill in all required fields to continue',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
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
                  onPressed: _isLoading ? null : (_currentStep == 3 ? _submitForm : (isCurrentStepValid ? _nextStep : null)),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_currentStep == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                  label: Text(_currentStep == 3 ? 'Submit' : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isCurrentStepValid || _currentStep == 3) ? Colors.green.shade600 : Colors.grey.shade400,
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
        ],
      ),
    );
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _nameController.text.trim().isNotEmpty &&
               _cityController.text.trim().isNotEmpty &&
               _addressController.text.trim().isNotEmpty &&
               _addressTypeController.text.trim().isNotEmpty &&
               _panNumberController.text.trim().isNotEmpty &&
               (_invoicingType != 'GST' || _gstNumberController.text.trim().isNotEmpty);
      case 1: // Contacts
        // Debug logging to see what's happening
        print('=== CONTACTS VALIDATION DEBUG ===');
        print('Logistics name: "${_logisticsNameController.text}" (${_logisticsNameController.text.length} chars)');
        print('Logistics phone: "${_logisticsPhoneController.text}" (${_logisticsPhoneController.text.length} chars)');
        print('Logistics email: "${_logisticsEmailController.text}" (${_logisticsEmailController.text.length} chars)');
        print('Finance name: "${_financeNameController.text}" (${_financeNameController.text.length} chars)');
        print('Finance phone: "${_financePhoneController.text}" (${_financePhoneController.text.length} chars)');
        print('Finance email: "${_financeEmailController.text}" (${_financeEmailController.text.length} chars)');
        print('Sales name: "${_salesRepNameController.text}" (${_salesRepNameController.text.length} chars)');
        print('Sales designation: "${_salesRepDesignationController.text}" (${_salesRepDesignationController.text.length} chars)');
        print('Sales phone: "${_salesRepPhoneController.text}" (${_salesRepPhoneController.text.length} chars)');
        print('Sales email: "${_salesRepEmailController.text}" (${_salesRepEmailController.text.length} chars)');
        
        bool isValid = _logisticsNameController.text.trim().isNotEmpty &&
               _logisticsPhoneController.text.trim().isNotEmpty &&
               _logisticsEmailController.text.trim().contains('@') &&
               _financeNameController.text.trim().isNotEmpty &&
               _financePhoneController.text.trim().isNotEmpty &&
               _financeEmailController.text.trim().contains('@') &&
               _salesRepNameController.text.trim().isNotEmpty &&
               _salesRepDesignationController.text.trim().isNotEmpty &&
               _salesRepPhoneController.text.trim().isNotEmpty &&
               _salesRepEmailController.text.trim().contains('@');
        
        print('Validation result: $isValid');
        print('=== END DEBUG ===');
        return isValid;
      case 2: // Documents
        return true;
      case 3: // Review
        return true;
      default:
        return true;
    }
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
      if (_currentStep < 3) {
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
        if (_nameController.text.trim().isEmpty) {
          _showSnackBar('Please enter client name', Colors.red);
          return false;
        }
        if (_cityController.text.trim().isEmpty) {
          _showSnackBar('Please enter city', Colors.red);
          return false;
        }
        if (_addressController.text.trim().isEmpty) {
          _showSnackBar('Please enter address', Colors.red);
          return false;
        }
        if (_addressTypeController.text.trim().isEmpty) {
          _showSnackBar('Please enter address type', Colors.red);
          return false;
        }
        if (_panNumberController.text.trim().isEmpty) {
          _showSnackBar('Please enter PAN number', Colors.red);
          return false;
        }
        if (_invoicingType == 'GST' && _gstNumberController.text.trim().isEmpty) {
          _showSnackBar('Please enter GST number for GST invoicing', Colors.red);
          return false;
        }
        return true;
        
      case 1: // Contacts
        if (_logisticsNameController.text.trim().isEmpty) {
          _showSnackBar('Please enter logistics contact name', Colors.red);
          return false;
        }
        if (_logisticsPhoneController.text.trim().isEmpty) {
          _showSnackBar('Please enter logistics phone number', Colors.red);
          return false;
        }
        if (!_logisticsEmailController.text.trim().contains('@')) {
          _showSnackBar('Please enter a valid logistics email address', Colors.red);
          return false;
        }
        if (_financeNameController.text.trim().isEmpty) {
          _showSnackBar('Please enter finance contact name', Colors.red);
          return false;
        }
        if (_financePhoneController.text.trim().isEmpty) {
          _showSnackBar('Please enter finance phone number', Colors.red);
          return false;
        }
        if (!_financeEmailController.text.trim().contains('@')) {
          _showSnackBar('Please enter a valid finance email address', Colors.red);
          return false;
        }
        if (_salesRepNameController.text.trim().isEmpty) {
          _showSnackBar('Please enter sales representative name', Colors.red);
          return false;
        }
        if (_salesRepDesignationController.text.trim().isEmpty) {
          _showSnackBar('Please enter sales representative designation', Colors.red);
          return false;
        }
        if (_salesRepPhoneController.text.trim().isEmpty) {
          _showSnackBar('Please enter sales rep phone number', Colors.red);
          return false;
        }
        if (!_salesRepEmailController.text.trim().contains('@')) {
          _showSnackBar('Please enter a valid sales rep email address', Colors.red);
          return false;
        }
        return true;
        
      case 2: // Documents
        return true;
        
      case 3: // Review
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
      // Create client data map with only properties expected by backend
      final clientData = {
        'id': 'CL${DateTime.now().millisecondsSinceEpoch}',
        'name': _nameController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'addressType': _addressTypeController.text,
        'invoicingType': _invoicingType,
        'gstNumber': _gstNumberController.text,
        'panNumber': _panNumberController.text,
        'logisticsPOC': {
          'name': _logisticsNameController.text,
          'phone': _logisticsPhoneController.text,
          'email': _logisticsEmailController.text,
        },
        'financePOC': {
          'name': _financeNameController.text,
          'phone': _financePhoneController.text,
          'email': _financeEmailController.text,
        },
        'salesRepresentative': {
          'name': _salesRepNameController.text,
          'phone': _salesRepPhoneController.text,
          'email': _salesRepEmailController.text,
          'designation': _salesRepDesignationController.text,
        },
        'documents': [],
      };

      // Submit to API directly
      final apiService = ref.read(apiServiceProvider);
      await apiService.createClient(clientData);
      
      // Refresh the clients list
      await ref.read(clientNotifierProvider.notifier).loadClients();

      _showSnackBar('Client onboarded successfully!', Colors.green);
      
      // Navigate back to client management
      if (mounted) {
        context.go('/clients');
      }
    } catch (e) {
      _showSnackBar('Error onboarding client: $e', Colors.red);
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

        setState(() {
          _uploadedDocuments[docType] = [file];
        });

        _showSnackBar('Document uploaded successfully', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error uploading document: $e', Colors.red);
    }
  }

  void _viewDocument(PlatformFile document) {
    _showSnackBar('Document viewing functionality will be implemented', Colors.blue);
  }

  void _removeDocument(String docType) {
    setState(() {
      _uploadedDocuments.remove(docType);
    });
    _showSnackBar('Document removed', Colors.orange);
  }

  IconData _getDocumentIcon(String docType) {
    switch (docType) {
      case 'gst_certificate':
        return Icons.receipt_long_rounded;
      case 'pan_card':
        return Icons.credit_card_rounded;
      case 'cancelled_cheque':
        return Icons.payment_rounded;
      case 'msme_certificate':
        return Icons.business_center_rounded;
      case 'client_onboarding_form':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getDocumentDisplayName(String docType) {
    switch (docType) {
      case 'gst_certificate':
        return 'GST Certificate';
      case 'pan_card':
        return 'PAN Card';
      case 'cancelled_cheque':
        return 'Cancelled Cheque';
      case 'msme_certificate':
        return 'MSME Certificate';
      case 'client_onboarding_form':
        return 'Client Onboarding Form';
      default:
        return 'Other Document';
    }
  }

  String _getDocumentDescription(String docType) {
    switch (docType) {
      case 'gst_certificate':
        return 'GST registration certificate';
      case 'pan_card':
        return 'Permanent Account Number card';
      case 'cancelled_cheque':
        return 'Bank account verification document';
      case 'msme_certificate':
        return 'MSME registration certificate (if applicable)';
      case 'client_onboarding_form':
        return 'Completed client onboarding form';
      default:
        return 'Additional supporting document';
    }
  }

  String _getFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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