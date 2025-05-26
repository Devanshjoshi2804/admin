import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Service for storing and retrieving document files in browser storage
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  
  factory LocalStorageService() {
    return _instance;
  }
  
  LocalStorageService._internal();
  
  /// Stores a document in local storage with metadata
  Future<bool> storeDocument({
    required String tripId,
    required String docId,
    required String docType,
    required String filename,
    required Uint8List fileBytes,
  }) async {
    try {
      final String storageKey = 'doc_${tripId}_${docId}';
      
      // Create base64 string from bytes
      final String base64Data = base64Encode(fileBytes);
      
      // Store metadata and content
      final Map<String, dynamic> documentData = {
        'tripId': tripId,
        'docId': docId,
        'type': docType,
        'filename': filename,
        'contentType': _getMimeType(filename),
        'fileData': base64Data,
        'storedAt': DateTime.now().toIso8601String(),
      };
      
      // Store as JSON string in localStorage
      final String documentJson = jsonEncode(documentData);
      html.window.localStorage[storageKey] = documentJson;
      
      // Also keep a registry of all documents by trip
      _updateTripDocumentRegistry(tripId, docId);
      
      debugPrint('Document stored in local storage: $storageKey');
      return true;
    } catch (e) {
      debugPrint('Error storing document in local storage: $e');
      return false;
    }
  }
  
  /// Retrieves a document from local storage
  Future<Map<String, dynamic>?> getDocument(String tripId, String docId) async {
    try {
      final String storageKey = 'doc_${tripId}_${docId}';
      final String? documentJson = html.window.localStorage[storageKey];
      
      if (documentJson == null) {
        debugPrint('Document not found in local storage: $storageKey');
        return null;
      }
      
      final Map<String, dynamic> documentData = jsonDecode(documentJson);
      debugPrint('Document retrieved from local storage: $storageKey');
      return documentData;
    } catch (e) {
      debugPrint('Error retrieving document from local storage: $e');
      return null;
    }
  }
  
  /// Downloads a document from local storage
  void downloadDocument(String tripId, String docId) async {
    try {
      final Map<String, dynamic>? documentData = await getDocument(tripId, docId);
      
      if (documentData == null) {
        debugPrint('Document not found for download: doc_${tripId}_${docId}');
        return;
      }
      
      final String base64Data = documentData['fileData'];
      final String filename = documentData['filename'];
      final String contentType = documentData['contentType'];
      
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
    } catch (e) {
      debugPrint('Error downloading document from local storage: $e');
    }
  }
  
  /// Gets a list of all documents for a trip
  List<String> getDocumentIdsForTrip(String tripId) {
    try {
      final String registryKey = 'trip_docs_$tripId';
      final String? registryJson = html.window.localStorage[registryKey];
      
      if (registryJson == null) {
        return [];
      }
      
      final List<dynamic> registry = jsonDecode(registryJson);
      return registry.cast<String>();
    } catch (e) {
      debugPrint('Error getting document registry for trip: $e');
      return [];
    }
  }
  
  /// Updates the registry of documents for a trip
  void _updateTripDocumentRegistry(String tripId, String docId) {
    try {
      final String registryKey = 'trip_docs_$tripId';
      final String? registryJson = html.window.localStorage[registryKey];
      
      List<String> registry = [];
      if (registryJson != null) {
        final List<dynamic> existingRegistry = jsonDecode(registryJson);
        registry = existingRegistry.cast<String>();
      }
      
      if (!registry.contains(docId)) {
        registry.add(docId);
      }
      
      html.window.localStorage[registryKey] = jsonEncode(registry);
    } catch (e) {
      debugPrint('Error updating document registry for trip: $e');
    }
  }
  
  /// Gets the MIME type based on file extension
  String _getMimeType(String filename) {
    final String extension = filename.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
} 