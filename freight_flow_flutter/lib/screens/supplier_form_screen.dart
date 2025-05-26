import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/api/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class SupplierFormScreen extends StatefulWidget {
  final String? supplierId;

  const SupplierFormScreen({super.key, this.supplierId});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _activeTab = 'basic';
  
  final Map<String, dynamic> _formData = {
    // Basic Information
    'name': '',
    'address': '',
    'city': '',
    'gstNumber': '',
    
    // Contact Person
    'contactName': '',
    'contactPhone': '',
    'contactEmail': '',
    
    // Supplier Representative
    'representativeName': '',
    'representativeDesignation': '',
    'representativePhone': '',
    'representativeEmail': '',
    
    // Bank Details
    'bankName': '',
    'accountType': '',
    'accountNumber': '',
    'ifscCode': '',
  };
  
  final Map<String, String?> _documentFiles = {
    'gstFile': null,
    'panFile': null,
    'msmeFile': null,
    'onboardingFile': null,
    'cancelledChequeFile': null,
  };
  
  List<Map<String, dynamic>> _uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    if (widget.supplierId != null) {
      _fetchSupplierData();
    }
  }

  Future<void> _fetchSupplierData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch actual supplier data from the API
      final supplier = await _apiService.getSupplierById(widget.supplierId!);
      
      // Update form data
      setState(() {
        for (final key in _formData.keys) {
          if (supplier.toJson().containsKey(key)) {
            _formData[key] = supplier.toJson()[key] ?? '';
          }
        }
        
        // Load documents if any
        if (supplier.documents != null && supplier.documents!.isNotEmpty) {
          _uploadedDocuments = List<Map<String, dynamic>>.from(supplier.documents!);
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load supplier data: $error')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Format data according to the backend DTO
      final Map<String, dynamic> supplierData = {
        'name': _formData['name'],
        'address': _formData['address'],
        'city': _formData['city'],
        'gstNumber': _formData['gstNumber'],
        'panNumber': _formData['gstNumber'], // Using GST as PAN if not available
        
        // Contact person details
        'contactName': _formData['contactName'],
        'contactPhone': _formData['contactPhone'],
        'contactEmail': _formData['contactEmail'],
        
        // Representative details
        'representativeName': _formData['representativeName'],
        'representativeDesignation': _formData['representativeDesignation'],
        'representativePhone': _formData['representativePhone'],
        'representativeEmail': _formData['representativeEmail'],
        
        // Bank details
        'bankName': _formData['bankName'],
        'accountType': _formData['accountType'],
        'accountNumber': _formData['accountNumber'],
        'ifscCode': _formData['ifscCode'],
      };
      
      // Submit data to the API
      if (widget.supplierId != null) {
        await _apiService.updateSupplier(widget.supplierId!, supplierData);
      } else {
        await _apiService.createSupplier(supplierData);
      }
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.supplierId != null 
            ? 'Supplier updated successfully' 
            : 'Supplier added successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save supplier: $error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierId != null ? 'Edit Supplier' : 'Add New Supplier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        'Add New Supplier',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the supplier details to onboard a new supplier.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
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
                          ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              widget.supplierId != null ? 'Update Supplier' : 'Create Supplier',
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

  Widget _buildTabButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabButton('basic', 'Basic Information'),
          _buildTabButton('banking', 'Banking Details'),
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
      case 'banking':
        return _buildBankingDetailsTab();
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
        // Supplier Name and City
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Supplier Name*',
                hint: 'Enter supplier name',
                value: _formData['name'],
                onChanged: (value) => _formData['name'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier name';
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
        const SizedBox(height: 24),
        
        // Contact Person section
        const Text(
          'Contact Person',
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
          value: _formData['contactName'],
          onChanged: (value) => _formData['contactName'] = value,
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
                value: _formData['contactPhone'],
                onChanged: (value) => _formData['contactPhone'] = value,
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
                value: _formData['contactEmail'],
                onChanged: (value) => _formData['contactEmail'] = value,
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
        
        // Supplier Representative section
        const Text(
          'Supplier Representative',
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
                value: _formData['representativeName'],
                onChanged: (value) => _formData['representativeName'] = value,
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
                value: _formData['representativeDesignation'],
                onChanged: (value) => _formData['representativeDesignation'] = value,
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
                value: _formData['representativePhone'],
                onChanged: (value) => _formData['representativePhone'] = value,
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
                value: _formData['representativeEmail'],
                onChanged: (value) => _formData['representativeEmail'] = value,
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

  Widget _buildBankingDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank Name and Account Type
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Bank Name*',
                hint: 'Enter bank name',
                value: _formData['bankName'],
                onChanged: (value) => _formData['bankName'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bank name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Account Type*',
                hint: 'Select Account Type',
                value: _formData['accountType'],
                items: const ['Current', 'Savings'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _formData['accountType'] = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select account type';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Account Number and IFSC Code
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(
                label: 'Account Number*',
                hint: 'Enter account number',
                value: _formData['accountNumber'],
                onChanged: (value) => _formData['accountNumber'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                label: 'IFSC Code*',
                hint: 'Enter IFSC code',
                value: _formData['ifscCode'],
                onChanged: (value) => _formData['ifscCode'] = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IFSC code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Cancelled Cheque
        Column(
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
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GST Number and Certificate
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
              child: _buildFileUploadField(
                documentType: 'gstFile',
                label: 'Choose File',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // PAN Card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'PAN Card',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFileUploadField(
                documentType: 'panFile',
                label: 'Choose File',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // MSME Certificate
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'MSME Certificate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFileUploadField(
                documentType: 'msmeFile',
                label: 'Choose File',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Supplier Onboarding Form
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Supplier Onboarding Form',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFileUploadField(
                documentType: 'onboardingFile',
                label: 'Choose File',
              ),
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
          'All uploaded documents related to this supplier will appear here.',
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
          value: value != '' ? value : null,
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
        
        // If we have a supplier ID, upload the document immediately
        if (widget.supplierId != null) {
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
          docType = 'Supplier Onboarding Form';
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
      final result = await _apiService.uploadSupplierDocument(
        widget.supplierId!,
        docData,
      );
      
      // Refresh supplier data to get updated documents list
      await _fetchSupplierData();
      
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