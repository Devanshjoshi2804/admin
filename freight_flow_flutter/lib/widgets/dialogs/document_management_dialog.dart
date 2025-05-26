import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/providers/trip_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';

class DocumentManagementDialog extends ConsumerStatefulWidget {
  final Trip trip;
  final Function(Trip) onDocumentUploaded;

  const DocumentManagementDialog({
    super.key,
    required this.trip,
    required this.onDocumentUploaded,
  });

  @override
  ConsumerState<DocumentManagementDialog> createState() => _DocumentManagementDialogState();
}

class _DocumentManagementDialogState extends ConsumerState<DocumentManagementDialog> {
  final Map<String, List<Document>> _documentsByType = {};
  bool _isLoading = false;
  String? _selectedDocumentType;

  // Define document types with their properties
  final Map<String, DocumentTypeInfo> _documentTypes = {
    'LR Copy': DocumentTypeInfo(
      icon: Icons.description_rounded,
      color: Colors.blue,
      allowMultiple: true,
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    ),
    'E-way Bill': DocumentTypeInfo(
      icon: Icons.receipt_long_rounded,
      color: Colors.green,
      allowMultiple: true,
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    ),
    'Invoice': DocumentTypeInfo(
      icon: Icons.article_rounded,
      color: Colors.orange,
      allowMultiple: true,
      extensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    ),
    'POD': DocumentTypeInfo(
      icon: Icons.verified_rounded,
      color: Colors.purple,
      allowMultiple: true,
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    ),
    'Weighment Slip': DocumentTypeInfo(
      icon: Icons.scale_rounded,
      color: Colors.teal,
      allowMultiple: true,
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    ),
    'Payment Proof': DocumentTypeInfo(
      icon: Icons.payment_rounded,
      color: Colors.indigo,
      allowMultiple: true,
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    ),
    'Performa Invoice': DocumentTypeInfo(
      icon: Icons.preview_rounded,
      color: Colors.amber,
      allowMultiple: true,
      extensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    ),
    'Contract': DocumentTypeInfo(
      icon: Icons.gavel_rounded,
      color: Colors.red,
      allowMultiple: false,
      extensions: ['pdf', 'doc', 'docx'],
    ),
    'Insurance': DocumentTypeInfo(
      icon: Icons.security_rounded,
      color: Colors.cyan,
      allowMultiple: false,
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    ),
    'Other': DocumentTypeInfo(
      icon: Icons.folder_rounded,
      color: Colors.grey,
      allowMultiple: true,
      extensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    // Group documents by type
    for (final doc in widget.trip.documents) {
      final type = doc.type;
      if (!_documentsByType.containsKey(type)) {
        _documentsByType[type] = [];
      }
      _documentsByType[type]!.add(doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade500, Colors.orange.shade600],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents for ${widget.trip.orderNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Upload and manage trip documents',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Upload Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _buildUploadSection(),
            ),

            // Documents List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildDocumentsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_upload_rounded, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              'Upload New Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: InputDecoration(
                  labelText: 'Select Document Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _documentTypes.keys.map((type) {
                  final info = _documentTypes[type]!;
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(info.icon, color: info.color, size: 20),
                        const SizedBox(width: 8),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDocumentType = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _selectedDocumentType != null && !_isLoading
                  ? () => _uploadDocument(_selectedDocumentType!)
                  : null,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(_isLoading ? 'Uploading...' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Supported formats: PDF, JPG, PNG, DOC, DOCX (Max 10MB)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    if (_documentsByType.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents uploaded yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload documents using the form above',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _documentsByType.entries.map((entry) {
        final type = entry.key;
        final documents = entry.value;
        final info = _documentTypes[type] ?? _documentTypes['Other']!;

        return _buildDocumentTypeSection(type, documents, info);
      }).toList(),
    );
  }

  Widget _buildDocumentTypeSection(String type, List<Document> documents, DocumentTypeInfo info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(info.icon, color: info.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getDarkColor(info.color),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: info.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${documents.length} ${documents.length == 1 ? 'file' : 'files'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getDarkColor(info.color),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Documents List
          ...documents.asMap().entries.map((entry) {
            final index = entry.key;
            final document = entry.value;
            final isLast = index == documents.length - 1;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: _buildDocumentItem(document, type),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Document document, String type) {
    return Row(
      children: [
        // File Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(document.url),
            color: Colors.grey.shade600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // File Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.filename ?? 'Document',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Uploaded: ${DateFormat('dd MMM yyyy, hh:mm a').format(document.uploadedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Actions
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_rounded),
              color: Colors.blue.shade600,
              tooltip: 'View',
              onPressed: () => _viewDocument(document),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              color: Colors.green.shade600,
              tooltip: 'Download',
              onPressed: () => _downloadDocument(document),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red.shade600,
              tooltip: 'Delete',
              onPressed: () => _deleteDocument(document, type),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final info = _documentTypes[documentType]!;
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: info.extensions,
        withData: true,
        allowMultiple: info.allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.bytes == null) continue;

          final docData = {
            'type': documentType,
            'filename': file.name,
            'file': {
              'name': file.name,
              'bytes': file.bytes,
              'size': file.size,
            },
            'uploadedAt': DateTime.now().toIso8601String(),
          };

          // Upload document using the provider
          await ref.read(uploadDocumentProvider((
            tripId: widget.trip.id,
            docData: docData
          )).future);

          // Update local state
          final newDocument = Document(
            type: documentType,
            url: 'uploaded',
            uploadedAt: DateTime.now(),
            filename: file.name,
            isDownloadable: true,
          );

          setState(() {
            if (!_documentsByType.containsKey(documentType)) {
              _documentsByType[documentType] = [];
            }
            _documentsByType[documentType]!.add(newDocument);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.length} document(s) uploaded successfully'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Refresh trip data
        ref.invalidate(tripDetailProvider(widget.trip.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewDocument(Document document) {
    // Implement document viewing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document viewing will open in new tab'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadDocument(Document document) {
    // Implement document download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${document.filename}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteDocument(Document document, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _documentsByType[type]?.remove(document);
                if (_documentsByType[type]?.isEmpty == true) {
                  _documentsByType.remove(type);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Color _getDarkColor(Color color) {
    // Create a darker shade of the given color
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }
}

class DocumentTypeInfo {
  final IconData icon;
  final Color color;
  final bool allowMultiple;
  final List<String> extensions;

  DocumentTypeInfo({
    required this.icon,
    required this.color,
    required this.allowMultiple,
    required this.extensions,
  });
} 