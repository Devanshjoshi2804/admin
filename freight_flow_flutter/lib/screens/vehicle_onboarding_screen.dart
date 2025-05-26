import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/providers/vehicle_provider.dart';
import 'package:freight_flow_flutter/providers/supplier_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

class VehicleOnboardingScreen extends ConsumerStatefulWidget {
  const VehicleOnboardingScreen({super.key});

  @override
  ConsumerState<VehicleOnboardingScreen> createState() => _VehicleOnboardingScreenState();
}

class _VehicleOnboardingScreenState extends ConsumerState<VehicleOnboardingScreen>
    with TickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Vehicle Information Controllers
  final _registrationNumberController = TextEditingController();
  String _selectedSupplierId = '';
  String _vehicleType = 'Truck';
  String _vehicleSize = 'Medium';
  String _vehicleCapacity = '10 Tons';
  String _axleType = '2 Axle';
  
  // Driver Information
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  
  // Compliance Information
  final _rcNumberController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  final _pucExpiryController = TextEditingController();
  final _fitnessExpiryController = TextEditingController();
  final _permitExpiryController = TextEditingController();
  
  // Document Management
  final Map<String, List<PlatformFile>> _uploadedDocuments = {};
  
  // Required document types
  List<String> get _requiredDocuments {
    return [
      'registration_certificate',
      'insurance_policy',
      'puc_certificate',
      'fitness_certificate',
      'permit',
      'driver_license',
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
    _registrationNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverLicenseController.dispose();
    _rcNumberController.dispose();
    _insuranceExpiryController.dispose();
    _pucExpiryController.dispose();
    _fitnessExpiryController.dispose();
    _permitExpiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Vehicle Onboarding',
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
                  _buildVehicleInfoStep(),
                  _buildDriverInfoStep(),
                  _buildComplianceStep(),
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
                child: Icon(Icons.local_shipping_rounded, color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Onboarding',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Register a new vehicle with complete documentation and compliance',
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
      'Vehicle Info',
      'Driver Details',
      'Compliance',
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

  Widget _buildVehicleInfoStep() {
    return _buildStepContainer(
      title: 'Vehicle Information',
      icon: Icons.local_shipping_rounded,
      child: Consumer(
        builder: (context, ref, child) {
          final suppliersAsync = ref.watch(suppliersProvider);
          
          return suppliersAsync.when(
            data: (suppliers) => Column(
              children: [
                _buildDropdownField(
                  value: _selectedSupplierId.isEmpty ? null : _selectedSupplierId,
                  label: 'Supplier',
                  hint: 'Select Supplier',
                  icon: Icons.business_rounded,
                  items: suppliers.map((supplier) => DropdownMenuItem<String>(
                    value: supplier.id,
                    child: Text(supplier.name),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplierId = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please select a supplier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _registrationNumberController,
                  label: 'Vehicle Registration Number',
                  hint: 'Enter registration number (e.g., MH12AB1234)',
                  icon: Icons.confirmation_number_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Registration number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        value: _vehicleType,
                        label: 'Vehicle Type',
                        hint: 'Select vehicle type',
                        icon: Icons.category_rounded,
                        items: const [
                          'Truck',
                          'Container',
                          'Trailer',
                          'Mini Truck',
                          'Pickup',
                          'Tempo',
                        ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _vehicleType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        value: _vehicleSize,
                        label: 'Vehicle Size',
                        hint: 'Select vehicle size',
                        icon: Icons.straighten_rounded,
                        items: const [
                          'Small',
                          'Medium',
                          'Large',
                          'Extra Large',
                        ].map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _vehicleSize = value!;
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
                      child: _buildDropdownField(
                        value: _vehicleCapacity,
                        label: 'Vehicle Capacity',
                        hint: 'Select capacity',
                        icon: Icons.scale_rounded,
                        items: const [
                          '1 Ton',
                          '2 Tons',
                          '3 Tons',
                          '5 Tons',
                          '7 Tons',
                          '10 Tons',
                          '15 Tons',
                          '20 Tons',
                          '25 Tons',
                          '32 Tons',
                        ].map((capacity) => DropdownMenuItem(value: capacity, child: Text(capacity))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _vehicleCapacity = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        value: _axleType,
                        label: 'Axle Type',
                        hint: 'Select axle type',
                        icon: Icons.settings_rounded,
                        items: const [
                          '2 Axle',
                          '3 Axle',
                          '4 Axle',
                          '5 Axle',
                          '6 Axle',
                        ].map((axle) => DropdownMenuItem(value: axle, child: Text(axle))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _axleType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading suppliers: $error'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverInfoStep() {
    return _buildStepContainer(
      title: 'Driver Information',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _buildTextField(
            controller: _driverNameController,
            label: 'Driver Name',
            hint: 'Enter driver full name',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Driver name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _driverPhoneController,
                  label: 'Driver Phone',
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
                  controller: _driverLicenseController,
                  label: 'Driver License Number',
                  hint: 'Enter license number',
                  icon: Icons.credit_card_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'License number is required';
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

  Widget _buildComplianceStep() {
    return _buildStepContainer(
      title: 'Compliance & Validity',
      icon: Icons.verified_rounded,
      child: Column(
        children: [
          _buildTextField(
            controller: _rcNumberController,
            label: 'RC Number',
            hint: 'Registration Certificate number',
            icon: Icons.description_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'RC number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _insuranceExpiryController,
                  label: 'Insurance Expiry',
                  hint: 'Select expiry date',
                  icon: Icons.security_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  controller: _pucExpiryController,
                  label: 'PUC Expiry',
                  hint: 'Select expiry date',
                  icon: Icons.eco_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _fitnessExpiryController,
                  label: 'Fitness Expiry',
                  hint: 'Select expiry date',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  controller: _permitExpiryController,
                  label: 'Permit Expiry',
                  hint: 'Select expiry date',
                  icon: Icons.assignment_rounded,
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
          _buildReviewSection('Vehicle Information', [
            'Registration Number: ${_registrationNumberController.text}',
            'Vehicle Type: $_vehicleType',
            'Vehicle Size: $_vehicleSize',
            'Vehicle Capacity: $_vehicleCapacity',
            'Axle Type: $_axleType',
          ]),
          
          _buildReviewSection('Driver Information', [
            'Driver Name: ${_driverNameController.text}',
            'Driver Phone: ${_driverPhoneController.text}',
            'License Number: ${_driverLicenseController.text}',
          ]),
          
          _buildReviewSection('Compliance Information', [
            'RC Number: ${_rcNumberController.text}',
            'Insurance Expiry: ${_insuranceExpiryController.text}',
            'PUC Expiry: ${_pucExpiryController.text}',
            'Fitness Expiry: ${_fitnessExpiryController.text}',
            'Permit Expiry: ${_permitExpiryController.text}',
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
                        'All required information and documents have been provided. Click Submit to complete the vehicle registration.',
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
          borderSide: BorderSide(color: Colors.blue.shade600),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) {
          controller.text = picked.toString().split(' ')[0];
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.calendar_today_rounded),
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
              onPressed: _isLoading ? null : (_currentStep == 4 ? _submitForm : _nextStep),
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_currentStep == 4 ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(_currentStep == 4 ? 'Submit' : 'Next'),
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
      if (_currentStep < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Vehicle Info
        if (_selectedSupplierId.isEmpty) {
          _showSnackBar('Please select a supplier', Colors.red);
          return false;
        }
        if (_registrationNumberController.text.isEmpty) {
          _showSnackBar('Please enter vehicle registration number', Colors.red);
          return false;
        }
        return true;
        
      case 1: // Driver Info
        if (_driverNameController.text.isEmpty) {
          _showSnackBar('Please enter driver name', Colors.red);
          return false;
        }
        if (_driverPhoneController.text.isEmpty) {
          _showSnackBar('Please enter driver phone number', Colors.red);
          return false;
        }
        if (_driverLicenseController.text.isEmpty) {
          _showSnackBar('Please enter driver license number', Colors.red);
          return false;
        }
        return true;
        
      case 2: // Compliance
        if (_rcNumberController.text.isEmpty) {
          _showSnackBar('Please enter RC number', Colors.red);
          return false;
        }
        if (_insuranceExpiryController.text.isEmpty) {
          _showSnackBar('Please enter insurance expiry date', Colors.red);
          return false;
        }
        if (_pucExpiryController.text.isEmpty) {
          _showSnackBar('Please enter PUC expiry date', Colors.red);
          return false;
        }
        return true;
        
      case 3: // Documents
        // Documents are now optional - no validation required
        return true;
        
      case 4: // Review
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
      // Get selected supplier details
      final suppliersAsync = ref.read(suppliersProvider);
      final suppliers = suppliersAsync.value ?? [];
      final selectedSupplier = suppliers.firstWhere((s) => s.id == _selectedSupplierId);

      // Create vehicle object
      final vehicle = Vehicle(
        id: 'VH${DateTime.now().millisecondsSinceEpoch}',
        vehicleNumber: _registrationNumberController.text,
        vehicleType: _vehicleType,
        vehicleSize: _vehicleSize,
        vehicleCapacity: _vehicleCapacity,
        axleType: _axleType,
        supplierId: _selectedSupplierId,
        supplierName: selectedSupplier.name,
        ownerName: selectedSupplier.name,
        driverName: _driverNameController.text,
        driverPhone: _driverPhoneController.text,
        driverLicense: _driverLicenseController.text,
        rcNumber: _rcNumberController.text,
        insuranceExpiry: _insuranceExpiryController.text,
        pucExpiry: _pucExpiryController.text,
        fitnessExpiry: _fitnessExpiryController.text,
        permitExpiry: _permitExpiryController.text,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Submit to API
      await ref.read(vehicleNotifierProvider.notifier).createVehicle(vehicle);

      _showSnackBar('Vehicle registered successfully!', Colors.green);
      
      // Navigate back to vehicle management
      if (mounted) {
        context.go('/vehicles');
      }
    } catch (e) {
      _showSnackBar('Error registering vehicle: $e', Colors.red);
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
      case 'registration_certificate':
        return Icons.description_rounded;
      case 'insurance_policy':
        return Icons.security_rounded;
      case 'puc_certificate':
        return Icons.eco_rounded;
      case 'fitness_certificate':
        return Icons.fitness_center_rounded;
      case 'permit':
        return Icons.assignment_rounded;
      case 'driver_license':
        return Icons.credit_card_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getDocumentDisplayName(String docType) {
    switch (docType) {
      case 'registration_certificate':
        return 'Registration Certificate';
      case 'insurance_policy':
        return 'Insurance Policy';
      case 'puc_certificate':
        return 'PUC Certificate';
      case 'fitness_certificate':
        return 'Fitness Certificate';
      case 'permit':
        return 'Permit';
      case 'driver_license':
        return 'Driver License';
      default:
        return 'Other Document';
    }
  }

  String _getDocumentDescription(String docType) {
    switch (docType) {
      case 'registration_certificate':
        return 'Vehicle registration certificate from RTO';
      case 'insurance_policy':
        return 'Valid vehicle insurance policy';
      case 'puc_certificate':
        return 'Pollution Under Control certificate';
      case 'fitness_certificate':
        return 'Vehicle fitness certificate';
      case 'permit':
        return 'Commercial vehicle permit';
      case 'driver_license':
        return 'Valid driving license';
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