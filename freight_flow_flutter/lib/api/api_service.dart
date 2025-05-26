import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:freight_flow_flutter/models/trip.dart';
import 'package:freight_flow_flutter/models/client.dart';
import 'package:freight_flow_flutter/models/supplier.dart';
import 'package:freight_flow_flutter/models/vehicle.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:async';
import 'package:flutter/services.dart';

// Web-only imports, conditionally used at runtime
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Logger _logger = Logger('ApiService');
  final String _baseUrl = 'http://localhost:3000/api';
  late http.Client _client;
  
  // Connection status
  bool _isConnected = false;
  DateTime? _lastConnectionCheck;
  final Duration _connectionCheckInterval = const Duration(minutes: 1);
  
  // Retry configuration
  final int _maxRetries = 3;
  final Duration _retryDelay = const Duration(seconds: 2);

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _client = http.Client();
    _logger.info('ApiService initialized with base URL: $_baseUrl');
    _checkConnection();
  }
  
  // Check API connection
  Future<bool> _checkConnection() async {
    // Only check connection if we haven't checked recently
    if (_lastConnectionCheck == null || 
        DateTime.now().difference(_lastConnectionCheck!) > _connectionCheckInterval) {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/health'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
        
        _isConnected = response.statusCode >= 200 && response.statusCode < 300;
        _lastConnectionCheck = DateTime.now();
        _logger.info('API connection check: $_isConnected (${response.statusCode})');
      } catch (e) {
        _isConnected = false;
        _lastConnectionCheck = DateTime.now();
        _logger.warning('API connection check failed: $e');
      }
    }
    
    return _isConnected;
  }
  
  // Generic request handler with retries
  Future<http.Response> _makeRequest(
    String method, 
    String endpoint, 
    {Map<String, String>? headers, 
    Object? body}
  ) async {
    // Check connection first
    final isConnected = await _checkConnection();
    if (!isConnected) {
      _logger.severe('API not connected. Cannot make request to $endpoint');
      throw Exception('API server is not available. Please check your connection and try again.');
    }
    
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    http.Response? response;
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      attempts++;
      try {
        switch (method.toUpperCase()) {
          case 'GET':
            response = await _client.get(uri, headers: headers)
                .timeout(const Duration(seconds: 30));
            break;
          case 'POST':
            // Log the request body for debugging
            if (body != null) {
              _logger.info('POST request body: $body');
            }
            response = await _client.post(uri, headers: headers, body: body)
                .timeout(const Duration(seconds: 30));
            break;
          case 'PATCH':
            response = await _client.patch(uri, headers: headers, body: body)
                .timeout(const Duration(seconds: 30));
            break;
          case 'DELETE':
            response = await _client.delete(uri, headers: headers)
                .timeout(const Duration(seconds: 30));
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
        
        // Log request result
        _logger.info('$method $endpoint - Status: ${response.statusCode}');
        
        // Break the loop if successful
        break;
      } catch (e) {
        if (attempts >= _maxRetries) {
          _logger.severe('Request to $endpoint failed after $_maxRetries attempts: $e');
          throw Exception('Request failed: $e');
        } else {
          _logger.warning('Request to $endpoint failed (attempt $attempts): $e. Retrying...');
          await Future.delayed(_retryDelay * attempts);
        }
      }
    }
    
    // Process response
    if (response == null) {
      throw Exception('Request to $endpoint failed with no response');
    }
    
    // Handle error responses
    if (response.statusCode >= 400) {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      
      try {
        _logger.severe('Error response body: ${response.body}');
        final errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        } else if (errorBody['error'] != null) {
          errorMessage = errorBody['error'];
        }
      } catch (e) {
        // If we can't parse the JSON, just log the raw body
        _logger.severe('Raw error response: ${response.body}');
      }
      
      _logger.severe('$method $endpoint - Error: $errorMessage');
      throw Exception(errorMessage);
    }
    
    return response;
  }

  // Client API Methods
  Future<List<Client>> getClients() async {
    try {
      final response = await _makeRequest(
        'GET',
        '/clients',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

        final List<dynamic> data = jsonDecode(response.body);
      final clients = data.map((json) => Client.fromJson(json)).toList();
      _logger.info('Retrieved ${clients.length} clients');
      return clients;
    } catch (e) {
      _logger.severe('Error fetching clients: $e');
      throw Exception('Failed to load clients: $e');
    }
  }

  Future<Client> getClientById(String id) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/clients/$id',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

        final data = jsonDecode(response.body);
        return Client.fromJson(data);
    } catch (e) {
      _logger.severe('Error fetching client $id: $e');
      throw Exception('Failed to load client: $e');
    }
  }

  Future<Client> createClient(Map<String, dynamic> clientData) async {
    try {
      _logger.info('Creating client: ${clientData['name']}');
      final response = await _makeRequest(
        'POST',
        '/clients',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(clientData),
      );

        final data = jsonDecode(response.body);
      _logger.info('Client created successfully: ${data['id']}');
        return Client.fromJson(data);
    } catch (e) {
      _logger.severe('Error creating client: $e');
      throw Exception('Failed to create client: $e');
    }
  }

  Future<Client> updateClient(String id, Map<String, dynamic> clientData) async {
    try {
      _logger.info('Updating client $id with data: ${jsonEncode(clientData)}');
      
      final response = await _makeRequest(
        'PATCH',
        '/clients/$id',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(clientData),
      );

        final data = jsonDecode(response.body);
      _logger.info('Client updated successfully: $id');
        return Client.fromJson(data);
    } catch (e) {
      _logger.severe('Error updating client: $e');
      throw Exception('Failed to update client: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      _logger.info('Deleting client: $id');
      await _makeRequest(
        'DELETE',
        '/clients/$id',
        headers: {
          'Content-Type': 'application/json',
        },
      );
      _logger.info('Client deleted successfully: $id');
    } catch (e) {
      _logger.severe('Error deleting client: $e');
      throw Exception('Failed to delete client: $e');
    }
  }

  Future<Client> uploadClientDocument(String clientId, Map<String, dynamic> docData) async {
    try {
      _logger.info('Uploading document for client $clientId: ${docData['type']}');
      
      // Check if there's a file to upload
      if (docData['file'] != null && docData['file'] is PlatformFile) {
        final PlatformFile file = docData['file'];
        
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/clients/$clientId/documents'),
        );
        
        // Add file bytes
        if (file.bytes != null) {
          final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);
        }
        
        // Add metadata
        request.fields['type'] = docData['type'];
        if (docData['number'] != null) {
          request.fields['number'] = docData['number'];
        }
        
        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          _logger.info('Document uploaded successfully for client $clientId');
          return Client.fromJson(data);
        } else {
          String errorMessage = 'Failed to upload document: ${response.statusCode}';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'];
            }
          } catch (e) {
            // Ignore JSON parsing errors
          }
          _logger.severe('Error uploading document: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        // If no file, just send metadata
        final response = await _makeRequest(
          'POST',
          '/clients/$clientId/documents',
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(docData),
        );

          final data = jsonDecode(response.body);
        _logger.info('Document metadata uploaded successfully for client $clientId');
          return Client.fromJson(data);
      }
    } catch (e) {
      _logger.severe('Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  // Supplier API Methods
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _makeRequest(
        'GET',
        '/suppliers',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      final suppliers = data.map((json) => Supplier.fromJson(json)).toList();
      _logger.info('Retrieved ${suppliers.length} suppliers');
      return suppliers;
    } catch (e) {
      _logger.severe('Error fetching suppliers: $e');
      throw Exception('Failed to load suppliers: $e');
    }
  }

  Future<Supplier> getSupplierById(String id) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/suppliers/$id',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      return Supplier.fromJson(data);
    } catch (e) {
      _logger.severe('Error fetching supplier $id: $e');
      throw Exception('Failed to load supplier: $e');
    }
  }

  Future<Supplier> createSupplier(Map<String, dynamic> supplierData) async {
    try {
      _logger.info('Creating supplier: ${supplierData['name']}');
      final response = await _makeRequest(
        'POST',
        '/suppliers',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(supplierData),
      );

      final data = jsonDecode(response.body);
      _logger.info('Supplier created successfully: ${data['id']}');
      return Supplier.fromJson(data);
    } catch (e) {
      _logger.severe('Error creating supplier: $e');
      throw Exception('Failed to create supplier: $e');
    }
  }

  Future<Supplier> updateSupplier(String id, Map<String, dynamic> supplierData) async {
    try {
      _logger.info('Updating supplier $id with data: ${jsonEncode(supplierData)}');
      
      final response = await _makeRequest(
        'PATCH',
        '/suppliers/$id',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(supplierData),
      );

      final data = jsonDecode(response.body);
      _logger.info('Supplier updated successfully: $id');
      return Supplier.fromJson(data);
    } catch (e) {
      _logger.severe('Error updating supplier: $e');
      throw Exception('Failed to update supplier: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      _logger.info('Deleting supplier: $id');
      await _makeRequest(
        'DELETE',
        '/suppliers/$id',
        headers: {
          'Content-Type': 'application/json',
        },
      );
      _logger.info('Supplier deleted successfully: $id');
    } catch (e) {
      _logger.severe('Error deleting supplier: $e');
      throw Exception('Failed to delete supplier: $e');
    }
  }

  Future<Supplier> uploadSupplierDocument(String supplierId, Map<String, dynamic> docData) async {
    try {
      _logger.info('Uploading document for supplier $supplierId: ${docData['type']}');
      
      // Check if there's a file to upload
      if (docData['file'] != null && docData['file'] is PlatformFile) {
        final PlatformFile file = docData['file'];
        
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/suppliers/$supplierId/documents'),
        );
        
        // Add file bytes
        if (file.bytes != null) {
          final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);
        }
        
        // Add metadata
        request.fields['type'] = docData['type'];
        if (docData['number'] != null) {
          request.fields['number'] = docData['number'];
        }
        
        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          _logger.info('Document uploaded successfully for supplier $supplierId');
          return Supplier.fromJson(data);
        } else {
          String errorMessage = 'Failed to upload document: ${response.statusCode}';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'];
            }
          } catch (e) {
            // Ignore JSON parsing errors
          }
          _logger.severe('Error uploading document: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        // If no file, just send metadata
        final response = await _makeRequest(
          'POST',
          '/suppliers/$supplierId/documents',
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(docData),
        );

        final data = jsonDecode(response.body);
        _logger.info('Document metadata uploaded successfully for supplier $supplierId');
        return Supplier.fromJson(data);
      }
    } catch (e) {
      _logger.severe('Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  // Vehicle API Methods
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _makeRequest(
        'GET',
        '/vehicles',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      final vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
      _logger.info('Retrieved ${vehicles.length} vehicles');
      return vehicles;
    } catch (e) {
      _logger.severe('Error fetching vehicles: $e');
      throw Exception('Failed to load vehicles: $e');
    }
  }

  Future<Vehicle> getVehicleById(String id) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/vehicles/$id',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      return Vehicle.fromJson(data);
    } catch (e) {
      _logger.severe('Error fetching vehicle $id: $e');
      
      // If UUID validation fails, try to find by vehicle number
      if (e.toString().contains('uuid is expected')) {
        _logger.info('UUID validation failed for $id, trying to find by vehicle number');
        try {
          return await getVehicleByNumber(id);
        } catch (fallbackError) {
          _logger.severe('Fallback search by vehicle number also failed: $fallbackError');
          throw Exception('Failed to load vehicle: $e');
        }
      }
      
      throw Exception('Failed to load vehicle: $e');
    }
  }

  // Add method to search vehicle by vehicle number
  Future<Vehicle> getVehicleByNumber(String vehicleNumber) async {
    try {
      _logger.info('Searching for vehicle by number: $vehicleNumber');
      final allVehicles = await getVehicles();
      
      // Search by vehicle number or ID
      final vehicle = allVehicles.firstWhere(
        (v) => v.vehicleNumber == vehicleNumber || v.id == vehicleNumber,
        orElse: () => throw Exception('Vehicle not found with number: $vehicleNumber'),
      );
      
      _logger.info('Found vehicle by number: ${vehicle.vehicleNumber} (ID: ${vehicle.id})');
      return vehicle;
    } catch (e) {
      _logger.severe('Error searching vehicle by number $vehicleNumber: $e');
      throw Exception('Failed to find vehicle by number: $e');
    }
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      _logger.info('Creating vehicle: ${vehicleData['vehicleNumber']}');
      final response = await _makeRequest(
        'POST',
        '/vehicles',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vehicleData),
      );

      final data = jsonDecode(response.body);
      _logger.info('Vehicle created successfully: ${data['id']}');
      return Vehicle.fromJson(data);
    } catch (e) {
      _logger.severe('Error creating vehicle: $e');
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> vehicleData) async {
    try {
      _logger.info('Updating vehicle $id with data: ${jsonEncode(vehicleData)}');
      
      final response = await _makeRequest(
        'PATCH',
        '/vehicles/$id',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vehicleData),
      );

      final data = jsonDecode(response.body);
      _logger.info('Vehicle updated successfully: $id');
      return Vehicle.fromJson(data);
    } catch (e) {
      _logger.severe('Error updating vehicle: $e');
      throw Exception('Failed to update vehicle: $e');
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      _logger.info('Deleting vehicle: $id');
      await _makeRequest(
        'DELETE',
        '/vehicles/$id',
        headers: {
          'Content-Type': 'application/json',
        },
      );
      _logger.info('Vehicle deleted successfully: $id');
    } catch (e) {
      _logger.severe('Error deleting vehicle: $e');
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  Future<Vehicle> uploadVehicleDocument(String vehicleId, Map<String, dynamic> docData) async {
    try {
      _logger.info('Uploading document for vehicle $vehicleId: ${docData['type']}');
      
      // Check if there's a file to upload
      if (docData['file'] != null && docData['file'] is PlatformFile) {
        final PlatformFile file = docData['file'];
        
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/vehicles/$vehicleId/documents'),
        );
        
        // Add file bytes
        if (file.bytes != null) {
          final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);
        }
        
        // Add metadata
        request.fields['type'] = docData['type'];
        if (docData['number'] != null) {
          request.fields['number'] = docData['number'];
        }
        
        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          _logger.info('Document uploaded successfully for vehicle $vehicleId');
          return Vehicle.fromJson(data);
        } else {
          String errorMessage = 'Failed to upload document: ${response.statusCode}';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'];
            }
          } catch (e) {
            // Ignore JSON parsing errors
          }
          _logger.severe('Error uploading document: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        // If no file, just send metadata
        final response = await _makeRequest(
          'POST',
          '/vehicles/$vehicleId/documents',
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(docData),
        );

        final data = jsonDecode(response.body);
        _logger.info('Document metadata uploaded successfully for vehicle $vehicleId');
        return Vehicle.fromJson(data);
      }
    } catch (e) {
      _logger.severe('Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  // Trip API Methods
  Future<List<Trip>> getTrips() async {
    try {
      _logger.info('Fetching all trips');
      final response = await _makeRequest(
        'GET',
        '/trips',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      
      _logger.info('Received ${data.length} trips from API');
      
      // Process each trip to enrich data and ensure financial calculations
      List<Trip> enrichedTrips = [];
      
      for (int i = 0; i < data.length; i++) {
        try {
          final Map<String, dynamic> tripData = Map<String, dynamic>.from(data[i]);
          
          // Log progress for large datasets
          if (i % 10 == 0) {
            _logger.info('Processing trip ${i + 1}/${data.length}: ${tripData['id']}');
          }
          
          // **CRITICAL: Fetch missing client information**
          if (tripData['clientId'] != null && 
              (tripData['clientName'] == null || tripData['clientName'].toString().isEmpty)) {
            try {
              _logger.info('Fetching missing client name for trip ${tripData['id']}, clientId: ${tripData['clientId']}');
              final client = await this.getClientById(tripData['clientId']);
              tripData['clientName'] = client.name;
              tripData['clientAddress'] = client.address ?? tripData['clientAddress'];
              tripData['clientCity'] = client.city ?? tripData['clientCity'];
              _logger.info('Client name updated: ${client.name}');
            } catch (clientError) {
              _logger.warning('Could not fetch client details for ${tripData['clientId']}: $clientError');
              // Set a more descriptive default
              tripData['clientName'] = 'Client ID: ${tripData['clientId']}';
            }
          }
          
          // **CRITICAL: Fetch missing supplier information**
          if (tripData['supplierId'] != null && 
              (tripData['supplierName'] == null || tripData['supplierName'].toString().isEmpty)) {
            try {
              _logger.info('Fetching missing supplier name for trip ${tripData['id']}, supplierId: ${tripData['supplierId']}');
              final supplier = await this.getSupplierById(tripData['supplierId']);
              tripData['supplierName'] = supplier.name;
              _logger.info('Supplier name updated: ${supplier.name}');
            } catch (supplierError) {
              _logger.warning('Could not fetch supplier details for ${tripData['supplierId']}: $supplierError');
              // Set a more descriptive default
              tripData['supplierName'] = 'Supplier ID: ${tripData['supplierId']}';
            }
          }
          
          // **CRITICAL: Fetch missing vehicle information**
          if (tripData['vehicleId'] != null && 
              (tripData['vehicleNumber'] == null || tripData['vehicleNumber'].toString().isEmpty)) {
            try {
              _logger.info('Fetching missing vehicle details for trip ${tripData['id']}, vehicleId: ${tripData['vehicleId']}');
              final vehicle = await this.getVehicleById(tripData['vehicleId']);
              tripData['vehicleNumber'] = vehicle.vehicleNumber;
              tripData['vehicleType'] = vehicle.vehicleType;
              tripData['driverName'] = vehicle.driverName ?? tripData['driverName'];
              tripData['driverPhone'] = vehicle.driverPhone ?? tripData['driverPhone'];
              _logger.info('Vehicle details updated: ${vehicle.vehicleNumber}');
            } catch (vehicleError) {
              _logger.warning('Could not fetch vehicle details for ${tripData['vehicleId']}: $vehicleError');
              // Set a more descriptive default
              tripData['vehicleNumber'] = 'Vehicle ID: ${tripData['vehicleId']}';
            }
          }
          
          // Enrich each trip's financial data
          _enrichFinancialData(tripData);
          
          // Set default values for missing fields
          _setDefaultValues(tripData);
          
          // Ensure orderNumber is properly set
          if (tripData['orderNumber'] == null || tripData['orderNumber'].toString().isEmpty) {
            tripData['orderNumber'] = tripData['id'] ?? 'UNKNOWN';
          }
          
          // Create Trip object and add to list
          final trip = Trip.fromJson(tripData);
          enrichedTrips.add(trip);
          
        } catch (e) {
          _logger.warning('Error processing trip ${i + 1}: $e');
          // Continue with next trip instead of failing entirely
          continue;
        }
      }
      
      _logger.info('Successfully processed ${enrichedTrips.length} trips');
      
      // Log summary of data completeness
      int tripsWithClientData = 0;
      int tripsWithSupplierData = 0;
      int tripsWithVehicleData = 0;
      int tripsWithFinancialData = 0;
      
      for (final trip in enrichedTrips) {
        if (trip.clientName != null && !trip.clientName!.contains('Unknown') && !trip.clientName!.contains('Client ID:')) {
          tripsWithClientData++;
        }
        if (trip.supplierName != null && !trip.supplierName!.contains('Unknown') && !trip.supplierName!.contains('Supplier ID:')) {
          tripsWithSupplierData++;
        }
        if (trip.vehicleNumber != null && !trip.vehicleNumber!.contains('Unknown') && !trip.vehicleNumber!.contains('Vehicle ID:')) {
          tripsWithVehicleData++;
        }
        if (trip.clientFreight != null && trip.clientFreight! > 0 && 
            trip.supplierFreight != null && trip.supplierFreight! > 0) {
          tripsWithFinancialData++;
        }
      }
      
      _logger.info('Data completeness summary:');
      _logger.info('- Trips with client data: $tripsWithClientData/${enrichedTrips.length}');
      _logger.info('- Trips with supplier data: $tripsWithSupplierData/${enrichedTrips.length}');
      _logger.info('- Trips with vehicle data: $tripsWithVehicleData/${enrichedTrips.length}');
      _logger.info('- Trips with financial data: $tripsWithFinancialData/${enrichedTrips.length}');
      
      return enrichedTrips;
    } catch (e) {
      _logger.severe('Error fetching trips: $e');
      throw Exception('Failed to load trips: $e');
    }
  }

  Future<Trip> getTripById(String id) async {
    try {
      _logger.info('Fetching trip details for ID: $id');
      final response = await _makeRequest(
        'GET',
        '/trips/$id',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      // Log the raw response for debugging
      _logger.info('Raw trip response for $id: ${data.toString()}');
      
      // Ensure essential fields are present
      if (data['id'] == null || data['orderNumber'] == null) {
        _logger.warning('Warning: Trip data missing essential fields. ID: $id, Data: $data');
        
        // If orderNumber is missing, use the id as the orderNumber
        if (data['id'] != null && data['orderNumber'] == null) {
          data['orderNumber'] = data['id'];
          _logger.info('Setting orderNumber to ID: ${data['id']}');
        }
      }
      
      // 1. FETCH AND POPULATE VEHICLE + DRIVER DETAILS
      if (data['vehicleId'] != null) {
        try {
          _logger.info('Fetching vehicle and driver details for vehicle ID: ${data['vehicleId']}');
          final vehicle = await this.getVehicleById(data['vehicleId']);
          
          // Update vehicle details
          if (data['vehicleNumber'] == null || data['vehicleNumber'].toString().isEmpty) {
            data['vehicleNumber'] = vehicle.vehicleNumber;
          }
          if (data['vehicleType'] == null || data['vehicleType'].toString().isEmpty) {
            data['vehicleType'] = vehicle.vehicleType;
          }
          if (data['vehicleSize'] == null || data['vehicleSize'].toString().isEmpty) {
            data['vehicleSize'] = vehicle.vehicleSize;
          }
          if (data['vehicleCapacity'] == null || data['vehicleCapacity'].toString().isEmpty) {
            data['vehicleCapacity'] = vehicle.vehicleCapacity;
          }
          if (data['axleType'] == null || data['axleType'].toString().isEmpty) {
            data['axleType'] = vehicle.axleType;
          }
          
          // CRITICAL: Update driver details from vehicle
          if (vehicle.driverName != null && vehicle.driverName!.isNotEmpty) {
            data['driverName'] = vehicle.driverName;
            _logger.info('Updated driver name from vehicle: ${vehicle.driverName}');
          }
          if (vehicle.driverPhone != null && vehicle.driverPhone!.isNotEmpty) {
            data['driverPhone'] = vehicle.driverPhone;
            _logger.info('Updated driver phone from vehicle: ${vehicle.driverPhone}');
          }
          
          _logger.info('Vehicle and driver details updated successfully');
        } catch (vehicleError) {
          _logger.warning('Could not fetch vehicle/driver details: $vehicleError');
        }
      }
      
      // 2. FETCH AND POPULATE CLIENT DETAILS
      if (data['clientId'] != null && 
          (data['clientName'] == null || data['clientName'].toString().isEmpty)) {
        try {
          _logger.info('Fetching client details for ID: ${data['clientId']}');
          final client = await this.getClientById(data['clientId']);
          
          data['clientName'] = client.name;
          data['clientAddress'] = client.address;
          data['clientCity'] = client.city;
          
          _logger.info('Client details updated: ${data['clientName']}');
        } catch (clientError) {
          _logger.warning('Could not fetch client details: $clientError');
        }
      }
      
      // 3. FETCH AND POPULATE SUPPLIER + FIELD OPS DETAILS
      if (data['supplierId'] != null) {
        try {
          _logger.info('Fetching supplier details for ID: ${data['supplierId']}');
          final supplier = await this.getSupplierById(data['supplierId']);
          
          // Update supplier name
          if (data['supplierName'] == null || data['supplierName'].toString().isEmpty) {
            data['supplierName'] = supplier.name;
          }
          
          // CRITICAL: Update field operations from supplier contact person
          bool needsFieldOpsUpdate = data['fieldOps'] == null || 
                                   (data['fieldOps'] is Map && 
                                    (data['fieldOps']['name'] == null || 
                                     data['fieldOps']['name'].toString().isEmpty ||
                                     data['fieldOps']['name'] == 'N/A'));
          
          if (needsFieldOpsUpdate) {
            String fieldOpsName = 'Not assigned';
            String fieldOpsPhone = 'Not available';
            String fieldOpsEmail = 'Not available';
            
            // Try representative first, then contact person
            if (supplier.representativeName != null && supplier.representativeName!.isNotEmpty) {
              fieldOpsName = supplier.representativeName!;
              fieldOpsPhone = supplier.representativePhone ?? 'Not available';
              fieldOpsEmail = supplier.representativeEmail ?? 'Not available';
            } else if (supplier.contactName != null && supplier.contactName!.isNotEmpty) {
              fieldOpsName = supplier.contactName!;
              fieldOpsPhone = supplier.contactPhone ?? 'Not available';
              fieldOpsEmail = supplier.contactEmail ?? 'Not available';
            }
            
            data['fieldOps'] = {
              'name': fieldOpsName,
              'phone': fieldOpsPhone,
              'email': fieldOpsEmail
            };
            
            _logger.info('Field operations updated from supplier: $fieldOpsName');
          }
          
          _logger.info('Supplier details updated: ${supplier.name}');
        } catch (supplierError) {
          _logger.warning('Could not fetch supplier details: $supplierError');
        }
      }
      
      // 4. CALCULATE AND POPULATE FINANCIAL DATA
      _enrichFinancialData(data);
      
      // 5. ENSURE DEFAULT VALUES FOR MISSING FIELDS
      _setDefaultValues(data);
      
      // 6. FETCH ADDITIONAL TRIP DATA (materials, driver info, etc.)
      try {
        final additionalData = await _getAdditionalTripData(id);
        
        // Merge additional data into the main trip data
        if (additionalData.isNotEmpty) {
          data.addAll(additionalData);
          
          // Extract specific fields for compatibility
          if (additionalData['driverInfo'] != null) {
            data['driverName'] = additionalData['driverInfo']['name'] ?? data['driverName'];
            data['driverPhone'] = additionalData['driverInfo']['phone'] ?? data['driverPhone'];
          }
          
          if (additionalData['vehicleDetails'] != null) {
            data['vehicleNumber'] = additionalData['vehicleDetails']['vehicleNumber'] ?? data['vehicleNumber'];
            data['vehicleType'] = additionalData['vehicleDetails']['vehicleType'] ?? data['vehicleType'];
            data['vehicleSize'] = additionalData['vehicleDetails']['vehicleSize'] ?? data['vehicleSize'];
            data['vehicleCapacity'] = additionalData['vehicleDetails']['vehicleCapacity'] ?? data['vehicleCapacity'];
            data['axleType'] = additionalData['vehicleDetails']['axleType'] ?? data['axleType'];
          }
          
          if (additionalData['expiryInfo'] != null) {
            data['expiryDate'] = additionalData['expiryInfo']['expiryDate'] ?? data['expiryDate'];
            data['expiryTime'] = additionalData['expiryInfo']['expiryTime'] ?? data['expiryTime'];
          }
          
          if (additionalData['pickupInfo'] != null) {
            data['pickupDate'] = additionalData['pickupInfo']['pickupDate'] ?? data['pickupDate'];
            data['pickupTime'] = additionalData['pickupInfo']['pickupTime'] ?? data['pickupTime'];
          }
          
          if (additionalData['locationInfo'] != null) {
            data['clientCity'] = additionalData['locationInfo']['clientCity'] ?? data['clientCity'];
            data['destinationCity'] = additionalData['locationInfo']['destinationCity'] ?? data['destinationCity'];
            data['clientAddress'] = additionalData['locationInfo']['clientAddress'] ?? data['clientAddress'];
          }
          
          _logger.info('Additional data fetched and merged for trip: $id');
        }
      } catch (additionalDataError) {
        _logger.warning('Could not fetch additional data for trip $id: $additionalDataError');
        // Set defaults for missing additional data
        data['materials'] ??= [];
        data['lrNumbers'] ??= [];
        data['invoiceNumbers'] ??= [];
        data['ewayBillNumbers'] ??= [];
        data['gsmTracking'] ??= false;
      }
      
      try {
        final trip = Trip.fromJson(data);
        _logger.info('Successfully created Trip object for ID: $id');
        _verifyTripData(trip);
        return trip;
      } catch (parseError) {
        _logger.severe('Error parsing Trip from JSON: $parseError');
        _logger.severe('Problematic trip data: $data');
        rethrow;
      }
    } catch (e) {
      _logger.severe('Error fetching trip $id: $e');
      throw Exception('Failed to load trip: $e');
    }
  }

  // Enhanced method to calculate financial data
  void _enrichFinancialData(Map<String, dynamic> data) {
    try {
      _logger.info('Enriching financial data for trip: ${data['id']}');
      
      double clientFreight = _parseDoubleValue(data['clientFreight']);
      double supplierFreight = _parseDoubleValue(data['supplierFreight']);
      double advancePercentage = _parseDoubleValue(data['advancePercentage']);
      
      // Set default advance percentage if not provided
      if (advancePercentage <= 0) {
        advancePercentage = 30.0;
        data['advancePercentage'] = advancePercentage;
      }
      
      // Get pricing data if available
      double pricingTotal = 0.0;
      if (data['pricing'] != null && data['pricing'] is Map) {
        final pricing = data['pricing'] as Map<String, dynamic>;
        pricingTotal = _parseDoubleValue(pricing['totalAmount']);
      }
      
      // Calculate missing financial values
      if (clientFreight <= 0 || supplierFreight <= 0) {
        _logger.info('Financial data missing or zero, calculating from available data');
        
        if (pricingTotal > 0) {
          // Use pricing data as baseline
          if (clientFreight <= 0) {
            clientFreight = pricingTotal;
          }
          if (supplierFreight <= 0) {
            supplierFreight = clientFreight * 0.9; // Assume 90% for supplier
          }
          _logger.info('Calculated from pricing: client=₹$clientFreight, supplier=₹$supplierFreight');
        } else {
          // Use reasonable defaults if no pricing data
          if (clientFreight <= 0 && supplierFreight <= 0) {
            // Estimate based on route distance or use industry defaults
            clientFreight = _estimateFreightAmount(
              data['source']?.toString() ?? '', 
              data['destination']?.toString() ?? ''
            );
            supplierFreight = clientFreight * 0.9;
          } else if (clientFreight > 0 && supplierFreight <= 0) {
            supplierFreight = clientFreight * 0.9;
          } else if (supplierFreight > 0 && clientFreight <= 0) {
            clientFreight = supplierFreight / 0.9;
          }
          _logger.info('Used estimation: client=₹$clientFreight, supplier=₹$supplierFreight');
        }
        
        // Update the data
        data['clientFreight'] = clientFreight;
        data['supplierFreight'] = supplierFreight;
      }
      
      // Calculate derived financial values
      final double margin = clientFreight - supplierFreight;
      final double advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
      final double balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
      
      // Update all financial fields
      data['margin'] = margin;
      data['advanceSupplierFreight'] = advanceSupplierFreight;
      data['balanceSupplierFreight'] = balanceSupplierFreight;
      
      _logger.info('Financial enrichment completed:');
      _logger.info('Client: ₹$clientFreight, Supplier: ₹$supplierFreight, Margin: ₹$margin');
      _logger.info('Advance (${advancePercentage}%): ₹$advanceSupplierFreight, Balance: ₹$balanceSupplierFreight');
    } catch (e) {
      _logger.warning('Error enriching financial data: $e');
    }
  }

  // Helper method to parse double values safely
  double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to estimate freight amount based on route
  double _estimateFreightAmount(String source, String destination) {
    // Enhanced estimation based on major city routes
    final Map<String, double> cityMultipliers = {
      'mumbai': 1.5,
      'delhi': 1.4,
      'bangalore': 1.3,
      'chennai': 1.3,
      'kolkata': 1.2,
      'hyderabad': 1.2,
      'pune': 1.4,
      'ahmedabad': 1.3,
      'jaipur': 1.2,
      'lucknow': 1.1,
    };
    
    final String sourceLower = source.toLowerCase();
    final String destLower = destination.toLowerCase();
    
    double multiplier = 1.0;
    
    // Check for major cities in source or destination
    for (final city in cityMultipliers.keys) {
      if (sourceLower.contains(city) || destLower.contains(city)) {
        multiplier = cityMultipliers[city]!;
        break;
      }
    }
    
    // Base freight amount with city-based multiplier
    double baseAmount = 15000.0;
    
    // Additional logic for long-distance routes
    if ((sourceLower.contains('mumbai') && destLower.contains('delhi')) ||
        (sourceLower.contains('delhi') && destLower.contains('mumbai'))) {
      baseAmount = 25000.0;
    } else if ((sourceLower.contains('bangalore') && destLower.contains('delhi')) ||
               (sourceLower.contains('delhi') && destLower.contains('bangalore'))) {
      baseAmount = 30000.0;
    }
    
    return baseAmount * multiplier;
  }

  // Helper method to set default values for missing fields
  void _setDefaultValues(Map<String, dynamic> data) {
    // Driver defaults
    if (data['driverName'] == null || data['driverName'].toString().isEmpty) {
      data['driverName'] = 'Driver not assigned';
    }
    if (data['driverPhone'] == null || data['driverPhone'].toString().isEmpty) {
      data['driverPhone'] = 'Phone not available';
    }
    
    // Field operations defaults
    if (data['fieldOps'] == null || !(data['fieldOps'] is Map)) {
      data['fieldOps'] = {
        'name': 'Field ops not assigned',
        'phone': 'Phone not available',
        'email': 'Email not available'
      };
    } else {
      final fieldOps = data['fieldOps'] as Map<String, dynamic>;
      if (fieldOps['name'] == null || fieldOps['name'].toString().isEmpty) {
        fieldOps['name'] = 'Field ops not assigned';
      }
      if (fieldOps['phone'] == null || fieldOps['phone'].toString().isEmpty) {
        fieldOps['phone'] = 'Phone not available';
      }
      if (fieldOps['email'] == null || fieldOps['email'].toString().isEmpty) {
        fieldOps['email'] = 'Email not available';
      }
    }
    
    // Payment status defaults
    if (data['advancePaymentStatus'] == null) {
      data['advancePaymentStatus'] = 'Not Started';
    }
    if (data['balancePaymentStatus'] == null) {
      data['balancePaymentStatus'] = 'Not Started';
    }
    
    // LR Numbers default
    if (data['lrNumbers'] == null) {
      data['lrNumbers'] = [];
    }
    
    // Date defaults
    if (data['startDate'] == null) {
      data['startDate'] = DateTime.now().toIso8601String();
    }
  }

  // Helper method to verify trip data completeness
  void _verifyTripData(Trip trip) {
    // Log verification results
    _logger.info('Trip verification for ${trip.id}:');
    _logger.info('- Driver: ${trip.driverName} (${trip.driverPhone})');
    _logger.info('- Field Ops: ${trip.fieldOps?.name ?? 'N/A'} (${trip.fieldOps?.phone ?? 'N/A'})');
    _logger.info('- Financial: Client=₹${trip.clientFreight}, Supplier=₹${trip.supplierFreight}');
    _logger.info('- Payments: Advance=₹${trip.advanceSupplierFreight}, Balance=₹${trip.balanceSupplierFreight}');
    
    // Warn about potential issues
    if (trip.clientFreight == null || trip.clientFreight! <= 0) {
      _logger.warning('ISSUE: Trip ${trip.id} has invalid client freight: ${trip.clientFreight}');
    }
    if (trip.supplierFreight == null || trip.supplierFreight! <= 0) {
      _logger.warning('ISSUE: Trip ${trip.id} has invalid supplier freight: ${trip.supplierFreight}');
    }
    if (trip.driverName == null || trip.driverName!.contains('not assigned')) {
      _logger.warning('ISSUE: Trip ${trip.id} has no driver assigned');
    }
    if (trip.fieldOps == null || trip.fieldOps!.name.contains('not assigned')) {
      _logger.warning('ISSUE: Trip ${trip.id} has no field operations contact');
    }
  }

  Future<Trip> createTrip(Map<String, dynamic> tripData) async {
    try {
      // Process any DateTime objects in the data
      final processedTripData = this._processDateFields(Map<String, dynamic>.from(tripData));
      
      _logger.info('Creating trip: ${processedTripData['orderNumber']}');
      _logger.info('JSON data length: ${jsonEncode(processedTripData).length}');
      
      // Check for required fields
      final requiredFields = ['source', 'destination', 'clientId', 'supplierId', 'vehicleId', 'startDate'];
      final missingFields = requiredFields.where((field) => 
        processedTripData[field] == null || processedTripData[field].toString().isEmpty
      ).toList();
      
      if (missingFields.isNotEmpty) {
        throw Exception('Missing required fields: ${missingFields.join(', ')}');
      }
      
      // Extract and validate financial values with better logging
      final clientFreightRaw = processedTripData['clientFreight'];
      final supplierFreightRaw = processedTripData['supplierFreight'];
      final advancePercentageRaw = processedTripData['advancePercentage'];
      
      _logger.info('Raw financial values from form:');
      _logger.info('- clientFreight: $clientFreightRaw (${clientFreightRaw.runtimeType})');
      _logger.info('- supplierFreight: $supplierFreightRaw (${supplierFreightRaw.runtimeType})');
      _logger.info('- advancePercentage: $advancePercentageRaw (${advancePercentageRaw.runtimeType})');
      
      // Parse values to ensure they're numeric with improved error handling
      final clientFreight = _parseFinancialValue(clientFreightRaw, 'clientFreight');
      final supplierFreight = _parseFinancialValue(supplierFreightRaw, 'supplierFreight');
      final advancePercentage = _parseFinancialValue(advancePercentageRaw, 'advancePercentage', defaultValue: 30.0);
      
      // Calculate derived values
      final margin = clientFreight - supplierFreight;
      final advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
      final balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
      
      // Log the freight calculation details
      _logger.info('Financial calculations:');
      _logger.info('- Client Freight: ₹$clientFreight');
      _logger.info('- Supplier Freight: ₹$supplierFreight');
      _logger.info('- Margin: ₹$margin (${margin > 0 ? '+' : ''}${(margin/clientFreight*100).toStringAsFixed(2)}%)');
      _logger.info('- Advance Percentage: $advancePercentage%');
      _logger.info('- Advance Amount: ₹$advanceSupplierFreight');
      _logger.info('- Balance Amount: ₹$balanceSupplierFreight');
      
      // Validate financial calculations
      if (clientFreight < 0 || supplierFreight < 0 || advancePercentage < 0 || advancePercentage > 100) {
        throw Exception('Invalid financial values: Client=₹$clientFreight, Supplier=₹$supplierFreight, Advance=$advancePercentage%');
      }
      
      if (supplierFreight > clientFreight) {
        _logger.warning('Supplier freight (₹$supplierFreight) is higher than client freight (₹$clientFreight). Negative margin: ₹$margin');
      }
      
      // Store additional data for later saving
      final additionalData = {
        'invoiceNumbers': processedTripData['invoiceNumbers'] ?? [],
        'ewayBillNumbers': processedTripData['ewayBillNumbers'] ?? [],
        'materials': processedTripData['materials'] ?? [],
        'documents': processedTripData['documents'] ?? [],
        'fieldOps': {
          'name': processedTripData['fieldOpsName'] ?? '',
          'phone': processedTripData['fieldOpsPhone'] ?? '',
          'email': processedTripData['fieldOpsEmail'] ?? '',
        },
        'driverInfo': {
          'name': processedTripData['driverName'] ?? '',
          'phone': processedTripData['driverPhone'] ?? '',
        },
        'vehicleDetails': {
          'vehicleNumber': processedTripData['vehicleNumber'],
          'vehicleType': processedTripData['vehicleType'],
          'vehicleSize': processedTripData['vehicleSize'],
          'vehicleCapacity': processedTripData['vehicleCapacity'],
          'axleType': processedTripData['axleType'],
        },
        'expiryInfo': {
          'expiryDate': processedTripData['expiryDate'],
          'expiryTime': processedTripData['expiryTime'],
        },
        'pickupInfo': {
          'pickupDate': processedTripData['pickupDate'],
          'pickupTime': processedTripData['pickupTime'],
        },
        'locationInfo': {
          'clientCity': processedTripData['clientCity'],
          'destinationCity': processedTripData['destination'], // Store as separate field
          'clientAddress': processedTripData['clientAddress'],
        },
        'gsmTracking': processedTripData['gsmTracking'] ?? false,
        // Store LR numbers separately to avoid schema validation errors
        'lrNumbers': processedTripData['lrNumbers'] ?? [],
      };
      
      // If we have vehicleId but missing other vehicle details, try to fetch them
      if (processedTripData['vehicleId'] != null && 
          (processedTripData['vehicleNumber'] == null || 
           processedTripData['vehicleType'] == null)) {
        try {
          _logger.info('Fetching vehicle details for ID: ${processedTripData['vehicleId']}');
          final vehicle = await this.getVehicleById(processedTripData['vehicleId']);
          
          // Update additional data with vehicle details
          additionalData['driverInfo'] = {
            'name': vehicle.driverName ?? processedTripData['driverName'] ?? '',
            'phone': vehicle.driverPhone ?? processedTripData['driverPhone'] ?? '',
          };
          
          additionalData['vehicleDetails'] = {
            'vehicleNumber': vehicle.vehicleNumber ?? processedTripData['vehicleNumber'],
            'vehicleType': vehicle.vehicleType ?? processedTripData['vehicleType'],
            'vehicleSize': vehicle.vehicleSize ?? processedTripData['vehicleSize'],
            'vehicleCapacity': vehicle.vehicleCapacity ?? processedTripData['vehicleCapacity'],
            'axleType': vehicle.axleType ?? processedTripData['axleType'],
          };
          
          _logger.info('Added vehicle details to additional data: ${vehicle.vehicleNumber}');
        } catch (vehicleError) {
          _logger.warning('Could not fetch vehicle details: $vehicleError');
        }
      }
      
      // Create a clean request payload that only includes backend-expected fields
      final apiRequestData = {
        'clientId': processedTripData['clientId'],
        'supplierId': processedTripData['supplierId'],
        'vehicleId': processedTripData['vehicleId'],
        'source': processedTripData['source'],
        'destination': processedTripData['destination'],
        'distance': processedTripData['distance'],
        'startDate': processedTripData['startDate'],
        'orderNumber': processedTripData['orderNumber'],
        'status': processedTripData['status'] ?? 'Booked',
        'pricing': {
          'baseAmount': clientFreight,
          'gst': 0, // Set appropriate GST if available
          'totalAmount': clientFreight,
        },
        // IMPORTANT: Include all financial fields explicitly
        'clientFreight': clientFreight,
        'supplierFreight': supplierFreight,
        'advancePercentage': advancePercentage,
        'margin': margin,
        'advanceSupplierFreight': advanceSupplierFreight,
        'balanceSupplierFreight': balanceSupplierFreight,
        // Payment status fields
        'advancePaymentStatus': processedTripData['advancePaymentStatus'] ?? 'Pending',
        'balancePaymentStatus': processedTripData['balancePaymentStatus'] ?? 'Pending',
      };
      
      // Log the complete request data for debugging
      _logger.info('API Request Data:');
      _logger.info('- Financial fields: clientFreight=$clientFreight, supplierFreight=$supplierFreight, margin=$margin');
      _logger.info('- Payment fields: advance=$advanceSupplierFreight, balance=$balanceSupplierFreight, percentage=$advancePercentage%');
      _logger.info('- Request keys: ${apiRequestData.keys.join(', ')}');
      
      final response = await _makeRequest(
        'POST',
        '/trips',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(apiRequestData),
      );

      final data = jsonDecode(response.body);
      _logger.info('Trip created successfully: ${data['id']}');
      
      final tripId = data['id'];
      
      // Now save additional data as separate entities
      await _saveAdditionalTripData(tripId, additionalData);
      
      // Merge calculated values with API response data to ensure client-side consistency
      Map<String, dynamic> mergedData = Map.from(data);
      
      // IMPORTANT: Ensure all financial values are properly set in the response
      mergedData['clientFreight'] = clientFreight;
      mergedData['supplierFreight'] = supplierFreight;
      mergedData['advancePercentage'] = advancePercentage;
      mergedData['margin'] = margin;
      mergedData['advanceSupplierFreight'] = advanceSupplierFreight;
      mergedData['balanceSupplierFreight'] = balanceSupplierFreight;
      
      // Merge additional data back into the trip object for client-side use
      mergedData.addAll({
        'invoiceNumbers': additionalData['invoiceNumbers'],
        'ewayBillNumbers': additionalData['ewayBillNumbers'],
        'materials': additionalData['materials'],
        'documents': additionalData['documents'],
        'fieldOps': additionalData['fieldOps'],
        'driverName': additionalData['driverInfo']['name'],
        'driverPhone': additionalData['driverInfo']['phone'],
        'vehicleNumber': additionalData['vehicleDetails']['vehicleNumber'],
        'vehicleType': additionalData['vehicleDetails']['vehicleType'],
        'vehicleSize': additionalData['vehicleDetails']['vehicleSize'],
        'vehicleCapacity': additionalData['vehicleDetails']['vehicleCapacity'],
        'axleType': additionalData['vehicleDetails']['axleType'],
        'expiryDate': additionalData['expiryInfo']['expiryDate'],
        'expiryTime': additionalData['expiryInfo']['expiryTime'],
        'pickupDate': additionalData['pickupInfo']['pickupDate'],
        'pickupTime': additionalData['pickupInfo']['pickupTime'],
        'clientCity': additionalData['locationInfo']['clientCity'],
        'destinationCity': additionalData['locationInfo']['destinationCity'],
        'clientAddress': additionalData['locationInfo']['clientAddress'],
        'gsmTracking': additionalData['gsmTracking'],
        // Add LR numbers for client-side use (stored as document metadata)
        'lrNumbers': additionalData['lrNumbers'],
      });
      
      // Log the final merged data
      _logger.info('Final trip data after merge:');
      _logger.info('- clientFreight: ${mergedData['clientFreight']}');
      _logger.info('- supplierFreight: ${mergedData['supplierFreight']}');
      _logger.info('- margin: ${mergedData['margin']}');
      _logger.info('- advanceSupplierFreight: ${mergedData['advanceSupplierFreight']}');
      _logger.info('- balanceSupplierFreight: ${mergedData['balanceSupplierFreight']}');
      
      // Set payment statuses
      mergedData['advancePaymentStatus'] = processedTripData['advancePaymentStatus'] ?? 'Pending';
      mergedData['balancePaymentStatus'] = processedTripData['balancePaymentStatus'] ?? 'Pending';
      
      return Trip.fromJson(mergedData);
    } catch (e) {
      _logger.severe('Error creating trip: $e');
      
      // Check if this is a DateTime serialization error
      if (e.toString().contains('Converting object to an encodable object failed') && 
          e.toString().contains('DateTime')) {
        throw Exception('Failed to create trip: Date format error. Please ensure all dates are properly formatted.');
      }
      
      throw Exception('Failed to create trip: $e');
    }
  }
  
  // Helper method to parse financial values with better error handling
  double _parseFinancialValue(dynamic value, String fieldName, {double defaultValue = 0.0}) {
    if (value == null) {
      _logger.info('$fieldName is null, using default: $defaultValue');
      return defaultValue;
    }
    
    if (value is num) {
      return value.toDouble();
    }
    
    if (value is String) {
      // Remove any commas that might cause parsing errors
      final cleanValue = value.replaceAll(',', '').trim();
      if (cleanValue.isEmpty) {
        _logger.info('$fieldName is empty string, using default: $defaultValue');
        return defaultValue;
      }
      
      final parsed = double.tryParse(cleanValue);
      if (parsed == null) {
        _logger.warning('Could not parse $fieldName value "$value", using default: $defaultValue');
        return defaultValue;
      }
      
      return parsed;
    }
    
    try {
      // Try to convert to double via toString() as a last resort
      final stringValue = value.toString();
      final parsed = double.tryParse(stringValue.replaceAll(',', ''));
      if (parsed != null) {
        return parsed;
      }
    } catch (e) {
      _logger.warning('Error parsing $fieldName value: $value, error: $e');
    }
    
    _logger.warning('Using default value for $fieldName: $defaultValue');
    return defaultValue;
  }

  // Add a new method for the improved payment processing endpoint
  Future<Trip> processPayment(
    String tripId, {
    required String paymentType, // 'advance' or 'balance'
    required String paymentStatus,
    String? utrNumber,
    String? paymentMethod,
  }) async {
    try {
      _logger.info('Processing $paymentType payment for trip $tripId with status: $paymentStatus');
      
      // First get the current trip to ensure it exists and to get the correct financial data
      final currentTrip = await getTripById(tripId);
      _logger.info('Found trip for payment processing: ${currentTrip.id}, current status: ${currentTrip.status}');
      
      // Create update data for direct payment update
      final Map<String, dynamic> updateData = {};
      
      // Set payment status based on type
      if (paymentType == 'advance') {
        updateData['advancePaymentStatus'] = paymentStatus;
      } else {
        updateData['balancePaymentStatus'] = paymentStatus;
      }
      
      // Add optional fields if provided
      if (utrNumber != null && utrNumber.isNotEmpty) {
        updateData['utrNumber'] = utrNumber;
      }
      
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        updateData['paymentMethod'] = paymentMethod;
      }
      
      // Add payment date if payment is marked as paid
      if (paymentStatus == 'Paid') {
        updateData['paymentDate'] = DateTime.now().toIso8601String();
      }
      
      _logger.info('Payment data: ${jsonEncode(updateData)}');
      
      try {
        // Use the payment-status endpoint that is known to work
        final response = await _makeRequest(
          'PATCH',
          '/trips/$tripId/payment-status',
        headers: {
          'Content-Type': 'application/json',
          },
          body: jsonEncode(updateData),
        );
        
        final data = jsonDecode(response.body);
        _logger.info('Payment processed successfully for trip $tripId');
        
        // Update status if needed
        if (paymentStatus == 'Paid') {
          Map<String, String> statusUpdate = {};
          
          if (paymentType == 'advance') {
            statusUpdate['status'] = 'In Transit';
          } else if (paymentType == 'balance' && currentTrip.podUploaded) {
            statusUpdate['status'] = 'Completed';
          }
          
          if (statusUpdate.isNotEmpty) {
            _logger.info('Updating trip status: ${statusUpdate['status']}');
            await this.updateTrip(tripId, statusUpdate);
          }
        }
        
        // Get the updated trip with all payment changes
        final updatedTrip = await getTripById(tripId);
        return updatedTrip;
      } catch (apiError) {
        _logger.severe('API error processing payment: $apiError');
        
        // Try direct trip update as a fallback
        _logger.info('Trying fallback method using direct trip update');
        
        // Try update via direct patch to the trip
        final updatedTrip = await this.updateTrip(tripId, updateData);
        
        // Update status as needed
        if (paymentStatus == 'Paid') {
          Map<String, String> statusUpdate = {};
          
          if (paymentType == 'advance') {
            statusUpdate['status'] = 'In Transit';
          } else if (paymentType == 'balance' && currentTrip.podUploaded) {
            statusUpdate['status'] = 'Completed';
          }
          
          if (statusUpdate.isNotEmpty) {
            _logger.info('Updating trip status: ${statusUpdate['status']}');
            await this.updateTrip(tripId, statusUpdate);
          }
        }
        
        // Get the final trip with all updates
        return await getTripById(tripId);
          }
        } catch (e) {
      _logger.severe('Error processing payment: $e');
      throw Exception('Failed to process payment: $e');
    }
  }

  // Utility Methods
  Future<bool> testApiConnection() async {
    try {
      await _checkConnection();
      return _isConnected;
    } catch (e) {
      _logger.warning('API connection test failed: $e');
      return false;
    }
  }

  String getDocumentUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // If already a full URL, return as is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Otherwise, construct the full URL
    return '$_baseUrl/files/$relativePath';
  }

  Future<Uint8List?> downloadDocument(String documentUrl) async {
    try {
      // Clean up the URL to avoid malformed URLs like "/apihttps://..."
      String cleanUrl = documentUrl;
      
      // If the URL starts with our base URL path, it might be malformed
      if (cleanUrl.startsWith('/api') && cleanUrl.contains('http')) {
        // Extract the actual URL part after /api
        final httpIndex = cleanUrl.indexOf('http');
        if (httpIndex > 0) {
          cleanUrl = cleanUrl.substring(httpIndex);
        }
      }
      
      // If it's a relative path, construct the full URL
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = getDocumentUrl(cleanUrl);
      }
      
      _logger.info('Downloading document from: $cleanUrl');
      
      final response = await _makeRequest('GET', cleanUrl);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download document: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error downloading document from $documentUrl: $e');
      throw Exception('Failed to download document: $e');
    }
  }

  // Trip document upload
  Future<void> uploadDocument(String tripId, Map<String, dynamic> docData) async {
    try {
      _logger.info('Uploading document for trip $tripId: ${docData['type']}');
      
      // Always try metadata-only upload first to avoid server errors
      // This ensures document records are created even if file upload fails
      try {
        final metadataResponse = await _makeRequest(
          'POST',
          '/trips/$tripId/documents',
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'type': docData['type'] ?? 'Unknown',
            'filename': docData['filename'] ?? 'document',
            'uploadedAt': docData['uploadedAt'] ?? DateTime.now().toIso8601String(),
            'number': docData['number'], // Include LR number if provided
          }),
        );
        
        _logger.info('Document metadata uploaded successfully for trip $tripId');
        return; // Success - metadata uploaded
        
      } catch (metadataError) {
        _logger.warning('Metadata upload failed, trying multipart: $metadataError');
        
        // If metadata upload fails, try multipart as fallback
        if (docData['file'] != null) {
          final fileData = docData['file'];
          
          // Handle both PlatformFile and Map structures
          Uint8List? fileBytes;
          String? filename;
          
          if (fileData is PlatformFile) {
            fileBytes = fileData.bytes;
            filename = fileData.name;
          } else if (fileData is Map<String, dynamic>) {
            if (fileData['bytes'] is Uint8List) {
              fileBytes = fileData['bytes'];
            } else if (fileData['bytes'] is List<int>) {
              fileBytes = Uint8List.fromList(List<int>.from(fileData['bytes']));
            }
            filename = fileData['name'] ?? docData['filename'];
          }
          
          if (fileBytes != null && filename != null) {
            // Create multipart request
            var request = http.MultipartRequest(
              'POST',
              Uri.parse('$_baseUrl/trips/$tripId/documents'),
            );
            
            // Add file bytes
            final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';
            final multipartFile = http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: filename,
              contentType: MediaType.parse(mimeType),
            );
            request.files.add(multipartFile);
            
            // Add metadata fields
            request.fields['type'] = docData['type'] ?? 'Unknown';
            request.fields['filename'] = filename;
            request.fields['uploadedAt'] = docData['uploadedAt'] ?? DateTime.now().toIso8601String();
            if (docData['number'] != null) {
              request.fields['number'] = docData['number'].toString();
            }
            
            // Send the request with timeout
            final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
            final response = await http.Response.fromStream(streamedResponse);
            
            if (response.statusCode == 200 || response.statusCode == 201) {
              _logger.info('Document uploaded successfully via multipart for trip $tripId');
              return;
            } else {
              String errorMessage = 'Upload failed: ${response.statusCode}';
              try {
                final errorBody = jsonDecode(response.body);
                if (errorBody['message'] != null) {
                  errorMessage = errorBody['message'];
                }
              } catch (_) {
                // Ignore JSON parsing errors
              }
              throw Exception(errorMessage);
            }
          }
        }
        
        // If both methods fail, rethrow the original metadata error
        throw Exception('Document upload failed: $metadataError');
      }
      
    } catch (e) {
      _logger.severe('Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  // Trip update method
  Future<Trip> updateTrip(String id, Map<String, dynamic> updateData) async {
    try {
      _logger.info('Updating trip $id with data: ${jsonEncode(updateData)}');
      
      final response = await _makeRequest(
        'PATCH',
        '/trips/$id',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);
      _logger.info('Trip updated successfully: $id');
      return Trip.fromJson(data);
    } catch (e) {
      _logger.severe('Error updating trip: $e');
      throw Exception('Failed to update trip: $e');
    }
  }

  // Payment status update method
  Future<Trip> updatePaymentStatus(
    String tripId,
    Map<String, dynamic> paymentData
  ) async {
    try {
      return await processPayment(
        tripId,
        paymentType: paymentData['paymentType'] ?? 'advance',
        paymentStatus: paymentData['status'] ?? 'Paid',
        utrNumber: paymentData['utrNumber'],
        paymentMethod: paymentData['paymentMethod'],
      );
    } catch (e) {
      _logger.severe('Error updating payment status: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Financial data synchronization
  Future<Trip> synchronizeFinancialData(String tripId) async {
    try {
      _logger.info('Synchronizing financial data for trip $tripId');
      
      // Get the current trip
      final trip = await getTripById(tripId);
      
      // Check if financial data needs updating
      if (trip.clientFreight != null && trip.supplierFreight != null) {
        final clientFreight = trip.clientFreight!;
        final supplierFreight = trip.supplierFreight!;
        final advancePercentage = trip.advancePercentage ?? 30.0;
        
        // Calculate derived values
        final margin = clientFreight - supplierFreight;
        final advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
        final balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
        
        // Update trip with calculated values if they differ significantly
        final updateData = <String, dynamic>{};
        
        if ((trip.margin ?? 0) != margin) {
          updateData['margin'] = margin;
        }
        if ((trip.advanceSupplierFreight ?? 0) != advanceSupplierFreight) {
          updateData['advanceSupplierFreight'] = advanceSupplierFreight;
        }
        if ((trip.balanceSupplierFreight ?? 0) != balanceSupplierFreight) {
          updateData['balanceSupplierFreight'] = balanceSupplierFreight;
        }
        
        if (updateData.isNotEmpty) {
          _logger.info('Updating financial data for trip $tripId: ${updateData.keys.join(', ')}');
          return await updateTrip(tripId, updateData);
        }
      }
      
      return trip;
    } catch (e) {
      _logger.severe('Error synchronizing financial data: $e');
      throw Exception('Failed to synchronize financial data: $e');
    }
  }

  // Date field processing helper
  Map<String, dynamic> _processDateFields(Map<String, dynamic> data) {
    // List of common date field names
    final dateFields = [
      'pickupDate', 'deliveryDate', 'expiryDate', 'bookingDate',
      'loadingDate', 'unloadingDate', 'createdAt', 'updatedAt', 'startDate'
    ];
    
    final processedData = Map<String, dynamic>.from(data);
    
    // Process known date fields
    for (final field in dateFields) {
      if (processedData.containsKey(field) && processedData[field] is DateTime) {
        processedData[field] = (processedData[field] as DateTime).toIso8601String();
      }
    }
    
    // Process any other fields that might contain DateTime objects
    processedData.forEach((key, value) {
      if (value is DateTime) {
        processedData[key] = value.toIso8601String();
      } else if (value is Map) {
        processedData[key] = _processDateFieldsInMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        processedData[key] = _processDateFieldsInList(List.from(value));
      }
    });
    
    return processedData;
  }
  
  // Helper method to process date fields in a map
  Map<String, dynamic> _processDateFieldsInMap(Map<String, dynamic> value) {
    final processedMap = Map<String, dynamic>.from(value);
    processedMap.forEach((key, val) {
      if (val is DateTime) {
        processedMap[key] = val.toIso8601String();
      } else if (val is Map) {
        processedMap[key] = _processDateFieldsInMap(Map<String, dynamic>.from(val));
      } else if (val is List) {
        processedMap[key] = _processDateFieldsInList(List.from(val));
      }
    });
    return processedMap;
  }
  
  // Helper method to process date fields in a list
  List _processDateFieldsInList(List value) {
    final processedList = List.from(value);
    for (int i = 0; i < processedList.length; i++) {
      if (processedList[i] is DateTime) {
        processedList[i] = (processedList[i] as DateTime).toIso8601String();
      } else if (processedList[i] is Map) {
        processedList[i] = _processDateFieldsInMap(Map<String, dynamic>.from(processedList[i]));
      } else if (processedList[i] is List) {
        processedList[i] = _processDateFieldsInList(List.from(processedList[i]));
      }
    }
    return processedList;
  }

  // Helper method to save additional trip data as separate entities
  Future<void> _saveAdditionalTripData(String tripId, Map<String, dynamic> additionalData) async {
    try {
      _logger.info('Saving additional data for trip: $tripId');
      
      // Save materials as trip items
      if (additionalData['materials'] != null && additionalData['materials'].isNotEmpty) {
        try {
          for (final material in additionalData['materials']) {
            await _makeRequest(
              'POST',
              '/trips/$tripId/materials',
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'tripId': tripId,
                'name': material['name'],
                'weight': material['weight'],
                'unit': material['unit'],
                'ratePerMT': material['ratePerMT'],
                'totalCost': (material['weight'] ?? 0) * (material['ratePerMT'] ?? 0),
              }),
            );
          }
          _logger.info('Materials saved successfully for trip: $tripId');
        } catch (materialError) {
          _logger.warning('Failed to save materials: $materialError');
        }
      }
      
      // Save LR numbers, invoice numbers, and e-way bill numbers as trip documents
      final documentTypes = [
        {'numbers': additionalData['lrNumbers'], 'type': 'LR'},
        {'numbers': additionalData['invoiceNumbers'], 'type': 'Invoice'},
        {'numbers': additionalData['ewayBillNumbers'], 'type': 'E-way Bill'},
      ];
      
      for (final docType in documentTypes) {
        if (docType['numbers'] != null && docType['numbers'].isNotEmpty) {
          try {
            for (final number in docType['numbers']) {
              await _makeRequest(
                'POST',
                '/trips/$tripId/document-numbers',
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'tripId': tripId,
                  'type': docType['type'],
                  'number': number,
                  'createdAt': DateTime.now().toIso8601String(),
                }),
              );
            }
            _logger.info('${docType['type']} numbers saved successfully for trip: $tripId');
          } catch (docError) {
            _logger.warning('Failed to save ${docType['type']} numbers: $docError');
          }
        }
      }
      
      // Save driver information as trip metadata
      if (additionalData['driverInfo'] != null) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'driver',
              'data': additionalData['driverInfo'],
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('Driver information saved successfully for trip: $tripId');
        } catch (driverError) {
          _logger.warning('Failed to save driver information: $driverError');
        }
      }
      
      // Save vehicle details as trip metadata
      if (additionalData['vehicleDetails'] != null) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'vehicle',
              'data': additionalData['vehicleDetails'],
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('Vehicle details saved successfully for trip: $tripId');
        } catch (vehicleError) {
          _logger.warning('Failed to save vehicle details: $vehicleError');
        }
      }
      
      // Save field operations information as trip metadata
      if (additionalData['fieldOps'] != null) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'fieldOps',
              'data': additionalData['fieldOps'],
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('Field operations info saved successfully for trip: $tripId');
        } catch (fieldOpsError) {
          _logger.warning('Failed to save field operations info: $fieldOpsError');
        }
      }
      
      // Save expiry information as trip metadata
      if (additionalData['expiryInfo'] != null && 
          (additionalData['expiryInfo']['expiryDate'] != null || 
           additionalData['expiryInfo']['expiryTime'] != null)) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'expiry',
              'data': additionalData['expiryInfo'],
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('Expiry information saved successfully for trip: $tripId');
        } catch (expiryError) {
          _logger.warning('Failed to save expiry information: $expiryError');
        }
      }
      
      // Save GSM tracking preference as trip metadata
      if (additionalData['gsmTracking'] != null) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'tracking',
              'data': {'gsmTracking': additionalData['gsmTracking']},
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('GSM tracking preference saved successfully for trip: $tripId');
        } catch (trackingError) {
          _logger.warning('Failed to save GSM tracking preference: $trackingError');
        }
      }
      
      // Save pickup information as trip metadata
      if (additionalData['pickupInfo'] != null) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'pickup',
              'data': additionalData['pickupInfo'],
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('Pickup information saved successfully for trip: $tripId');
        } catch (pickupError) {
          _logger.warning('Failed to save pickup information: $pickupError');
        }
      }
      
      // Save location information as trip metadata
      if (additionalData['locationInfo'] != null) {
        try {
          await _makeRequest(
            'POST',
            '/trips/$tripId/metadata',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tripId': tripId,
              'category': 'location',
              'data': additionalData['locationInfo'],
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          _logger.info('Location information saved successfully for trip: $tripId');
        } catch (locationError) {
          _logger.warning('Failed to save location information: $locationError');
        }
      }
      
      // Save any uploaded documents
      if (additionalData['documents'] != null && additionalData['documents'].isNotEmpty) {
        try {
          for (final doc in additionalData['documents']) {
            await _makeRequest(
              'POST',
              '/trips/$tripId/document-metadata',
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'tripId': tripId,
                'type': doc['type'],
                'fileName': doc['fileName'],
                'createdAt': DateTime.now().toIso8601String(),
              }),
            );
          }
          _logger.info('Document metadata saved successfully for trip: $tripId');
        } catch (docMetaError) {
          _logger.warning('Failed to save document metadata: $docMetaError');
        }
      }
      
      _logger.info('All additional data saved successfully for trip: $tripId');
    } catch (e) {
      _logger.severe('Error saving additional trip data: $e');
      // Don't throw error here as the main trip was created successfully
      // The additional data can be added later if needed
    }
  }

  // Helper method to retrieve additional trip data
  Future<Map<String, dynamic>> _getAdditionalTripData(String tripId) async {
    try {
      final Map<String, dynamic> additionalData = {};
      
      // Get materials - handle 404 gracefully
      try {
        final materialsResponse = await _makeRequest('GET', '/trips/$tripId/materials');
        additionalData['materials'] = jsonDecode(materialsResponse.body);
        _logger.info('Materials data fetched for trip $tripId');
      } catch (e) {
        if (e.toString().contains('404') || e.toString().contains('Cannot GET')) {
          _logger.info('Materials endpoint not available for trip $tripId - using empty list');
          additionalData['materials'] = [];
        } else {
          _logger.warning('Error fetching materials for trip $tripId: $e');
          additionalData['materials'] = [];
        }
      }
      
      // Get document numbers - handle 404 gracefully
      try {
        final docNumbersResponse = await _makeRequest('GET', '/trips/$tripId/document-numbers');
        final docNumbers = jsonDecode(docNumbersResponse.body) as List;
        
        additionalData['lrNumbers'] = docNumbers.where((doc) => doc['type'] == 'LR').map((doc) => doc['number']).toList();
        additionalData['invoiceNumbers'] = docNumbers.where((doc) => doc['type'] == 'Invoice').map((doc) => doc['number']).toList();
        additionalData['ewayBillNumbers'] = docNumbers.where((doc) => doc['type'] == 'E-way Bill').map((doc) => doc['number']).toList();
        _logger.info('Document numbers fetched for trip $tripId');
      } catch (e) {
        if (e.toString().contains('404') || e.toString().contains('Cannot GET')) {
          _logger.info('Document numbers endpoint not available for trip $tripId - using empty lists');
        } else {
          _logger.warning('Error fetching document numbers for trip $tripId: $e');
        }
        additionalData['lrNumbers'] = [];
        additionalData['invoiceNumbers'] = [];
        additionalData['ewayBillNumbers'] = [];
      }
      
      // Get metadata - handle 404 gracefully
      try {
        final metadataResponse = await _makeRequest('GET', '/trips/$tripId/metadata');
        final metadata = jsonDecode(metadataResponse.body) as List;
        
        for (final meta in metadata) {
          switch (meta['category']) {
            case 'driver':
              additionalData['driverInfo'] = meta['data'];
              break;
            case 'vehicle':
              additionalData['vehicleDetails'] = meta['data'];
              break;
            case 'fieldOps':
              additionalData['fieldOps'] = meta['data'];
              break;
            case 'expiry':
              additionalData['expiryInfo'] = meta['data'];
              break;
            case 'tracking':
              additionalData['gsmTracking'] = meta['data']['gsmTracking'];
              break;
            case 'pickup':
              additionalData['pickupInfo'] = meta['data'];
              break;
            case 'location':
              additionalData['locationInfo'] = meta['data'];
              break;
          }
        }
        _logger.info('Metadata fetched for trip $tripId');
      } catch (e) {
        if (e.toString().contains('404') || e.toString().contains('Cannot GET')) {
          _logger.info('Metadata endpoint not available for trip $tripId - using fallback data');
        } else {
          _logger.warning('Error fetching metadata for trip $tripId: $e');
        }
        
        // Provide fallback metadata structure
        additionalData['driverInfo'] = additionalData['driverInfo'] ?? {'name': '', 'phone': ''};
        additionalData['vehicleDetails'] = additionalData['vehicleDetails'] ?? {};
        additionalData['fieldOps'] = additionalData['fieldOps'] ?? {'name': '', 'phone': '', 'email': ''};
        additionalData['expiryInfo'] = additionalData['expiryInfo'] ?? {};
        additionalData['pickupInfo'] = additionalData['pickupInfo'] ?? {};
        additionalData['locationInfo'] = additionalData['locationInfo'] ?? {};
        additionalData['gsmTracking'] = additionalData['gsmTracking'] ?? false;
      }
      
      return additionalData;
    } catch (e) {
      _logger.warning('Error retrieving additional trip data: $e');
      return {
        'materials': [],
        'lrNumbers': [],
        'invoiceNumbers': [],
        'ewayBillNumbers': [],
        'driverInfo': {'name': '', 'phone': ''},
        'vehicleDetails': {},
        'fieldOps': {'name': '', 'phone': '', 'email': ''},
        'expiryInfo': {},
        'pickupInfo': {},
        'locationInfo': {},
        'gsmTracking': false,
      };
    }
  }

  // Method to update additional charges for a trip
  Future<Trip> updateAdditionalCharges(
    String tripId,
    List<Map<String, dynamic>> additionalCharges,
    List<Map<String, dynamic>> deductionCharges,
    double newBalanceAmount
  ) async {
    try {
      _logger.info('Updating additional charges for trip $tripId');
      _logger.info('Additional charges: ${additionalCharges.length}');
      _logger.info('Deduction charges: ${deductionCharges.length}');
      _logger.info('New balance amount: $newBalanceAmount');
      
      final updateData = <String, dynamic>{
        'additionalCharges': additionalCharges,
        'deductionCharges': deductionCharges,
        'newBalanceAmount': newBalanceAmount,
        'reason': 'Additional charges updated via app',
        'addedBy': 'app_user',
      };

      _logger.info('Update data: ${jsonEncode(updateData)}');

      final response = await _makeRequest(
        'PATCH',
        '/trips/$tripId/additional-charges',
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logger.info('Additional charges updated successfully for trip $tripId');
      return Trip.fromJson(data);
    } catch (e) {
      _logger.severe('Error updating additional charges: $e');
      throw Exception('Failed to update additional charges: $e');
    }
  }

  // Optimized trip fetching methods
  Future<List<Trip>> getTripsPaginated(int page, int pageSize) async {
    try {
      _logger.info('Fetching trips page $page with size $pageSize');
      final response = await _makeRequest(
        'GET',
        '/trips?page=$page&limit=$pageSize',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['data'] ?? responseData;
      
      _logger.info('Received ${data.length} trips from API for page $page');
      
      // Process trips with minimal enrichment for speed
      List<Trip> trips = [];
      for (final tripData in data) {
        try {
          // Only enrich essential missing data
          _setDefaultValues(tripData);
          _enrichFinancialData(tripData);
          
          final trip = Trip.fromJson(tripData);
          trips.add(trip);
        } catch (e) {
          _logger.warning('Error processing trip in pagination: $e');
          continue;
        }
      }
      
      return trips;
    } catch (e) {
      _logger.severe('Error fetching paginated trips: $e');
      throw Exception('Failed to load trips: $e');
    }
  }

  // Fast balance payment queue fetching
  Future<List<Trip>> getBalancePaymentQueue() async {
    try {
      _logger.info('Fetching balance payment queue');
      final response = await _makeRequest(
        'GET',
        '/payments/balance-queue',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      _logger.info('Received ${data.length} trips in balance payment queue');
      
      List<Trip> trips = [];
      for (final tripData in data) {
        try {
          _setDefaultValues(tripData);
          _enrichFinancialData(tripData);
          
          final trip = Trip.fromJson(tripData);
          trips.add(trip);
        } catch (e) {
          _logger.warning('Error processing balance queue trip: $e');
          continue;
        }
      }
      
      return trips;
    } catch (e) {
      _logger.warning('Balance queue endpoint not available, using fallback: $e');
      // Fallback to filtering from all trips
      return await _getBalanceQueueFallback();
    }
  }

  // Fast advance payment queue fetching
  Future<List<Trip>> getAdvancePaymentQueue() async {
    try {
      _logger.info('Fetching advance payment queue');
      final response = await _makeRequest(
        'GET',
        '/payments/advance-queue',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      _logger.info('Received ${data.length} trips in advance payment queue');
      
      List<Trip> trips = [];
      for (final tripData in data) {
        try {
          _setDefaultValues(tripData);
          _enrichFinancialData(tripData);
          
          final trip = Trip.fromJson(tripData);
          trips.add(trip);
        } catch (e) {
          _logger.warning('Error processing advance queue trip: $e');
          continue;
        }
      }
      
      return trips;
    } catch (e) {
      _logger.warning('Advance queue endpoint not available, using fallback: $e');
      // Fallback to filtering from all trips
      return await _getAdvanceQueueFallback();
    }
  }

  // Fallback methods for payment queues
  Future<List<Trip>> _getBalanceQueueFallback() async {
    try {
      final allTrips = await getTrips();
      return allTrips.where((trip) => 
        trip.isInBalanceQueue && 
        trip.balancePaymentStatus != 'Paid'
      ).toList();
    } catch (e) {
      _logger.severe('Error in balance queue fallback: $e');
      return [];
    }
  }

  Future<List<Trip>> _getAdvanceQueueFallback() async {
    try {
      final allTrips = await getTrips();
      return allTrips.where((trip) => 
        trip.isInAdvanceQueue && 
        trip.advancePaymentStatus != 'Paid'
      ).toList();
    } catch (e) {
      _logger.severe('Error in advance queue fallback: $e');
      return [];
    }
  }

  // Ultra-fast payment status update
  Future<Trip> updatePaymentStatusFast(String tripId, Map<String, dynamic> paymentData) async {
    try {
      _logger.info('Fast payment status update for trip $tripId');
      final response = await _makeRequest(
        'PATCH',
        '/payments/$tripId/status',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

      final data = jsonDecode(response.body);
      _setDefaultValues(data);
      _enrichFinancialData(data);
      
      return Trip.fromJson(data);
    } catch (e) {
      _logger.warning('Fast payment update not available, using standard method: $e');
      // Fallback to standard update method
      return await updatePaymentStatus(tripId, paymentData);
    }
  }

  // Optimized clients fetching with caching headers
  Future<List<Client>> getClientsOptimized() async {
    try {
      _logger.info('Fetching clients with optimization');
      final response = await _makeRequest(
        'GET',
        '/clients',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'max-age=300', // 5 minutes cache
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      _logger.info('Received ${data.length} clients');
      
      return data.map((clientData) => Client.fromJson(clientData)).toList();
    } catch (e) {
      _logger.severe('Error fetching optimized clients: $e');
      // Fallback to regular method
      return await getClients();
    }
  }

  // Optimized suppliers fetching with caching headers
  Future<List<Supplier>> getSuppliersOptimized() async {
    try {
      _logger.info('Fetching suppliers with optimization');
      final response = await _makeRequest(
        'GET',
        '/suppliers',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'max-age=300', // 5 minutes cache
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      _logger.info('Received ${data.length} suppliers');
      
      return data.map((supplierData) => Supplier.fromJson(supplierData)).toList();
    } catch (e) {
      _logger.severe('Error fetching optimized suppliers: $e');
      // Fallback to regular method
      return await getSuppliers();
    }
  }

  // Optimized vehicles fetching with caching headers
  Future<List<Vehicle>> getVehiclesOptimized() async {
    try {
      _logger.info('Fetching vehicles with optimization');
      final response = await _makeRequest(
        'GET',
        '/vehicles',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'max-age=300', // 5 minutes cache
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      _logger.info('Received ${data.length} vehicles');
      
      return data.map((vehicleData) => Vehicle.fromJson(vehicleData)).toList();
    } catch (e) {
      _logger.severe('Error fetching optimized vehicles: $e');
      // Fallback to regular method
      return await getVehicles();
    }
  }

  // Bulk status update for multiple trips
  Future<List<Trip>> bulkUpdatePaymentStatus(List<Map<String, dynamic>> updates) async {
    try {
      _logger.info('Bulk updating payment status for ${updates.length} trips');
      final response = await _makeRequest(
        'PATCH',
        '/payments/bulk-update',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'updates': updates}),
      );

      final List<dynamic> data = jsonDecode(response.body);
      _logger.info('Bulk update completed for ${data.length} trips');
      
      List<Trip> updatedTrips = [];
      for (final tripData in data) {
        try {
          _setDefaultValues(tripData);
          _enrichFinancialData(tripData);
          
          final trip = Trip.fromJson(tripData);
          updatedTrips.add(trip);
        } catch (e) {
          _logger.warning('Error processing bulk updated trip: $e');
          continue;
        }
      }
      
      return updatedTrips;
    } catch (e) {
      _logger.warning('Bulk update not available, processing individually: $e');
      // Fallback to individual updates
      List<Trip> updatedTrips = [];
      for (final update in updates) {
        try {
          final tripId = update['tripId'];
          final updatedTrip = await updatePaymentStatus(tripId, update);
          updatedTrips.add(updatedTrip);
        } catch (e) {
          _logger.warning('Error in individual update during bulk fallback: $e');
          continue;
        }
      }
      return updatedTrips;
    }
  }

  // Ultra-fast payment processing method
  Future<Map<String, dynamic>> ultraFastPaymentUpdate(
    String tripId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      _logger.info('Ultra-fast payment update for trip: $tripId');
      final stopwatch = Stopwatch()..start();
      
      final response = await _makeRequest(
        'PATCH',
        '/payments/$tripId/ultra-fast',
        body: jsonEncode({
          'paymentType': updateData['paymentType'],
          'targetStatus': updateData['targetStatus'],
          'utrNumber': updateData['utrNumber'],
          'paymentMethod': updateData['paymentMethod'],
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      stopwatch.stop();
      _logger.info('Ultra-fast payment update completed in ${stopwatch.elapsedMilliseconds}ms');

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      _logger.severe('Ultra-fast payment update failed: $e');
      rethrow;
    }
  }

  // Lightning-fast payment status progression
  Future<Map<String, dynamic>> progressPaymentStatus(
    String tripId,
    String paymentType,
  ) async {
    try {
      _logger.info('Progressing payment status for trip: $tripId, type: $paymentType');
      final stopwatch = Stopwatch()..start();
      
      final response = await _makeRequest(
        'PATCH',
        '/payments/$tripId/next-status/$paymentType',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      stopwatch.stop();
      _logger.info('Payment status progression completed in ${stopwatch.elapsedMilliseconds}ms');

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      _logger.severe('Payment status progression failed: $e');
      rethrow;
    }
  }

  // Instant payment validation
  Future<Map<String, dynamic>> canProcessPayment(
    String tripId,
    String paymentType,
  ) async {
    try {
      _logger.info('Checking if payment can be processed: $tripId, type: $paymentType');
      
      final response = await _makeRequest(
        'GET',
        '/payments/$tripId/can-process/$paymentType',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      _logger.warning('Payment validation check failed: $e');
      // Return safe default
      return {
        'canProcess': false,
        'reason': 'Validation check failed: $e',
      };
    }
  }

  // Batch ultra-fast payment processing
  Future<List<Map<String, dynamic>>> batchUltraFastPaymentUpdate(
    List<Map<String, dynamic>> updates,
  ) async {
    try {
      _logger.info('Batch ultra-fast payment update for ${updates.length} payments');
      final stopwatch = Stopwatch()..start();
      
      final response = await _makeRequest(
        'PATCH',
        '/payments/bulk-update',
        body: jsonEncode({'updates': updates}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      stopwatch.stop();
      _logger.info('Batch payment update completed in ${stopwatch.elapsedMilliseconds}ms');

      final responseData = jsonDecode(response.body);
      
      if (responseData is List) {
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        return [responseData];
      }
    } catch (e) {
      _logger.severe('Batch payment update failed: $e');
      rethrow;
    }
  }
}