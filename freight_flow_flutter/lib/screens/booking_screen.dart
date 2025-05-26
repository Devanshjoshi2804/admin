import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/widgets/layout/main_layout.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 0;
  
  // Controllers for material fields
  final List<Map<String, TextEditingController>> _materialControllers = [
    {
      'name': TextEditingController(),
      'weight': TextEditingController(),
      'unit': TextEditingController(text: 'MT'),
      'ratePerMT': TextEditingController(),
    }
  ];

  @override
  void dispose() {
    // Dispose all controllers
    for (final controllers in _materialControllers) {
      controllers.forEach((_, controller) => controller.dispose());
    }
    super.dispose();
  }

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

  void _submitForm() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      // Process materials
      final materials = _materialControllers.map((controllers) {
        return {
          'name': controllers['name']!.text,
          'weight': double.tryParse(controllers['weight']!.text) ?? 0,
          'unit': controllers['unit']!.text,
          'ratePerMT': double.tryParse(controllers['ratePerMT']!.text) ?? 0,
        };
      }).toList();
      
      // Add materials to form data
      formData['materials'] = materials;
      
      // Submit to API would go here
      // Logger.info('Form data: $formData');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'New FTL Booking',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                ),
                const Text('New FTL Booking'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Create New FTL Booking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the details below to create a new full truckload booking.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Form
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  // Stepper
                  Stepper(
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < 3) {
                        setState(() {
                          _currentStep += 1;
                        });
                      } else {
                        _submitForm();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep -= 1;
                        });
                      }
                    },
                    steps: [
                      // Step 1: Client Details
                      Step(
                        title: const Text('Client Details'),
                        content: Column(
                          children: [
                            FormBuilderDropdown(
                              name: 'clientId',
                              decoration: const InputDecoration(
                                labelText: 'Select Client',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormBuilderValidators.required(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'client1',
                                  child: Text('Tata Steel Ltd'),
                                ),
                                DropdownMenuItem(
                                  value: 'client2',
                                  child: Text('Reliance Industries'),
                                ),
                                DropdownMenuItem(
                                  value: 'client3',
                                  child: Text('JSW Steel'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'clientAddress',
                                    decoration: const InputDecoration(
                                      labelText: 'Pickup Address',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'clientCity',
                                    decoration: const InputDecoration(
                                      labelText: 'Pickup City',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FormBuilderDropdown(
                              name: 'clientAddressType',
                              decoration: const InputDecoration(
                                labelText: 'Pickup Address Type',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormBuilderValidators.required(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Factory',
                                  child: Text('Factory'),
                                ),
                                DropdownMenuItem(
                                  value: 'Warehouse',
                                  child: Text('Warehouse'),
                                ),
                                DropdownMenuItem(
                                  value: 'Office',
                                  child: Text('Office'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 0,
                      ),
                      
                      // Step 2: Destination Details
                      Step(
                        title: const Text('Destination Details'),
                        content: Column(
                          children: [
                            FormBuilderTextField(
                              name: 'destinationAddress',
                              decoration: const InputDecoration(
                                labelText: 'Destination Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormBuilderValidators.required(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'destinationCity',
                                    decoration: const InputDecoration(
                                      labelText: 'Destination City',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderDropdown(
                                    name: 'destinationAddressType',
                                    decoration: const InputDecoration(
                                      labelText: 'Destination Address Type',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Factory',
                                        child: Text('Factory'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Warehouse',
                                        child: Text('Warehouse'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Office',
                                        child: Text('Office'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderDateTimePicker(
                                    name: 'pickupDate',
                                    inputType: InputType.date,
                                    format: DateFormat('yyyy-MM-dd'),
                                    decoration: const InputDecoration(
                                      labelText: 'Pickup Date',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderDropdown(
                                    name: 'pickupTime',
                                    decoration: const InputDecoration(
                                      labelText: 'Pickup Time',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: '08:00 AM',
                                        child: Text('08:00 AM'),
                                      ),
                                      DropdownMenuItem(
                                        value: '09:00 AM',
                                        child: Text('09:00 AM'),
                                      ),
                                      DropdownMenuItem(
                                        value: '10:00 AM',
                                        child: Text('10:00 AM'),
                                      ),
                                      DropdownMenuItem(
                                        value: '11:00 AM',
                                        child: Text('11:00 AM'),
                                      ),
                                      DropdownMenuItem(
                                        value: '12:00 PM',
                                        child: Text('12:00 PM'),
                                      ),
                                      DropdownMenuItem(
                                        value: '01:00 PM',
                                        child: Text('01:00 PM'),
                                      ),
                                      DropdownMenuItem(
                                        value: '02:00 PM',
                                        child: Text('02:00 PM'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 1,
                      ),
                      
                      // Step 3: Material Details
                      Step(
                        title: const Text('Material Details'),
                        content: Column(
                          children: [
                            ..._materialControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controllers = entry.value;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Material ${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (_materialControllers.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _removeMaterial(index),
                                              tooltip: 'Remove material',
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: controllers['name'],
                                        decoration: const InputDecoration(
                                          labelText: 'Material Name',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: controllers['weight'],
                                              decoration: const InputDecoration(
                                                labelText: 'Weight',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: TextField(
                                              controller: controllers['unit'],
                                              decoration: const InputDecoration(
                                                labelText: 'Unit',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: controllers['ratePerMT'],
                                        decoration: const InputDecoration(
                                          labelText: 'Rate per MT (₹)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.currency_rupee),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            
                            ElevatedButton.icon(
                              onPressed: _addMaterial,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Another Material'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 2,
                      ),
                      
                      // Step 4: Vehicle & Pricing
                      Step(
                        title: const Text('Vehicle & Pricing'),
                        content: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderDropdown(
                                    name: 'vehicleType',
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Type',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Truck',
                                        child: Text('Truck'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Container',
                                        child: Text('Container'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Trailer',
                                        child: Text('Trailer'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderDropdown(
                                    name: 'vehicleSize',
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Size',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: '20FT Sxl',
                                        child: Text('20FT Sxl'),
                                      ),
                                      DropdownMenuItem(
                                        value: '32FT Sxl',
                                        child: Text('32FT Sxl'),
                                      ),
                                      DropdownMenuItem(
                                        value: '32FT Mxl',
                                        child: Text('32FT Mxl'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'vehicleCapacity',
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Capacity',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderDropdown(
                                    name: 'axleType',
                                    decoration: const InputDecoration(
                                      labelText: 'Axle Type',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Single',
                                        child: Text('Single'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Multi',
                                        child: Text('Multi'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FormBuilderCheckbox(
                              name: 'gsmTracking',
                              title: const Text('Enable GSM Tracking'),
                              initialValue: true,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'clientFreight',
                                    decoration: const InputDecoration(
                                      labelText: 'Client Freight (₹)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.currency_rupee),
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.numeric(),
                                    ]),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'supplierFreight',
                                    decoration: const InputDecoration(
                                      labelText: 'Supplier Freight (₹)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.currency_rupee),
                                    ),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.numeric(),
                                    ]),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'advancePercentage',
                                    decoration: const InputDecoration(
                                      labelText: 'Advance Percentage (%)',
                                      border: OutlineInputBorder(),
                                      suffixText: '%',
                                    ),
                                    initialValue: '30',
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.numeric(),
                                      FormBuilderValidators.max(100),
                                    ]),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderDropdown(
                                    name: 'supplierId',
                                    decoration: const InputDecoration(
                                      labelText: 'Select Supplier',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'supplier1',
                                        child: Text('Highway Transport Co'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'supplier2',
                                        child: Text('Express Logistics'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'supplier3',
                                        child: Text('Roadways Carriers'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isActive: _currentStep >= 3,
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
} 