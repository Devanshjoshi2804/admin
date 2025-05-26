import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freight_flow_flutter/widgets/layout/main_layout.dart';
import 'package:freight_flow_flutter/widgets/ui/status_badge.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _platformFeeController = TextEditingController();
  bool _isUpdating = false;
  bool _isUploading = false;
  // Debug mode flag - set to false for production
  final bool _debugMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _platformFeeController.dispose();
    super.dispose();
  }

  void _updatePlatformFee() async {
    if (_platformFeeController.text.isEmpty) return;

    final fee = double.tryParse(_platformFeeController.text);
    if (fee == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final tripNotifier = ref.read(tripNotifierProvider(widget.tripId).notifier);
      await tripNotifier.updatePlatformFee(fee);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Platform fee updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update platform fee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
  
  Future<void> _uploadDocument(String documentType) async {
    try {
      setState(() {
        _isUploading = true;
      });
      
      // Use file_picker to select a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true, // Important: get the file bytes
      );
      
      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Create document data with proper handling for file bytes
        final Map<String, dynamic> docData = {
          'type': documentType,
          'filename': file.name,
          // For web platform compatibility, we need to handle file data properly
          'file': {
            'name': file.name,
            'bytes': file.bytes,
            'size': file.size,
          },
          'uploadedAt': DateTime.now().toIso8601String(),
        };
        
        debugPrint('Uploading document: ${file.name}, size: ${file.size} bytes');
        if (file.bytes == null) {
          debugPrint('WARNING: File bytes are null!');
        } else {
          debugPrint('File bytes available: ${file.bytes!.length} bytes');
        }
        
        // Upload document using the provider
        await ref.read(uploadDocumentProvider(
          (tripId: widget.tripId, docData: docData)
        ).future);
        
        // If this is an LR copy, try to extract the LR number and add it
        if (documentType.toLowerCase().contains('lr') && file.name.isNotEmpty) {
          await _tryExtractAndSaveLRNumber(file.name);
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh trip data
        ref.refresh(tripDetailProvider(widget.tripId));
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Document upload error: $e');
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
          _isUploading = false;
        });
      }
    }
  }
  
  // Helper method to extract LR number from filename and save it
  Future<void> _tryExtractAndSaveLRNumber(String filename) async {
    try {
      // Get current trip
      final tripAsync = ref.read(tripDetailProvider(widget.tripId));
      final trip = tripAsync.value;
      
      if (trip == null) {
        return;
      }
      
      // Extract LR number using the helper method
      final String lrNumber = _extractLRNumberFromFilename(filename);
      
      if (lrNumber.isEmpty) {
        debugPrint('Could not extract a valid LR number from: $filename');
        return;
      }
      
      debugPrint('Extracted LR number: $lrNumber from filename: $filename');
      
      // Update the document metadata with the LR number
      // Find the document that matches this filename
      int matchingDocIndex = -1;
      for (int i = 0; i < trip.documents.length; i++) {
        if (trip.documents[i].filename == filename) {
          matchingDocIndex = i;
          break;
        }
      }
      
      if (matchingDocIndex >= 0) {
        final updatedDocs = [...trip.documents.map((d) => {
          'type': d.type,
          'filename': d.filename,
          'url': d.url,
          'uploadedAt': d.uploadedAt.toIso8601String(),
          'number': d.filename == filename ? lrNumber : d.number,
          if (d.id != null) 'id': d.id,
        })];
        
        try {
          await ref.read(updateTripProvider((trip.id, {
            'documents': updatedDocs
          })).future);
          debugPrint('Updated document metadata with LR number: $lrNumber');
        } catch (e) {
          debugPrint('Failed to update document metadata: $e');
        }
      }
      
      // Refresh trip data
      ref.refresh(tripDetailProvider(widget.tripId));
    } catch (e) {
      debugPrint('Error extracting LR number: $e');
    }
  }
  
  void _downloadDocument(Document doc) {
    if (doc.url.isNotEmpty) {
      try {
        // Check if this is a mock URL (client-side fallback)
        if (doc.url.startsWith('mock://')) {
          // Extract document ID from the URL
          String? docId;
          if (doc.id != null) {
            docId = doc.id;
          } else if (doc.url.contains('/')) {
            // Try to extract ID from the URL
            final parts = doc.url.split('/');
            if (parts.length > 2) {
              docId = parts.last;
            }
          }
          
          if (docId != null) {
            debugPrint('Attempting to download local document with ID: $docId');
            // Download the document directly
            _downloadLocalDocument(widget.tripId, docId);
            return;
          }
          
          // If we couldn't extract a document ID, show the document details dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('${doc.type} Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMockDocumentPreview(doc),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Filename'),
                    subtitle: Text(doc.filename ?? 'document'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Upload Date'),
                    subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(doc.uploadedAt)),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Note: This document was stored client-side and is not available for download.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
          return;
        }
        
        // For web, we can use html to trigger a download
        html.window.open(doc.url, '_blank');
        
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Generate a mock document preview based on document type
  Widget _buildMockDocumentPreview(Document doc) {
    final docType = doc.type.toLowerCase();
    final filename = (doc.filename ?? '').toLowerCase();
    
    // Check if it's an image type
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg') || 
        filename.endsWith('.png') || filename.endsWith('.gif')) {
      return Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            width: 250,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading image: $error');
              // If image doesn't exist, show placeholder
              return Container(
                width: 250,
                height: 150,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }
    
    // For LR Copy
    if (docType.contains('lr') || docType.contains('copy')) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 50, color: Colors.blue.shade700),
            const SizedBox(height: 8),
            Text('LR Document', style: TextStyle(color: Colors.blue.shade700)),
            if (doc.filename != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  doc.filename!,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }
    
    // For E-way Bill
    if (docType.contains('e-way') || docType.contains('eway')) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 50, color: Colors.purple.shade700),
            const SizedBox(height: 8),
            Text('E-way Bill', style: TextStyle(color: Colors.purple.shade700)),
          ],
        ),
      );
    }
    
    // For POD
    if (docType.contains('pod') || docType.contains('delivery')) {
      return Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 50, color: Colors.green.shade700),
            const SizedBox(height: 8),
            Text('Proof of Delivery', style: TextStyle(color: Colors.green.shade700)),
          ],
        ),
      );
    }
    
    // Default document preview
    return Container(
      width: 250,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 50, color: Colors.grey.shade700),
          const SizedBox(height: 8),
          Text(doc.type, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // Helper method to get all LR numbers from trip including those in document metadata
  List<String> _getAllLRNumbers(Trip trip) {
    // Start with the lrNumbers list
    final Set<String> uniqueLRNumbers = Set<String>.from(trip.lrNumbers);
    
    // Add any LR numbers found in document metadata
    for (final doc in trip.documents) {
      if (doc.type.toLowerCase().contains('lr') &&
          doc.number != null &&
          doc.number!.isNotEmpty) {
        uniqueLRNumbers.add(doc.number!);
      }
    }
    
    return uniqueLRNumbers.toList();
  }

  // Helper method to extract an LR number from a filename
  String _extractLRNumberFromFilename(String filename) {
    try {
      // Remove file extension
      String nameWithoutExtension = filename.split('.').first;
      
      // Try to find a pattern that looks like an LR number
      // Common formats: LR123456, LR-123456, LR_123456, 123456LR, 123456-LR
      RegExp lrPattern = RegExp(r'(?:[Ll][Rr][-_]?(\d+))|(?:(\d+)[_-]?[Ll][Rr])');
      final match = lrPattern.firstMatch(nameWithoutExtension);
      
      if (match != null) {
        // Use the matched group, which should be just the numbers
        String extractedNumber = match.group(1) ?? match.group(2) ?? '';
        if (extractedNumber.isNotEmpty) {
          return extractedNumber;
        }
      }
      
      // No match found, try to clean up the name as a fallback
      // Remove all non-alphanumeric characters
      String cleaned = nameWithoutExtension.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      
      // If it looks like it might be a valid LR number, return it
      if (cleaned.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleaned)) {
        return cleaned;
      }
      
      // If all extraction methods fail, return original filename without extension
      return nameWithoutExtension;
    } catch (e) {
      debugPrint('Error extracting LR number from filename: $e');
      return '';
    }
  }

  // Method to add LR number through document metadata when direct update fails
  Future<void> _addLRNumberViaDocumentMetadata(String tripId, String lrNumber) async {
    try {
      // Get current trip
      final tripAsync = ref.read(tripDetailProvider(tripId));
      final trip = tripAsync.value;
      
      if (trip == null) return;
      
      // Create a dummy document with the LR number
      final newDoc = {
        'type': 'LR Copy',
        'filename': 'manually_added_lr.txt',
        'url': 'mock://document-url',
        'uploadedAt': DateTime.now().toIso8601String(),
        'number': lrNumber,
      };
      
      // Add it to the list of documents
      final updatedDocs = [...trip.documents.map((d) => {
        'type': d.type,
        'filename': d.filename,
        'url': d.url,
        'uploadedAt': d.uploadedAt.toIso8601String(),
        'number': d.number,
        if (d.id != null) 'id': d.id,
      }), newDoc];
      
      // Update the trip with the new document
      await ref.read(updateTripProvider((tripId, {
        'documents': updatedDocs,
      })).future);
      
      // Refresh trip data
      ref.refresh(tripDetailProvider(tripId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LR Number added successfully as document metadata'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add LR Number: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Replace the LR number display section in the _buildContent method
  Widget _buildLRNumberSection(Trip trip) {
    // Get all unique LR numbers
    final allLRNumbers = _getAllLRNumbers(trip);
    
    return Row(
      children: [
        Expanded(
          child: allLRNumbers.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('LR Number not assigned',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'LR: ${allLRNumbers.join(", ")}',
                          style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add LR'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Colors.blue.shade50,
          ),
          onPressed: () {
            // Show dialog to add LR number
            showDialog(
              context: context,
              builder: (context) {
                final TextEditingController lrController = TextEditingController();
                return AlertDialog(
                  title: const Text('Add LR Number'),
                  content: TextField(
                    controller: lrController,
                    decoration: const InputDecoration(
                      labelText: 'LR Number',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (lrController.text.trim().isNotEmpty) {
                          try {
                            // Skip direct lrNumbers update as it causes schema validation errors
                            // Use document metadata approach directly
                            await _addLRNumberViaDocumentMetadata(trip.id, lrController.text.trim());
                            
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('LR Number added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add LR Number: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));

    return MainLayout(
      title: 'Trip Details',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Trip Data',
          onPressed: () {
            ref.refresh(tripDetailProvider(widget.tripId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing trip data...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
      child: tripAsync.when(
        data: (trip) {
          // Set initial platform fee value
          if (_platformFeeController.text.isEmpty && trip.platformFees != null) {
            _platformFeeController.text = trip.platformFees.toString();
          }
          
          return _buildContent(trip);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading trip: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumbs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Trips',
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
              ),
              Text(trip.orderNumber),
            ],
          ),
        ),
        
        // Trip header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                  children: [
                    Text(
                          trip.orderNumber.isEmpty ? 'Unknown Order' : 'Trip #${trip.orderNumber}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                        const SizedBox(width: 8),
                        StatusBadge(status: trip.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // LR Number with button to add if empty
                    _buildLRNumberSection(trip),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Tabs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Trip Info'),
              Tab(text: 'Freight Details'),
              Tab(text: 'Documents'),
            ],
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Trip Info Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      'Trip Information',
                      [
                        _buildInfoRow('Order ID', trip.orderNumber.isEmpty ? 'Unknown Order' : trip.orderNumber),
                        _buildInfoRow('LR Number', trip.lrNumbers.isEmpty ? 'Not assigned' : trip.lrNumbers.join(', ')),
                        _buildInfoRow('Status', trip.status, trailing: StatusBadge(status: trip.status)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Route Details',
                      [
                        _buildInfoRow('From', '${trip.clientAddress ?? trip.clientCity ?? trip.source}'),
                        _buildInfoRow('To', '${trip.destinationAddress ?? trip.destinationCity ?? trip.destination}'),
                        _buildInfoRow('Pickup Date', trip.pickupDate != null ? DateFormat('dd MMM yyyy').format(trip.pickupDate!) : 'N/A'),
                        _buildInfoRow('Pickup Time', trip.pickupTime ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Vehicle Details',
                      [
                        _buildInfoRow('Vehicle Type', trip.vehicleType ?? 'N/A'),
                        _buildInfoRow('Vehicle Number', trip.vehicleNumber ?? 'N/A'),
                        _buildInfoRow('Size', trip.vehicleSize ?? 'N/A'),
                        _buildInfoRow('Capacity', trip.vehicleCapacity ?? 'N/A'),
                        _buildInfoRow('Axle Type', trip.axleType ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Driver Details',
                      [
                        _buildInfoRow('Driver Name', trip.driverName ?? 'Driver not assigned'),
                        _buildInfoRow('Driver Phone', trip.driverPhone ?? 'Phone not available'),
                        if (trip.driverPhone != null && 
                            trip.driverPhone!.isNotEmpty && 
                            trip.driverPhone != 'Phone not available' &&
                            trip.driverPhone != 'N/A')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call Driver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                // Open phone app with driver's number
                                html.window.open('tel:${trip.driverPhone}', '_blank');
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Field Operations',
                      [
                        _buildInfoRow('Name', trip.fieldOps?.name ?? 'Field ops not assigned'),
                        _buildInfoRow('Phone', trip.fieldOps?.phone ?? 'Phone not available'),
                        _buildInfoRow('Email', trip.fieldOps?.email ?? 'Email not available'),
                        if (trip.fieldOps?.phone != null && 
                            trip.fieldOps!.phone.isNotEmpty && 
                            trip.fieldOps!.phone != 'Phone not available' &&
                            trip.fieldOps!.phone != 'N/A')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.phone, size: 18),
                                  label: const Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: () {
                                    // Open phone app with field ops number
                                    html.window.open('tel:${trip.fieldOps!.phone}', '_blank');
                                  },
                                ),
                                const SizedBox(width: 8),
                                if (trip.fieldOps?.email != null && 
                                    trip.fieldOps!.email.isNotEmpty && 
                                    trip.fieldOps!.email != 'Email not available' &&
                                    trip.fieldOps!.email != 'N/A')
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.email, size: 18),
                                    label: const Text('Email'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    onPressed: () {
                                      // Open email app
                                      html.window.open('mailto:${trip.fieldOps!.email}', '_blank');
                                    },
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Freight Details Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      'Material Details',
                      trip.materials.isEmpty
                          ? [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'No material details provided',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ]
                          : trip.materials.map((material) => _buildInfoRow(
                        material.name,
                        '${material.weight} ${material.unit} @ ₹${material.ratePerMT}/MT',
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Freight Details',
                      [
                        _buildInfoRow('Client Freight', _formatCurrency(_getClientFreight(trip))),
                        _buildInfoRow('Supplier Freight', _formatCurrency(_getSupplierFreight(trip))),
                        _buildInfoRow('Margin', _formatCurrency(_getMargin(trip)), 
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMargin(trip) > 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatCurrency(_getMargin(trip)),
                              style: TextStyle(
                                color: _getMargin(trip) > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Payment Breakdown',
                      [
                        _buildInfoRow(
                          'Advance (${_getAdvancePercentage(trip).toStringAsFixed(0)}%)', 
                          _formatCurrency(_getAdvanceAmount(trip)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPaymentStatusBadge(trip.advancePaymentStatus ?? 'Not Started'),
                              if (trip.advancePaymentStatus != 'Paid')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Mark Paid'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _updatePaymentStatus(trip, 'advance', 'Paid'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildInfoRow(
                          'Balance', 
                          _formatCurrency(_getBalanceAmount(trip)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPaymentStatusBadge(trip.balancePaymentStatus ?? 'Not Started'),
                              if (trip.balancePaymentStatus != 'Paid')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Mark Paid'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _updatePaymentStatus(trip, 'balance', 'Paid'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildInfoRow(
                          'Total Supplier Payment', 
                          _formatCurrency(_getSupplierFreight(trip)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTotalPaymentStatus(trip) == 'Completed' 
                                  ? Colors.green.shade50 
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTotalPaymentStatus(trip),
                              style: TextStyle(
                                color: _getTotalPaymentStatus(trip) == 'Completed'
                                    ? Colors.green.shade700 
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Debug Information (only show in debug mode)
                    if (_debugMode) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Debug Information',
                        [
                          _buildInfoRow('Supplier Freight (Raw)', '${trip.supplierFreight ?? 0}'),
                          _buildInfoRow('Advance Percentage', '${trip.advancePercentage ?? 30}'),
                          _buildInfoRow('Advance Amount (Raw)', '${trip.advanceSupplierFreight ?? 0}'),
                          _buildInfoRow('Balance Amount (Raw)', '${trip.balanceSupplierFreight ?? 0}'),
                          _buildInfoRow('Client Freight (Raw)', '${trip.clientFreight ?? 0}'),
                          _buildInfoRow('Margin (Raw)', '${trip.margin ?? 0}'),
                          _buildInfoRow('Pricing Total', '${trip.pricing.totalAmount}'),
                          _buildInfoRow('Calculated Client', '${_getClientFreight(trip)}'),
                          _buildInfoRow('Calculated Supplier', '${_getSupplierFreight(trip)}'),
                          _buildInfoRow('Calculated Advance', '${_getAdvanceAmount(trip)}'),
                          _buildInfoRow('Calculated Balance', '${_getBalanceAmount(trip)}'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Payment Status',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Advance Payment',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    trip.advancePaymentStatus ?? 'Pending',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (trip.advancePaymentStatus == 'Paid')
                                    Text(
                                      'Paid on ${trip.updatedAt != null ? DateFormat('dd MMM yyyy').format(trip.updatedAt!) : 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Balance Payment',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    trip.balancePaymentStatus ?? 'Pending',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (trip.balancePaymentStatus == 'Paid')
                                    Text(
                                      'Paid on ${trip.updatedAt != null ? DateFormat('dd MMM yyyy').format(trip.updatedAt!) : 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (trip.utrNumber != null) _buildInfoRow('UTR Number', trip.utrNumber!),
                        if (trip.paymentMethod != null) _buildInfoRow('Payment Method', trip.paymentMethod!),
                        
                        // Add input fields for UTR and payment method
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'UTR Number',
                            border: OutlineInputBorder(),
                            hintText: 'Enter UTR number for payment',
                          ),
                          onFieldSubmitted: (value) async {
                            if (value.trim().isNotEmpty) {
                              try {
                                await ref.read(updatePaymentStatusProvider((
                                  id: trip.id,
                                  advancePaymentStatus: null,
                                  balancePaymentStatus: null,
                                  utrNumber: value.trim(),
                                  paymentMethod: null,
                                )).future);
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('UTR number updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update UTR number: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                            DropdownMenuItem(value: 'NEFT', child: Text('NEFT')),
                            DropdownMenuItem(value: 'RTGS', child: Text('RTGS')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          ],
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              try {
                                await ref.read(updatePaymentStatusProvider((
                                  id: trip.id,
                                  advancePaymentStatus: null,
                                  balancePaymentStatus: null,
                                  utrNumber: null,
                                  paymentMethod: newValue,
                                )).future);
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment method updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update payment method: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          hint: const Text('Select payment method'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Additional Charges',
                      trip.additionalCharges != null && trip.additionalCharges!.isNotEmpty
                          ? [
                              ...trip.additionalCharges!.map((charge) => _buildInfoRow(
                                charge.description,
                                '₹${charge.amount}',
                              )),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Additional Charges:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      '₹${trip.additionalCharges!.fold(0.0, (sum, charge) => sum + charge.amount).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ℹ️ Additional charges are added to the supplier balance payment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ]
                          : [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'No additional charges',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Deductions',
                      [
                        _buildInfoRow('LR Charges', '₹${trip.lrCharges ?? 0}'),
                        _buildInfoRow('Platform Fees', '₹${trip.platformFees ?? 0}'),
                        if (trip.deductionCharges != null && trip.deductionCharges!.isNotEmpty)
                          ...trip.deductionCharges!.map((charge) => _buildInfoRow(
                            charge.description,
                            '₹${charge.amount}',
                          )),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Deductions:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              Text(
                                '₹${_getTotalDeductions(trip).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ℹ️ Deductions are subtracted from the supplier balance payment',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Enhanced Payment Breakdown',
                      [
                        _buildInfoRow('Supplier Freight (Base)', _formatCurrency(_getSupplierFreight(trip))),
                        _buildInfoRow('Advance (${_getAdvancePercentage(trip).toStringAsFixed(0)}%)', _formatCurrency(_getAdvanceAmount(trip))),
                        _buildInfoRow('Original Balance', _formatCurrency(_getOriginalBalanceAmount(trip))),
                        
                        const Divider(height: 16),
                        
                        // Additional charges impact
                        if (trip.additionalCharges != null && trip.additionalCharges!.isNotEmpty)
                          _buildInfoRow(
                            '+ Additional Charges', 
                            _formatCurrency(trip.additionalCharges!.fold(0.0, (sum, charge) => sum + charge.amount)),
                            trailing: Icon(Icons.add_circle, color: Colors.green.shade600, size: 16),
                          ),
                        
                        // Deductions impact
                        if (_getTotalDeductions(trip) > 0)
                          _buildInfoRow(
                            '- Total Deductions', 
                            _formatCurrency(_getTotalDeductions(trip)),
                            trailing: Icon(Icons.remove_circle, color: Colors.red.shade600, size: 16),
                          ),
                        
                        const Divider(height: 16),
                        
                        // Final balance payment
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Final Balance Payment:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatCurrency(_getAdjustedBalanceAmount(trip)),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Total supplier payment
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Supplier Payment:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatCurrency(_getAdvanceAmount(trip) + _getAdjustedBalanceAmount(trip)),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Impact summary
                        if (_getAdjustedBalanceAmount(trip) != _getOriginalBalanceAmount(trip))
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip) 
                                  ? Colors.orange.shade50 
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip) 
                                    ? Colors.orange.shade200 
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip) 
                                          ? Icons.trending_up 
                                          : Icons.trending_down,
                                      color: _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip) 
                                          ? Colors.orange.shade600 
                                          : Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Balance Payment Impact',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip) 
                                            ? Colors.orange.shade700 
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip)
                                      ? 'Increased by ${_formatCurrency(_getAdjustedBalanceAmount(trip) - _getOriginalBalanceAmount(trip))}'
                                      : 'Reduced by ${_formatCurrency(_getOriginalBalanceAmount(trip) - _getAdjustedBalanceAmount(trip))}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getAdjustedBalanceAmount(trip) > _getOriginalBalanceAmount(trip) 
                                        ? Colors.orange.shade600 
                                        : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Documents Tab
              _buildDocumentsTab(trip),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    // Special handling for LR Number row
    if (label == 'LR Number') {
      // Get the trip from the current context if we're displaying LR Number
      final tripAsync = ref.read(tripDetailProvider(widget.tripId));
      final trip = tripAsync.value;
      
      if (trip != null) {
        // Use _getAllLRNumbers to get a comprehensive list of LR numbers
        final allLRNumbers = _getAllLRNumbers(trip);
        value = allLRNumbers.isEmpty ? 'Not assigned' : allLRNumbers.join(', ');
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(Trip trip) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload document section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Document upload buttons
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildUploadButton('LR Copy', 'LR Copy'),
                      _buildUploadButton('E-way Bill', 'E-way Bill'),
                      _buildUploadButton('Invoice', 'Invoice'),
                      _buildUploadButton('POD', 'POD'),
                      _buildUploadButton('Weighment Slip', 'Weighment Slip'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Document list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uploaded Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  trip.documents.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No documents uploaded yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: trip.documents.map((doc) {
                            return _buildDocumentItem(doc);
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label, String documentType) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : () => _uploadDocument(documentType),
      icon: const Icon(Icons.upload_file),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDocumentItem(Document doc) {
    // Determine the document icon based on type or filename
    IconData documentIcon;
    Color iconColor;
    
    final docType = doc.type.toLowerCase();
    final filename = (doc.filename ?? '').toLowerCase();
    
    if (docType.contains('lr') || docType.contains('copy')) {
      documentIcon = Icons.description;
      iconColor = Colors.blue;
    } else if (docType.contains('e-way') || docType.contains('eway')) {
      documentIcon = Icons.receipt;
      iconColor = Colors.purple;
    } else if (docType.contains('invoice')) {
      documentIcon = Icons.receipt_long;
      iconColor = Colors.orange;
    } else if (docType.contains('pod') || docType.contains('delivery')) {
      documentIcon = Icons.done_all;
      iconColor = Colors.green;
    } else if (docType.contains('weight') || docType.contains('slip')) {
      documentIcon = Icons.scale;
      iconColor = Colors.amber;
    } else if (filename.endsWith('.pdf')) {
      documentIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (filename.endsWith('.jpg') || filename.endsWith('.jpeg') || 
             filename.endsWith('.png') || filename.endsWith('.gif')) {
      documentIcon = Icons.image;
      iconColor = Colors.blue;
    } else {
      documentIcon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }
    
    // Determine if this is a mock URL
    final isMockUrl = doc.url.startsWith('mock://');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: Icon(documentIcon, color: iconColor, size: 32),
        title: Row(
          children: [
            Text(doc.type, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isMockUrl)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text('Local', style: TextStyle(fontSize: 10)),
                  backgroundColor: Color(0xFFE0E0E0),
                  labelPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
        'Uploaded on ${DateFormat('dd MMM yyyy, hh:mm a').format(doc.uploadedAt)}',
        style: const TextStyle(fontSize: 12),
            ),
            if (doc.filename != null && doc.filename!.isNotEmpty)
              Text(
                doc.filename!,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
              ),
          ],
      ),
      trailing: IconButton(
          icon: Icon(
            Icons.download, 
            color: Colors.blue
          ),
        tooltip: 'Download',
          onPressed: () => _downloadDocument(doc),
        ),
        isThreeLine: doc.filename != null && doc.filename!.isNotEmpty,
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'paid':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'initiated':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'completed':
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        break;
      case 'ready for payment':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper method to download documents from local storage
  void _downloadLocalDocument(String tripId, String docId) {
    try {
      debugPrint('Downloading local document: $docId for trip $tripId');
      
      final String storageKey = 'doc_${tripId}_${docId}';
      final String? documentJson = html.window.localStorage[storageKey];
      
      if (documentJson == null) {
        debugPrint('Document not found in local storage: $storageKey');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document not found in local storage'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Parse the document data
      final Map<String, dynamic> documentData = jsonDecode(documentJson);
      final String base64Data = documentData['fileData'];
      final String filename = documentData['filename'] ?? 'document';
      final String contentType = documentData['contentType'] ?? 'application/octet-stream';
      
      // Convert base64 back to bytes
      final Uint8List bytes = base64Decode(base64Data);
      
      // Create a blob
      final blob = html.Blob([bytes], contentType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create download link
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      
      // Trigger download
      anchor.click();
      
      // Cleanup
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      debugPrint('Document download started: $filename');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading document: $filename'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error downloading document from local storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Financial calculation helper methods
  double _getClientFreight(Trip trip) {
    if (trip.clientFreight != null && trip.clientFreight! > 0) {
      return trip.clientFreight!;
    }
    
    // Fallback to pricing total if available
    if (trip.pricing.totalAmount > 0) {
      return trip.pricing.totalAmount;
    }
    
    // Ultimate fallback - estimate based on supplier freight
    final supplierFreight = _getSupplierFreight(trip);
    if (supplierFreight > 0) {
      return supplierFreight / 0.9; // Assume 90% margin for supplier
    }
    
    return 0.0;
  }

  double _getSupplierFreight(Trip trip) {
    if (trip.supplierFreight != null && trip.supplierFreight! > 0) {
      return trip.supplierFreight!;
    }
    
    // Calculate from client freight if available
    final clientFreight = trip.clientFreight ?? trip.pricing.totalAmount;
    if (clientFreight > 0) {
      return clientFreight * 0.9; // 90% of client freight
    }
    
    return 0.0;
  }

  double _getMargin(Trip trip) {
    if (trip.margin != null && trip.margin! > 0) {
      return trip.margin!;
    }
    
    // Calculate margin from client and supplier freight
    final clientFreight = _getClientFreight(trip);
    final supplierFreight = _getSupplierFreight(trip);
    
    return clientFreight - supplierFreight;
  }

  double _getAdvancePercentage(Trip trip) {
    return trip.advancePercentage ?? 30.0;
  }

  double _getAdvanceAmount(Trip trip) {
    if (trip.advanceSupplierFreight != null && trip.advanceSupplierFreight! > 0) {
      return trip.advanceSupplierFreight!;
    }
    
    // Calculate from supplier freight and percentage
    final supplierFreight = _getSupplierFreight(trip);
    final advancePercentage = _getAdvancePercentage(trip);
    
    return supplierFreight * (advancePercentage / 100);
  }

  double _getBalanceAmount(Trip trip) {
    if (trip.balanceSupplierFreight != null && trip.balanceSupplierFreight! > 0) {
      return trip.balanceSupplierFreight!;
    }
    
    // Calculate as supplier freight minus advance
    final supplierFreight = _getSupplierFreight(trip);
    final advanceAmount = _getAdvanceAmount(trip);
    
    return supplierFreight - advanceAmount;
  }

  String _getTotalPaymentStatus(Trip trip) {
    final advanceStatus = trip.advancePaymentStatus ?? 'Not Started';
    final balanceStatus = trip.balancePaymentStatus ?? 'Not Started';
    
    if (advanceStatus == 'Paid' && balanceStatus == 'Paid') {
      return 'Completed';
    } else if (advanceStatus == 'Paid' || balanceStatus == 'Paid') {
      return 'Partial';
    } else {
      return 'Pending';
    }
  }

  String _formatCurrency(double amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }

  // Payment status update helper
  Future<void> _updatePaymentStatus(Trip trip, String paymentType, String status) async {
    try {
      if (paymentType == 'advance') {
        await ref.read(updatePaymentStatusProvider((
          id: trip.id,
          advancePaymentStatus: status,
          balancePaymentStatus: null,
          utrNumber: null,
          paymentMethod: null,
        )).future);
      } else {
        await ref.read(updatePaymentStatusProvider((
          id: trip.id,
          advancePaymentStatus: null,
          balancePaymentStatus: status,
          utrNumber: null,
          paymentMethod: null,
        )).future);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${paymentType[0].toUpperCase()}${paymentType.substring(1)} payment marked as $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getOriginalBalanceAmount(Trip trip) {
    // Calculate the original balance amount before any additional charges or deductions
    final supplierFreight = _getSupplierFreight(trip);
    final advanceAmount = _getAdvanceAmount(trip);
    return supplierFreight - advanceAmount;
  }

  double _getAdjustedBalanceAmount(Trip trip) {
    // Calculate the final balance amount after adding additional charges and subtracting deductions
    final originalBalance = _getOriginalBalanceAmount(trip);
    final additionalCharges = trip.additionalCharges?.fold(0.0, (sum, charge) => sum + charge.amount) ?? 0.0;
    final totalDeductions = _getTotalDeductions(trip);
    
    return originalBalance + additionalCharges - totalDeductions;
  }

  double _getTotalDeductions(Trip trip) {
    // Calculate total deductions including LR charges, platform fees, and other deduction charges
    double totalDeductions = 0.0;
    
    // Add LR charges
    totalDeductions += trip.lrCharges ?? 0.0;
    
    // Add platform fees
    totalDeductions += trip.platformFees ?? 0.0;
    
    // Add other deduction charges
    if (trip.deductionCharges != null) {
      totalDeductions += trip.deductionCharges!.fold(0.0, (sum, charge) => sum + charge.amount);
    }
    
    return totalDeductions;
  }
} 