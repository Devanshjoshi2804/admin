import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:logging/logging.dart';

class ClientFormScreen extends StatefulWidget {
  final String? clientId;
  
  const ClientFormScreen({super.key, this.clientId});
  
  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger('ClientFormScreen');
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _activeTab = 'basic';
  double _onboardingProgress = 0.0;
  String? _errorMessage;
  Client? _currentClient;
  
  final Map<String, dynamic> _formData = {
    // Basic Information
    'name': '',
    'address': '',
    'city': '',
    'addressType': '',
    'invoicingType': '',
    'gstNumber': '',
    'panNumber': '',
    
    // Logistics Contact
    'logisticsName': '',
    'logisticsPhone': '',
    'logisticsEmail': '',
    
    // Finance Contact
    'financeName': '',
    'financePhone': '',
    'financeEmail': '',
    
    // Sales Representative
    'salesRepName': '',
    'salesRepDesignation': '',
    'salesRepPhone': '',
    'salesRepEmail': '',
  };
  
  final Map<String, String?> _documentFiles = {
    'gstFile': null,
    'panFile': null,
    'msmeFile': null,
    'cancelledChequeFile': null,
  };
  
  List<Map<String, dynamic>> _uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) {
      _fetchClientData();
    }
  }

  Future<void> _fetchClientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Check API connectivity first
      final isConnected = await _apiService.testApiConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to the server. Please check your network connection.');
      }
      
      // Fetch actual client data from the API
      final client = await _apiService.getClientById(widget.clientId!);
      _currentClient = client;
      
      // Update form data
      setState(() {
        // Basic information
        _formData['name'] = client.name;
        _formData['address'] = client.address;
        _formData['city'] = client.city;
        _formData['addressType'] = client.addressType;
        _formData['invoicingType'] = client.invoicingType;
        _formData['gstNumber'] = client.gstNumber;
        _formData['panNumber'] = client.panNumber;
        
        // Contact information
        _formData['logisticsName'] = client.logisticsPOC.name;
        _formData['logisticsPhone'] = client.logisticsPOC.phone;
        _formData['logisticsEmail'] = client.logisticsPOC.email;

        _formData['financeName'] = client.financePOC.name;
        _formData['financePhone'] = client.financePOC.phone;
        _formData['financeEmail'] = client.financePOC.email;

        _formData['salesRepName'] = client.salesRepresentative.name;
        _formData['salesRepDesignation'] = client.salesRepresentative.designation ?? '';
        _formData['salesRepPhone'] = client.salesRepresentative.phone;
        _formData['salesRepEmail'] = client.salesRepresentative.email;
        
        // Set onboarding progress based on completeness
        _calculateOnboardingProgress();
        
        // Load documents if any
        if (client.documents.isNotEmpty) {
          // Convert document strings to map objects
          _uploadedDocuments = client.documents.map((doc) {
            if (doc is Map<String, dynamic>) {
              return doc;
            } else {
              return {
                'type': 'Document',
                'url': doc,
                'uploadedAt': DateTime.now().toIso8601String(),
              };
            }
          }).toList().cast<Map<String, dynamic>>();
        }
      });
      
      _logger.info('Client data loaded successfully: ${client.id}');
    } catch (error) {
      _logger.severe('Error loading client data: $error');
      setState(() {
        _errorMessage = 'Failed to load client data: $error';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load client data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateOnboardingProgress() {
    // Calculate progress based on filled fields
    int filledFields = 0;
    int totalFields = _formData.length;
    
    for (var value in _formData.values) {
      if (value != null && value.toString().isNotEmpty) {
        filledFields++;
      }
    }
    
    _onboardingProgress = filledFields / totalFields;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      // Check API connectivity first
      final isConnected = await _apiService.testApiConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to the server. Please check your network connection.');
      }
      
      // Prepare client data for API
      final Map<String, dynamic> clientData = {
        'name': _formData['name'],
        'address': _formData['address'],
        'city': _formData['city'],
        'addressType': _formData['addressType'],
        'invoicingType': _formData['invoicingType'],
        'gstNumber': _formData['gstNumber'],
        'panNumber': _formData['panNumber'],
        
        'logisticsPOC': {
          'name': _formData['logisticsName'],
          'phone': _formData['logisticsPhone'],
          'email': _formData['logisticsEmail'],
        },

        'financePOC': {
          'name': _formData['financeName'],
          'phone': _formData['financePhone'],
          'email': _formData['financeEmail'],
        },

        'salesRepresentative': {
          'name': _formData['salesRepName'],
          'designation': _formData['salesRepDesignation'],
          'phone': _formData['salesRepPhone'],
          'email': _formData['salesRepEmail'],
        }
      };
      
      _logger.info('Submitting client data: ${clientData.toString()}');
      
      // Submit data to the API
      Client updatedClient;
      if (widget.clientId != null) {
        updatedClient = await _apiService.updateClient(widget.clientId!, clientData);
        _logger.info('Client updated successfully: ${updatedClient.id}');
      } else {
        updatedClient = await _apiService.createClient(clientData);
        _logger.info('Client created successfully: ${updatedClient.id}');
      }
      
      // Update current client
      _currentClient = updatedClient;
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.clientId != null 
            ? 'Client updated successfully' 
            : 'Client added successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.pop(context);
    } catch (error) {
      _logger.severe('Error saving client: $error');
      
      setState(() {
        _errorMessage = 'Failed to save client: $error';
      });
      
      if (mounted) {
        String errorMessage = 'Failed to save client: $error';
        // Try to extract a cleaner error message
        final errorStr = error.toString();
        if (errorStr.contains('Exception: Failed to')) {
          final cleanedMessage = errorStr.replaceAll('Exception: ', '');
          errorMessage = cleanedMessage;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DISMISS',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientId != null ? 'Edit Client' : 'Add New Client'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _currentClient == null
              ? _buildErrorView()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form title and description
                          Text(
                            widget.clientId != null ? 'Edit Client' : 'Add New Client',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.clientId != null 
                              ? 'Update client information in the system.'
                              : 'Create a new client and add them to your system.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Display error message if any
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Onboarding progress
                          Row(
                            children: [
                              Text(
                                'Client Onboarding Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_onboardingProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _onboardingProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          const SizedBox(height: 24),
                          
                          // Tab buttons
                          _buildTabButtons(),
                          const SizedBox(height: 24),
                          
                          // Tab content
                          _buildActiveTabContent(),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              if (_activeTab != 'basic') 
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_activeTab == 'contacts') {
                                        _activeTab = 'basic';
                                      } else if (_activeTab == 'documents') {
                                        _activeTab = 'contacts';
                                      }
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Previous'),
                                ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : (_activeTab == 'documents' ? _handleSubmit : () {
                                  setState(() {
                                    if (_activeTab == 'basic') {
                                      _activeTab = 'contacts';
                                    } else if (_activeTab == 'contacts') {
                                      _activeTab = 'documents';
                                    }
                                  });
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _activeTab == 'documents' 
                                        ? (widget.clientId != null ? 'Update Client' : 'Create Client')
                                        : 'Next',
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Client',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchClientData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabButton('basic', 'Basic Info'),
          _buildTabButton('contacts', 'Contacts'),
          _buildTabButton('documents', 'Documents'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label) {
    final isActive = _activeTab == tabId;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = tabId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'basic':
        return _buildBasicInfoTab();
      case 'contacts':
        return _buildContactsTab();
      case 'documents':
        return _buildDocumentsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client Name and City
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Client Name*',
                hint: 'Enter client name',
                value: _formData['name'],
                onChanged: (value) => _formData['name'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter client name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'City*',
                hint: 'Enter city',
                value: _formData['city'],
                onChanged: (value) => _formData['city'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Address
        _buildFormField(
          label: 'Address*',
          hint: 'Enter address',
          value: _formData['address'],
          onChanged: (value) => _formData['address'] = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Address Type and Invoicing Type
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Address Type*',
                hint: 'E.g., Head Office, Factory, Warehouse',
                value: _formData['addressType'],
                onChanged: (value) => _formData['addressType'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address type';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Invoicing Type*',
                hint: 'Select Invoicing Type',
                value: _formData['invoicingType'],
                items: const ['GST', 'Non-GST', 'International', 'Digital', 'Physical'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _formData['invoicingType'] = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select invoicing type';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // GST Number and PAN Number
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'GST Number',
                hint: 'Enter GST number',
                value: _formData['gstNumber'],
                onChanged: (value) => _formData['gstNumber'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'PAN Number',
                hint: 'Enter PAN number',
                value: _formData['panNumber'],
                onChanged: (value) => _formData['panNumber'] = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Cancelled Cheque and MSME Certificate
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cancelled Cheque',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFileUploadField(
                    documentType: 'cancelledChequeFile',
                    label: 'Choose File',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MSME Certificate',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFileUploadField(
                    documentType: 'msmeFile',
                    label: 'Choose File',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logistics Point of Contact section
        const Text(
          'Logistics Point of Contact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Name
        _buildFormField(
          label: 'Name*',
          hint: 'Enter name',
          value: _formData['logisticsName'],
          onChanged: (value) => _formData['logisticsName'] = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Phone and Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Phone*',
                hint: 'Enter phone number',
                value: _formData['logisticsPhone'],
                onChanged: (value) => _formData['logisticsPhone'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'Email*',
                hint: 'Enter email address',
                value: _formData['logisticsEmail'],
                onChanged: (value) => _formData['logisticsEmail'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Finance Point of Contact section
        const Text(
          'Finance Point of Contact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Name
        _buildFormField(
          label: 'Name*',
          hint: 'Enter name',
          value: _formData['financeName'],
          onChanged: (value) => _formData['financeName'] = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Phone and Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Phone*',
                hint: 'Enter phone number',
                value: _formData['financePhone'],
                onChanged: (value) => _formData['financePhone'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'Email*',
                hint: 'Enter email address',
                value: _formData['financeEmail'],
                onChanged: (value) => _formData['financeEmail'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Sales Representative section
        const Text(
          'Sales Representative',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Name and Designation
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Name*',
                hint: 'Enter name',
                value: _formData['salesRepName'],
                onChanged: (value) => _formData['salesRepName'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter representative name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'Designation*',
                hint: 'Enter designation',
                value: _formData['salesRepDesignation'],
                onChanged: (value) => _formData['salesRepDesignation'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter designation';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Phone and Email
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Phone*',
                hint: 'Enter phone number',
                value: _formData['salesRepPhone'],
                onChanged: (value) => _formData['salesRepPhone'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'Email*',
                hint: 'Enter email address',
                value: _formData['salesRepEmail'],
                onChanged: (value) => _formData['salesRepEmail'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client Onboarding Form
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Onboarding Form',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildFileUploadField(
              documentType: 'onboardingFile',
              label: 'Choose File',
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Document Gallery
        const Text(
          'Document Gallery',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'All uploaded documents related to this client will appear here.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Document list or empty state
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _uploadedDocuments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No documents uploaded yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: _uploadedDocuments
                      .map((doc) => _buildDocumentItem(doc))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    // Check if the value exists in the items list
    final bool valueExists = value != null && items.contains(value);
    
    // If value doesn't exist in items, set it to null to avoid the dropdown error
    final String? safeValue = valueExists ? value : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFileUploadField({
    required String documentType,
    required String label,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _documentFiles[documentType] ?? 'No file chosen',
              style: TextStyle(
                color: _documentFiles[documentType] != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _pickFile(documentType),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(label),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    final uploadDate = DateTime.parse(doc['uploadedAt']).toString().split('.')[0];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['type'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Uploaded on $uploadDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () {
              _downloadDocument(doc);
            },
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }
  
  void _downloadDocument(Map<String, dynamic> doc) async {
    if (doc['url'] != null) {
      try {
        // Show loading indicator
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Get the proper URL using the API service
          final url = _apiService.getDocumentUrl(doc['url']);
          
          // For web, open the URL in a new tab
          html.AnchorElement anchorElement = html.AnchorElement(href: url);
          anchorElement.target = '_blank';
          anchorElement.download = doc['type'] ?? 'document';
          // Append to the body temporarily
          html.document.body?.append(anchorElement);
          // Trigger click and then remove
          anchorElement.click();
          anchorElement.remove();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document download started'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Hide loading indicator
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFile(String documentType) async {
    // Use file_picker to select actual files
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true, // Important: get the file bytes
      );
      
      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _documentFiles[documentType] = file.name;
        });
        
        // If we have a client ID, upload the document immediately
        if (widget.clientId != null) {
          await _uploadDocument(documentType, file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }
  
  Future<void> _uploadDocument(String documentType, PlatformFile file) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Determine document type based on the documentType parameter
      String docType;
      switch (documentType) {
        case 'gstFile':
          docType = 'GST Certificate';
          break;
        case 'panFile':
          docType = 'PAN Card';
          break;
        case 'msmeFile':
          docType = 'MSME Certificate';
          break;
        case 'onboardingFile':
          docType = 'Client Onboarding Form';
          break;
        case 'cancelledChequeFile':
          docType = 'Cancelled Cheque';
          break;
        default:
          docType = 'Other Document';
      }
      
      // Create document data with the actual file
      final Map<String, dynamic> docData = {
        'type': docType,
        'filename': file.name,
        'file': file, // Pass the actual file to the API service
      };
      
      // Upload document to the API
      final result = await _apiService.uploadClientDocument(
        widget.clientId!,
        docData,
      );
      
      // Refresh client data to get updated documents list
      await _fetchClientData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
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
} 