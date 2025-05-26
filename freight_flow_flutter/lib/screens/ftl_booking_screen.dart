import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/providers/booking_provider.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:freight_flow_flutter/providers/client_provider.dart';
import 'package:freight_flow_flutter/providers/supplier_provider.dart';
import 'package:freight_flow_flutter/providers/vehicle_provider.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:freight_flow_flutter/models/supplier.dart';

class FTLBookingScreen extends ConsumerStatefulWidget {
  const FTLBookingScreen({super.key});

  @override
  ConsumerState<FTLBookingScreen> createState() => _FTLBookingScreenState();
}

class _FTLBookingScreenState extends ConsumerState<FTLBookingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Animation controllers
  late AnimationController _pageAnimationController;
  late AnimationController _stepAnimationController;
  late AnimationController _pulseController;
  late List<AnimationController> _tabControllers;
  
  // Controllers for material fields
  final List<Map<String, TextEditingController>> _materialControllers = [
    {
      'name': TextEditingController(),
      'weight': TextEditingController(),
      'unit': TextEditingController(text: 'MT'),
      'ratePerMT': TextEditingController(),
    }
  ];

  // Calculate freight values when client freight, supplier freight or advance percentage changes
  bool _isUpdatingFreight = false;
  Timer? _freightCalculationTimer;
  Timer? _calculationTimer;
  
  // Document state
  Map<String, Map<String, dynamic>> _selectedDocuments = {};

  // New controllers
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String? _selectedClientId;
  final _loadingAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final _destinationCityController = TextEditingController();
  String _destinationAddressType = '';
  String? _selectedSupplierId;
  final _pickupDateController = TextEditingController();
  final _pickupTimeController = TextEditingController();
  String? _selectedVehicleId;
  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleSizeController = TextEditingController();
  final _vehicleCapacityController = TextEditingController();
  final _axleTypeController = TextEditingController();
  final _clientFreightController = TextEditingController();
  final _supplierFreightController = TextEditingController();
  final _advancePercentageController = TextEditingController(text: '30');
  final _marginController = TextEditingController();
  final _advanceSupplierFreightController = TextEditingController();
  final _balanceSupplierFreightController = TextEditingController();
  final _fieldOpsNameController = TextEditingController();
  final _fieldOpsPhoneController = TextEditingController();
  final _fieldOpsEmailController = TextEditingController();
  bool _enableGSMTracking = true;
  final Map<String, List<PlatformFile>> _uploadedDocuments = {};
  final List<String> _documentTypes = [
    'LR_Numbers',
    'Invoice_Material',
    'E_Way_Bills',
    'POD_Document',
    'Additional_Documents'
  ];
  Client? _selectedClient;
  Supplier? _selectedSupplier;
  Vehicle? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _tabControllers = List.generate(3, (index) => AnimationController(
      duration: Duration(milliseconds: 400 + (index * 100)),
      vsync: this,
    ));
    
    // Start animations
    _pageAnimationController.forward();
    _pulseController.repeat();
    
    // Initialize form and calculations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingStepProvider.notifier).state = 0;
      ref.read(bookingFormDataProvider.notifier).state = {};
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _formKey.currentState != null) {
          _formKey.currentState!.fields['clientFreight']?.didChange('0.00');
          _formKey.currentState!.fields['supplierFreight']?.didChange('0.00');
          _formKey.currentState!.fields['advancePercentage']?.didChange('30');
          _updateFreightCalculations();
        }
      });
    });

    // Set default pickup date to today
    _pickupDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _pickupTimeController.text = '09:00 AM';
    
    // Add listeners for real-time calculation
    _supplierFreightController.addListener(_calculateFreightValues);
    _advancePercentageController.addListener(_calculateFreightValues);
    for (var controllers in _materialControllers) {
      controllers['weight']?.addListener(_calculateMaterialCost);
      controllers['ratePerMT']?.addListener(_calculateMaterialCost);
    }
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _stepAnimationController.dispose();
    _pulseController.dispose();
    for (final controller in _tabControllers) {
      controller.dispose();
    }
    for (final controllers in _materialControllers) {
      controllers.forEach((_, controller) => controller.dispose());
    }
    _freightCalculationTimer?.cancel();
    _pageController.dispose();
    _calculationTimer?.cancel();
    _loadingAddressController.dispose();
    _destinationAddressController.dispose();
    _destinationCityController.dispose();
    _pickupDateController.dispose();
    _pickupTimeController.dispose();
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _vehicleTypeController.dispose();
    _vehicleSizeController.dispose();
    _vehicleCapacityController.dispose();
    _axleTypeController.dispose();
    _clientFreightController.dispose();
    _supplierFreightController.dispose();
    _advancePercentageController.dispose();
    _marginController.dispose();
    _advanceSupplierFreightController.dispose();
    _balanceSupplierFreightController.dispose();
    _fieldOpsNameController.dispose();
    _fieldOpsPhoneController.dispose();
    _fieldOpsEmailController.dispose();
    super.dispose();
  }

  void _debouncedUpdateFreight() {
    if (_freightCalculationTimer?.isActive ?? false) {
      _freightCalculationTimer!.cancel();
    }
    
    _freightCalculationTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateFreightCalculations();
      }
    });
  }
  
  void _updateFreightCalculations() {
    if (_isUpdatingFreight || _formKey.currentState == null) return;
    
    try {
      _isUpdatingFreight = true;
      
      final clientFreightField = _formKey.currentState!.fields['clientFreight'];
      final supplierFreightField = _formKey.currentState!.fields['supplierFreight'];
      final advancePercentageField = _formKey.currentState!.fields['advancePercentage'];
      
      String? clientFreightStr = clientFreightField?.value?.toString();
      String? supplierFreightStr = supplierFreightField?.value?.toString();
      String? advancePercentageStr = advancePercentageField?.value?.toString();
      
      double clientFreight = (clientFreightStr != null && clientFreightStr.isNotEmpty) 
          ? double.tryParse(clientFreightStr.replaceAll(',', '')) ?? 0 
          : 0;
      
      double supplierFreight = (supplierFreightStr != null && supplierFreightStr.isNotEmpty) 
          ? double.tryParse(supplierFreightStr.replaceAll(',', '')) ?? 0 
          : 0;
      
      double advancePercentage = (advancePercentageStr != null && advancePercentageStr.isNotEmpty) 
          ? double.tryParse(advancePercentageStr) ?? 30 
          : 30;
      
      clientFreight = clientFreight < 0 ? 0 : clientFreight;
      supplierFreight = supplierFreight < 0 ? 0 : supplierFreight;
      advancePercentage = advancePercentage < 0 ? 0 : (advancePercentage > 100 ? 100 : advancePercentage);
      
      double margin = clientFreight - supplierFreight;
      double advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
      double balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
      
      margin = margin.isNaN ? 0 : margin;
      advanceSupplierFreight = advanceSupplierFreight.isNaN ? 0 : advanceSupplierFreight;
      balanceSupplierFreight = balanceSupplierFreight.isNaN ? 0 : balanceSupplierFreight;
      
      final marginField = _formKey.currentState!.fields['margin'];
      final advanceSupplierFreightField = _formKey.currentState!.fields['advanceSupplierFreight'];
      final balanceSupplierFreightField = _formKey.currentState!.fields['balanceSupplierFreight'];
      
      setState(() {
        marginField?.didChange(margin.toStringAsFixed(2));
        advanceSupplierFreightField?.didChange(advanceSupplierFreight.toStringAsFixed(2));
        balanceSupplierFreightField?.didChange(balanceSupplierFreight.toStringAsFixed(2));
      });
    } catch (e) {
      print("[DEBUG] Error in freight calculations: $e");
    } finally {
      _isUpdatingFreight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Book Trip',
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
        child: AnimatedBuilder(
          animation: _pageAnimationController,
          builder: (context, child) {
            return Opacity(
              opacity: _pageAnimationController.value,
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    _buildModernHeader(),
                    _buildProgressIndicator(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(), // Disable manual swiping
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                          // Sync with the provider
                          ref.read(bookingStepProvider.notifier).state = index;
                        },
                        children: [
                          _buildBasicInfoStep(),
                          _buildVehicleAndMaterialStep(),
                          _buildDocumentationStep(),
                        ],
                      ),
                    ),
                    _buildModernBottomActions(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => context.go('/'),
                  child: Text(
                    'Home',
                    style: TextStyle(color: Colors.blue[600], fontSize: 14),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.blue[400]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Book Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (0.02 * math.sin(_pulseController.value * 2 * math.pi)),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.purple.shade500,
                                Colors.blue.shade700,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Create New Trip 🚛',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book your freight shipment in just a few steps',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 48,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentStep = ref.watch(bookingStepProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            _buildStepIndicator(
              stepNumber: i + 1,
              title: _getStepTitle(i),
              isActive: currentStep == i,
              isCompleted: currentStep > i,
            ),
            if (i < 2) _buildStepConnector(isCompleted: currentStep > i),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isActive || isCompleted
                  ? LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade600],
                    )
                  : null,
              color: isActive || isCompleted ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                  : Text(
                      stepNumber.toString(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.blue.shade600 : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : null,
          color: isCompleted ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Vehicle & Freight';
      case 2:
        return 'Documents & Review';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoStep() {
    final clientsAsync = ref.watch(clientsProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            title: 'Client Information',
            icon: Icons.business_rounded,
            children: [
              clientsAsync.when(
                data: (clients) => _buildModernDropdown(
                  name: 'clientId',
                  label: 'Select Client',
                  hint: 'Choose your client',
                  icon: Icons.business_rounded,
                  items: clients.map((client) => DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name),
                  )).toList(),
                  validator: (value) => value == null ? 'Please select a client' : null,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(clientDetailsProvider(value)).when(
                        data: (client) {
                          _formKey.currentState?.fields['clientAddress']?.didChange(client.address);
                          _formKey.currentState?.fields['clientCity']?.didChange(client.city);
                        },
                        loading: () {},
                        error: (error, stack) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to load client details: $error'),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Text('Failed to load clients'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildModernTextField(
                      name: 'clientAddress',
                      label: 'Client Address',
                      icon: Icons.location_on_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'clientCity',
                      label: 'City',
                      icon: Icons.location_city_rounded,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildStepCard(
            title: 'Supplier Information',
            icon: Icons.factory_rounded,
            children: [
              suppliersAsync.when(
                data: (suppliers) => _buildModernDropdown(
                  name: 'supplierId',
                  label: 'Select Supplier',
                  hint: 'Choose your supplier',
                  icon: Icons.factory_rounded,
                  items: suppliers.map((supplier) => DropdownMenuItem(
                    value: supplier.id,
                    child: Text(supplier.name),
                  )).toList(),
                  validator: (value) => value == null ? 'Please select a supplier' : null,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSupplierId = value;
                      });
                      ref.read(supplierDetailsProvider(value)).when(
                        data: (supplier) {
                          setState(() {
                            _selectedSupplier = supplier;
                          });
                          _formKey.currentState?.fields['supplierAddress']?.didChange(supplier.address);
                          _formKey.currentState?.fields['supplierCity']?.didChange(supplier.city);
                        },
                        loading: () {},
                        error: (error, stack) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to load supplier details: $error'),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load suppliers'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildModernTextField(
                      name: 'supplierAddress',
                      label: 'Supplier Address',
                      icon: Icons.location_on_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'supplierCity',
                      label: 'City',
                      icon: Icons.location_city_rounded,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildStepCard(
            title: 'Route Information',
            icon: Icons.route_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      name: 'source',
                      label: 'Pickup Location',
                      icon: Icons.my_location_rounded,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter pickup location' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'destination',
                      label: 'Delivery Location',
                      icon: Icons.location_on_rounded,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter delivery location' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildModernDatePicker(
                      name: 'pickupDate',
                      label: 'Pickup Date',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernDropdown(
                      name: 'pickupTime',
                      label: 'Pickup Time',
                      hint: 'Select time',
                      icon: Icons.schedule_rounded,
                      items: [
                        '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM',
                        '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
                        '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM'
                      ].map((time) => DropdownMenuItem(value: time, child: Text(time))).toList(),
                      validator: (value) => value == null ? 'Please select pickup time' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'distance',
                      label: 'Distance (km)',
                      icon: Icons.straighten_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter distance';
                        if (double.tryParse(value!) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleAndMaterialStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            title: 'Vehicle Selection',
            icon: Icons.local_shipping_rounded,
            children: [
              _buildVehicleSelection(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildStepCard(
            title: 'Material Information',
            icon: Icons.inventory_rounded,
            children: [
              _buildMaterialForm(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildStepCard(
            title: 'Freight Calculation',
            icon: Icons.calculate_rounded,
            children: [
              _buildFreightForm(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            title: 'Required Documents',
            icon: Icons.description_rounded,
            children: [
              _buildDocumentUpload(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildStepCard(
            title: 'Tracking & Operations',
            icon: Icons.track_changes_rounded,
            children: [
              _buildTrackingForm(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String name,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String?)? onChanged,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildModernDropdown<T>({
    required String name,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    String? Function(T?)? validator,
    void Function(T?)? onChanged,
  }) {
    return FormBuilderDropdown<T>(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildModernDatePicker({
    required String name,
    required String label,
    required IconData icon,
  }) {
    return FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.date,
      format: DateFormat('dd/MM/yyyy'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  // Placeholder methods for complex forms - would implement with modern styling
  Widget _buildVehicleSelection() {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vehiclesAsync.when(
          data: (vehicles) => _buildModernDropdown(
            name: 'vehicleId',
            label: 'Select Registered Vehicle',
            hint: 'Choose from registered vehicles',
            icon: Icons.local_shipping_rounded,
            items: vehicles.map((vehicle) => DropdownMenuItem(
              value: vehicle.id,
              child: Text('${vehicle.vehicleNumber} - ${vehicle.vehicleType}'),
            )).toList(),
            validator: (value) => value == null ? 'Please select a vehicle' : null,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedVehicleId = value;
                });
                // Auto-fill vehicle details
                final selectedVehicle = vehicles.firstWhere((v) => v.id == value);
                setState(() {
                  _selectedVehicle = selectedVehicle;
                  _vehicleNumberController.text = selectedVehicle.vehicleNumber;
                  _driverNameController.text = selectedVehicle.driverName ?? '';
                  _driverPhoneController.text = selectedVehicle.driverPhone ?? '';
                  _vehicleTypeController.text = selectedVehicle.vehicleType;
                  _vehicleSizeController.text = selectedVehicle.vehicleSize ?? '';
                  _vehicleCapacityController.text = selectedVehicle.vehicleCapacity ?? '';
                  _axleTypeController.text = selectedVehicle.axleType ?? '';
                });
                
                // Update form fields
                _formKey.currentState?.fields['vehicleNumber']?.didChange(selectedVehicle.vehicleNumber);
                _formKey.currentState?.fields['driverName']?.didChange(selectedVehicle.driverName ?? '');
                _formKey.currentState?.fields['driverPhone']?.didChange(selectedVehicle.driverPhone ?? '');
                _formKey.currentState?.fields['vehicleType']?.didChange(selectedVehicle.vehicleType);
                _formKey.currentState?.fields['vehicleSize']?.didChange(selectedVehicle.vehicleSize ?? '');
                _formKey.currentState?.fields['vehicleCapacity']?.didChange(selectedVehicle.vehicleCapacity ?? '');
                _formKey.currentState?.fields['axleType']?.didChange(selectedVehicle.axleType ?? '');
              }
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to load vehicles: $error',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Vehicle Details (Auto-filled from selection)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle Details (Auto-filled)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      name: 'vehicleNumber',
                      label: 'Vehicle Number',
                      icon: Icons.confirmation_number_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'vehicleType',
                      label: 'Vehicle Type',
                      icon: Icons.local_shipping_rounded,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      name: 'driverName',
                      label: 'Driver Name',
                      icon: Icons.person_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'driverPhone',
                      label: 'Driver Phone',
                      icon: Icons.phone_rounded,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      name: 'vehicleSize',
                      label: 'Vehicle Size',
                      icon: Icons.straighten_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'vehicleCapacity',
                      label: 'Vehicle Capacity (MT)',
                      icon: Icons.scale_rounded,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'axleType',
                      label: 'Axle Type',
                      icon: Icons.settings_rounded,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Materials (${_materialControllers.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addMaterial,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Add Material',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Material cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _materialControllers.length,
          itemBuilder: (context, index) => _buildMaterialCard(index),
        ),
        
        const SizedBox(height: 24),
        
        // Total calculation summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate_rounded, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Material Cost Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Weight:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    '${_calculateTotalWeight().toStringAsFixed(2)} MT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    '₹${_calculateTotalAmount().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialCard(int index) {
    final controllers = _materialControllers[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          // Card header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Material ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              if (_materialControllers.length > 1)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _removeMaterial(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Material name
          TextFormField(
            controller: controllers['name'],
            decoration: InputDecoration(
              labelText: 'Material Name',
              hintText: 'Enter material name',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_rounded, color: Colors.purple.shade600, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Please enter material name' : null,
          ),
          
          const SizedBox(height: 16),
          
          // Weight, Unit, Rate row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: controllers['weight'],
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    hintText: '0.00',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.scale_rounded, color: Colors.blue.shade600, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null) return 'Invalid number';
                    return null;
                  },
                  onChanged: (value) => _calculateMaterialCost(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: TextFormField(
                  controller: controllers['unit'],
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.straighten_rounded, color: Colors.green.shade600, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade500, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  readOnly: true,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: controllers['ratePerMT'],
                  decoration: InputDecoration(
                    labelText: 'Rate per MT',
                    hintText: '₹ 0.00',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.currency_rupee_rounded, color: Colors.orange.shade600, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange.shade500, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null) return 'Invalid number';
                    return null;
                  },
                  onChanged: (value) => _calculateMaterialCost(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Calculated amount display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${_calculateMaterialAmount(index).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaterialAmount(int index) {
    final controllers = _materialControllers[index];
    final weight = double.tryParse(controllers['weight']?.text ?? '') ?? 0;
    final rate = double.tryParse(controllers['ratePerMT']?.text ?? '') ?? 0;
    return weight * rate;
  }

  double _calculateTotalWeight() {
    double total = 0;
    for (final controllers in _materialControllers) {
      final weight = double.tryParse(controllers['weight']?.text ?? '') ?? 0;
      total += weight;
    }
    return total;
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (int i = 0; i < _materialControllers.length; i++) {
      total += _calculateMaterialAmount(i);
    }
    return total;
  }

  void _calculateMaterialCost() {
    // Cancel previous timer
    _calculationTimer?.cancel();
    
    // Set new timer for debounced calculation
    _calculationTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Update client freight with total material cost
          final totalAmount = _calculateTotalAmount();
          _clientFreightController.text = totalAmount.toStringAsFixed(2);
          _formKey.currentState?.fields['clientFreight']?.didChange(totalAmount.toStringAsFixed(2));
        });
        
        // Trigger freight calculations
        _calculateFreightValues();
      }
    });
  }

  void _calculateFreightValues() {
    // Cancel previous timer
    _freightCalculationTimer?.cancel();
    
    // Set new timer for debounced calculation
    _freightCalculationTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateFreightCalculations();
      }
    });
  }

  Widget _buildFreightForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.calculate_rounded, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Freight & Payment Calculations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Client Freight (Auto-calculated from materials)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Client Freight (Auto-calculated)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'clientFreight',
                controller: _clientFreightController,
                decoration: InputDecoration(
                  labelText: 'Client Freight Amount',
                  hintText: '₹ 0.00',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.currency_rupee_rounded, color: Colors.green.shade700, size: 20),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade500, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: 'Auto-filled from materials',
                  suffixStyle: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
                validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Client freight must be greater than 0' : null,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Supplier Freight
        _buildModernTextField(
          name: 'supplierFreight',
          label: 'Supplier Freight',
          icon: Icons.local_shipping_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hint: '₹ 0.00',
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter supplier freight';
            if (double.tryParse(value!) == null) return 'Please enter a valid amount';
            if ((double.tryParse(value) ?? 0) < 0) return 'Supplier freight cannot be negative';
            return null;
          },
          onChanged: (value) => _calculateFreightValues(),
        ),
        
        const SizedBox(height: 20),
        
        // Advance Percentage
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                name: 'advancePercentage',
                label: 'Advance Percentage',
                icon: Icons.percent_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: '30',
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter advance percentage';
                  final percentage = double.tryParse(value!);
                  if (percentage == null) return 'Please enter a valid percentage';
                  if (percentage < 0 || percentage > 100) return 'Percentage must be between 0-100';
                  return null;
                },
                onChanged: (value) => _calculateFreightValues(),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Default: 30%',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Calculated Values Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade50, Colors.purple.shade100.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
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
                  Icon(Icons.analytics_rounded, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Real-time Calculations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Margin Calculation
              _buildCalculationRow(
                'Margin',
                'Client Freight - Supplier Freight',
                Icons.trending_up_rounded,
                Colors.green,
                FormBuilderTextField(
                  name: 'margin',
                  controller: _marginController,
                  decoration: _buildCalculationFieldDecoration('Margin', Colors.green),
                  readOnly: true,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Advance Supplier Freight
              _buildCalculationRow(
                'Advance Amount',
                'Supplier Freight × Advance %',
                Icons.payment_rounded,
                Colors.orange,
                FormBuilderTextField(
                  name: 'advanceSupplierFreight',
                  controller: _advanceSupplierFreightController,
                  decoration: _buildCalculationFieldDecoration('Advance Amount', Colors.orange),
                  readOnly: true,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Balance Supplier Freight
              _buildCalculationRow(
                'Balance Amount',
                'Supplier Freight - Advance Amount',
                Icons.account_balance_rounded,
                Colors.blue,
                FormBuilderTextField(
                  name: 'balanceSupplierFreight',
                  controller: _balanceSupplierFreightController,
                  decoration: _buildCalculationFieldDecoration('Balance Amount', Colors.blue),
                  readOnly: true,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade900, Colors.indigo.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Total Weight', '${_calculateTotalWeight().toStringAsFixed(2)} MT'),
                  _buildSummaryItem('Client Freight', '₹${_clientFreightController.text}'),
                  _buildSummaryItem('Supplier Freight', '₹${_supplierFreightController.text}'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Advance', '₹${_advanceSupplierFreightController.text}'),
                  _buildSummaryItem('Balance', '₹${_balanceSupplierFreightController.text}'),
                  _buildSummaryItem('Margin', '₹${_marginController.text}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationRow(
    String title,
    String formula,
    IconData icon,
    MaterialColor color,
    Widget field,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color.shade700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.shade200),
                ),
                child: Text(
                  formula,
                  style: TextStyle(
                    color: color.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          field,
        ],
      ),
    );
  }

  InputDecoration _buildCalculationFieldDecoration(String label, MaterialColor color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.currency_rupee_rounded, color: color.shade600, size: 18),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.shade500, width: 2),
      ),
      filled: true,
      fillColor: color.shade50.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.cloud_upload_rounded, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Upload Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Upload required documents for your shipment. Supported formats: PDF, JPG, PNG',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Document types grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _documentTypes.length,
          itemBuilder: (context, index) {
            final docType = _documentTypes[index];
            final isUploaded = _selectedDocuments.containsKey(docType);
            
            return _buildDocumentCard(docType, isUploaded);
          },
        ),
        
        const SizedBox(height: 24),
        
        // Uploaded documents summary
        if (_selectedDocuments.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Uploaded Documents (${_selectedDocuments.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedDocuments.length,
                  itemBuilder: (context, index) {
                    final entry = _selectedDocuments.entries.elementAt(index);
                    final docKey = entry.key;
                    final docData = entry.value;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(_getDocumentIcon(docData['extension']), 
                               color: Colors.green.shade600, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  docData['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_formatDocumentType(docKey)} • ${_formatFileSize(docData['size'])}',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDocuments.remove(docKey);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.red.shade600,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentCard(String docType, bool isUploaded) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickDocument(docType, docType),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isUploaded
                ? LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)],
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100.withOpacity(0.3)],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUploaded ? Colors.green.shade300 : Colors.grey.shade300,
              width: isUploaded ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: isUploaded ? Colors.green.shade600 : Colors.grey.shade600,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _formatDocumentType(docType),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isUploaded ? Colors.green.shade700 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                isUploaded ? 'Uploaded ✓' : 'Tap to upload',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUploaded ? Colors.green.shade600 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Field Operations & Tracking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Configure field operations contact and tracking preferences',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Field Operations Contact
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Field Operations Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildModernTextField(
                name: 'fieldOpsName',
                label: 'Contact Person Name',
                icon: Icons.person_rounded,
                hint: 'Enter contact person name',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter contact person name' : null,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      name: 'fieldOpsPhone',
                      label: 'Phone Number',
                      icon: Icons.phone_rounded,
                      hint: '+91 9876543210',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter phone number';
                        if (value!.length < 10) return 'Please enter a valid phone number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      name: 'fieldOpsEmail',
                      label: 'Email Address',
                      icon: Icons.email_rounded,
                      hint: 'email@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter email address';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // GSM Tracking
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.purple.shade100.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, color: Colors.purple.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle Tracking',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              FormBuilderSwitch(
                name: 'enableGSMTracking',
                title: Text(
                  'Enable GSM Tracking',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Real-time vehicle location and route monitoring',
                  style: TextStyle(
                    color: Colors.purple.shade600,
                    fontSize: 12,
                  ),
                ),
                initialValue: _enableGSMTracking,
                activeColor: Colors.purple.shade600,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {
                    _enableGSMTracking = value ?? true;
                  });
                },
              ),
              
              if (_enableGSMTracking) ...[
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.purple.shade600, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Tracking Features',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildTrackingFeature('Real-time GPS location', Icons.location_on_rounded),
                      _buildTrackingFeature('Route optimization', Icons.route_rounded),
                      _buildTrackingFeature('Geofence alerts', Icons.notifications_rounded),
                      _buildTrackingFeature('Speed monitoring', Icons.speed_rounded),
                      _buildTrackingFeature('Trip history', Icons.history_rounded),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingFeature(String feature, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.shade600, size: 14),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDocumentType(String docType) {
    return docType.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getDocumentIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Widget _buildModernBottomActions() {
    final currentStep = ref.watch(bookingStepProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: _buildActionButton(
                label: 'Previous',
                icon: Icons.arrow_back_rounded,
                onPressed: _previousStep,
                isSecondary: true,
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: currentStep == 0 ? 1 : 2,
            child: _buildActionButton(
              label: currentStep < 2 ? 'Next Step' : 'Create Trip',
              icon: currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
              onPressed: _isSubmitting ? null : _nextStep,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool isSecondary = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: isSecondary || onPressed == null
                ? null
                : LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade600],
                  ),
            color: isSecondary 
                ? Colors.grey.shade100 
                : onPressed == null 
                    ? Colors.grey.shade300 
                    : null,
            borderRadius: BorderRadius.circular(16),
            border: isSecondary ? Border.all(color: Colors.grey.shade300) : null,
            boxShadow: !isSecondary && onPressed != null
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSecondary ? Colors.grey.shade600 : Colors.white,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: isSecondary 
                      ? Colors.grey.shade600 
                      : onPressed == null 
                          ? Colors.grey.shade500 
                          : Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Text(
                isLoading ? 'Creating...' : label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSecondary 
                      ? Colors.grey.shade600 
                      : onPressed == null 
                          ? Colors.grey.shade500 
                          : Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    final currentStep = ref.read(bookingStepProvider);
    if (currentStep < 2) {
      // Update the step state
      ref.read(bookingStepProvider.notifier).state = currentStep + 1;
      
      // Animate to the next page
      _pageController.animateToPage(
        currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Update local state
      setState(() {
        _currentStep = currentStep + 1;
      });
      
      // Animation controllers
      _stepAnimationController.forward().then((_) {
        _stepAnimationController.reset();
        if (currentStep + 1 < _tabControllers.length) {
          _tabControllers[currentStep + 1].forward();
        }
      });
    } else {
      _handleBookingSubmission();
    }
  }

  void _previousStep() {
    final currentStep = ref.read(bookingStepProvider);
    if (currentStep > 0) {
      // Update the step state
      ref.read(bookingStepProvider.notifier).state = currentStep - 1;
      
      // Animate to the previous page
      _pageController.animateToPage(
        currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Update local state
      setState(() {
        _currentStep = currentStep - 1;
      });
      
      // Animation controllers
      _stepAnimationController.reverse().then((_) {
        _stepAnimationController.reset();
      });
    }
  }

  Future<void> _handleBookingSubmission() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Validate form
      if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill in all required fields'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      final formData = _formKey.currentState!.value;
      
      // Prepare booking data with all intelligent auto-filled information
      final bookingData = {
        // Basic trip information
        'source': formData['source'],
        'destination': formData['destination'],
        'pickupDate': formData['pickupDate']?.toString(),
        'pickupTime': formData['pickupTime'],
        'distance': double.tryParse(formData['distance']?.toString() ?? '0') ?? 0,
        
        // Client information (auto-filled)
        'clientId': formData['clientId'],
        'clientName': _selectedClient?.name,
        'clientAddress': formData['clientAddress'],
        'clientCity': formData['clientCity'],
        
        // Supplier information (auto-filled)
        'supplierId': formData['supplierId'],
        'supplierName': _selectedSupplier?.name,
        'supplierAddress': formData['supplierAddress'],
        'supplierCity': formData['supplierCity'],
        
        // Vehicle information (auto-filled from registered vehicle)
        'vehicleId': formData['vehicleId'],
        'vehicleNumber': formData['vehicleNumber'],
        'driverName': formData['driverName'],
        'driverPhone': formData['driverPhone'],
        'vehicleType': formData['vehicleType'],
        'vehicleSize': formData['vehicleSize'],
        'vehicleCapacity': formData['vehicleCapacity'],
        'axleType': formData['axleType'],
        
        // Material information with calculations
        'materials': _materialControllers.asMap().map((index, controllers) => MapEntry(
          index.toString(),
          {
            'name': controllers['name']?.text,
            'weight': double.tryParse(controllers['weight']?.text ?? '0') ?? 0,
            'unit': controllers['unit']?.text ?? 'MT',
            'ratePerMT': double.tryParse(controllers['ratePerMT']?.text ?? '0') ?? 0,
            'amount': _calculateMaterialAmount(index),
          },
        )),
        'totalWeight': _calculateTotalWeight(),
        'totalMaterialAmount': _calculateTotalAmount(),
        
        // Freight and payment calculations
        'clientFreight': double.tryParse(_clientFreightController.text) ?? 0,
        'supplierFreight': double.tryParse(formData['supplierFreight']?.toString() ?? '0') ?? 0,
        'advancePercentage': double.tryParse(formData['advancePercentage']?.toString() ?? '30') ?? 30,
        'margin': double.tryParse(_marginController.text) ?? 0,
        'advanceSupplierFreight': double.tryParse(_advanceSupplierFreightController.text) ?? 0,
        'balanceSupplierFreight': double.tryParse(_balanceSupplierFreightController.text) ?? 0,
        
        // Field operations contact
        'fieldOpsName': formData['fieldOpsName'],
        'fieldOpsPhone': formData['fieldOpsPhone'],
        'fieldOpsEmail': formData['fieldOpsEmail'],
        
        // Tracking preferences
        'enableGSMTracking': formData['enableGSMTracking'] ?? _enableGSMTracking,
        
        // Documents
        'documents': _selectedDocuments.map((key, value) => MapEntry(key, {
          'name': value['name'],
          'type': value['type'],
          'size': value['size'],
          'extension': value['extension'],
          // Note: In production, you'd upload the file bytes to storage first
          // and store the URL here instead of the raw bytes
        })),
        
        // Metadata
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        'tripType': 'FTL',
      };

      // Submit to backend using the booking provider
      await ref.read(submitBookingProvider(bookingData).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Trip created successfully! 🎉',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Vehicle: ${formData['vehicleNumber']} • Client: ${_selectedClient?.name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.go('/trips');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Failed to create trip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Additional helper methods for material handling, document picking, etc.
  void _addMaterial() {
    setState(() {
      _materialControllers.add({
        'name': TextEditingController(),
        'weight': TextEditingController(),
        'unit': TextEditingController(text: 'MT'),
        'ratePerMT': TextEditingController(),
      });
    });
  }

  void _removeMaterial(int index) {
    if (_materialControllers.length > 1) {
      setState(() {
        final controllers = _materialControllers.removeAt(index);
        controllers.forEach((_, controller) => controller.dispose());
      });
    }
  }

  Future<void> _pickDocument(String docKey, String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        Map<String, Map<String, dynamic>> updatedDocs = Map.from(_selectedDocuments);
        updatedDocs[docKey] = {
          'name': file.name,
          'type': docType,
          'bytes': file.bytes,
          'size': file.size,
          'extension': file.extension,
        };
        
        setState(() {
          _selectedDocuments = updatedDocs;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} selected'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
} 