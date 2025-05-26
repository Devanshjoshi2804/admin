import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'dart:math' as math;

class Material {
  final String name;
  final double weight;
  final String unit; // "MT" or "KG"
  final double ratePerMT;

  Material({
    required this.name,
    required this.weight,
    required this.unit,
    required this.ratePerMT,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      name: json['name'] as String? ?? 'Unknown Material',
      weight: ((json['weight'] as num?) ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'MT',
      ratePerMT: ((json['ratePerMT'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'unit': unit,
      'ratePerMT': ratePerMT,
    };
  }
}

class Document {
  final String type;
  final String url;
  final DateTime uploadedAt;
  final String? number;
  final String? filename;
  final String? id;
  final bool? isDownloadable;

  Document({
    required this.type,
    required this.url,
    required this.uploadedAt,
    this.number,
    this.filename,
    this.id,
    this.isDownloadable = true,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      type: json['type'] as String? ?? 'Document',
      url: json['url'] as String? ?? '',
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt'] as String)
          : DateTime.now(),
      number: json['number'] as String?,
      filename: json['filename'] as String?,
      id: json['id'] as String?,
      isDownloadable: json['isDownloadable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      if (number != null) 'number': number,
      if (filename != null) 'filename': filename,
      if (id != null) 'id': id,
      'isDownloadable': isDownloadable ?? true,
    };
  }
}

class EwayBill {
  final String number;
  final DateTime validFrom;
  final DateTime validUntil;
  final String expiryTime;
  final String filename;
  final DateTime expiryDate;

  EwayBill({
    required this.number,
    required this.validFrom,
    required this.validUntil,
    required this.expiryTime,
    required this.filename,
    required this.expiryDate,
  });

  factory EwayBill.fromJson(Map<String, dynamic> json) {
    return EwayBill(
      number: json['number'] as String? ?? '',
      validFrom: json['validFrom'] != null ? DateTime.parse(json['validFrom'] as String) : DateTime.now(),
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil'] as String) : DateTime.now().add(const Duration(days: 7)),
      expiryTime: json['expiryTime'] as String? ?? '23:59',
      filename: json['filename'] as String? ?? '',
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : DateTime.now().add(const Duration(days: 7)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'expiryTime': expiryTime,
      'filename': filename,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}

class Charge {
  final String description;
  final double amount;

  Charge({
    required this.description,
    required this.amount,
  });

  factory Charge.fromJson(Map<String, dynamic> json) {
    return Charge(
      description: json['description'] as String? ?? 'Charge',
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
    };
  }
}

class TripMaterial {
  final String name;
  final double weight;
  final String unit; // "MT" or "KG"
  final double ratePerMT;

  TripMaterial({
    required this.name,
    required this.weight,
    required this.unit,
    required this.ratePerMT,
  });

  factory TripMaterial.fromJson(Map<String, dynamic> json) {
    return TripMaterial(
      name: json['name'] as String? ?? 'Unknown Material',
      weight: ((json['weight'] as num?) ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'MT',
      ratePerMT: ((json['ratePerMT'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'unit': unit,
      'ratePerMT': ratePerMT,
    };
  }
}

class FieldOps {
  final String name;
  final String phone;
  final String email;

  FieldOps({
    required this.name,
    required this.phone,
    required this.email,
  });

  factory FieldOps.fromJson(Map<String, dynamic> json) {
    return FieldOps(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

class Pricing {
  final double baseAmount;
  final double gst;
  final double totalAmount;

  Pricing({
    required this.baseAmount,
    required this.gst,
    required this.totalAmount,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      baseAmount: ((json['baseAmount'] as num?) ?? 0).toDouble(),
      gst: ((json['gst'] as num?) ?? 0).toDouble(),
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseAmount': baseAmount,
      'gst': gst,
      'totalAmount': totalAmount,
    };
  }
}

// Payment History Entry for Audit Trail
class PaymentHistoryEntry {
  final String paymentType; // 'advance' | 'balance'
  final String status;
  final double amount;
  final DateTime timestamp;
  final String? utrNumber;
  final String? paymentMethod;
  final String? notes;

  PaymentHistoryEntry({
    required this.paymentType,
    required this.status,
    required this.amount,
    required this.timestamp,
    this.utrNumber,
    this.paymentMethod,
    this.notes,
  });

  factory PaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryEntry(
      paymentType: json['paymentType'] as String? ?? 'advance',
      status: json['status'] as String? ?? 'Not Started',
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      utrNumber: json['utrNumber'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentType': paymentType,
      'status': status,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      if (utrNumber != null) 'utrNumber': utrNumber,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
    };
  }
}

// POD Document for enhanced tracking
class PODDocument {
  final String filename;
  final String url;
  final DateTime uploadedAt;
  final bool isDownloadable;

  PODDocument({
    required this.filename,
    required this.url,
    required this.uploadedAt,
    this.isDownloadable = true,
  });

  factory PODDocument.fromJson(Map<String, dynamic> json) {
    return PODDocument(
      filename: json['filename'] as String? ?? 'POD_Document',
      url: json['url'] as String? ?? '',
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt'] as String)
          : DateTime.now(),
      isDownloadable: json['isDownloadable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isDownloadable': isDownloadable,
    };
  }
}

class Trip extends Equatable {
  final String id;
  final String orderNumber;
  final String clientId;
  final String clientName;
  final String? clientAddress;
  final String? clientCity;
  final String supplierId;
  final String supplierName;
  final String vehicleId;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? vehicleSize;
  final String? vehicleCapacity;
  final String? axleType;
  final String source;
  final String destination;
  final String? destinationCity;
  final String? destinationAddress;
  final double? distance;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? pickupDate;
  final String? pickupTime;
  final Pricing pricing;
  final List<Document> documents;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? clientFreight;
  final double? supplierFreight;
  final double? advancePercentage;
  final double? margin;
  final double? advanceSupplierFreight;
  final double? balanceSupplierFreight;
  final String? advancePaymentStatus;
  final String? balancePaymentStatus;
  final List<String> lrNumbers;
  final bool podUploaded;
  final DateTime? podDate;
  final List<TripMaterial> materials;
  final List<EwayBill>? ewayBills;
  final String? driverName;
  final String? driverPhone;
  final FieldOps? fieldOps;
  final String? notes;
  final String? utrNumber;
  final String? paymentMethod;
  final DateTime? paymentDate;
  final String? paymentNotes;
  final double? platformFees;
  final double? lrCharges;
  final List<Charge>? additionalCharges;
  final List<Charge>? deductionCharges;
  
  // Enhanced fields for streamlined payment workflow
  final PODDocument? podDocument;
  final List<PaymentHistoryEntry> paymentHistory;
  final bool isInAdvanceQueue;
  final bool isInBalanceQueue;
  final DateTime? advancePaymentInitiatedAt;
  final DateTime? advancePaymentCompletedAt;
  final DateTime? balancePaymentInitiatedAt;
  final DateTime? balancePaymentCompletedAt;

  Trip({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    this.clientAddress,
    this.clientCity,
    required this.supplierId,
    required this.supplierName,
    required this.vehicleId,
    this.vehicleNumber,
    this.vehicleType,
    this.vehicleSize,
    this.vehicleCapacity,
    this.axleType,
    required this.source,
    required this.destination,
    this.destinationCity,
    this.destinationAddress,
    this.distance,
    required this.startDate,
    this.endDate,
    this.pickupDate,
    this.pickupTime,
    required this.pricing,
    required this.documents,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.clientFreight = 0.0,
    this.supplierFreight = 0.0,
    this.advancePercentage = 30.0,
    this.margin = 0.0,
    this.advanceSupplierFreight = 0.0,
    this.balanceSupplierFreight = 0.0,
    this.advancePaymentStatus = 'Not Started',
    this.balancePaymentStatus = 'Not Started',
    this.lrNumbers = const [],
    this.podUploaded = false,
    this.podDate,
    this.materials = const [],
    this.ewayBills,
    this.driverName,
    this.driverPhone,
    this.fieldOps,
    this.notes,
    this.utrNumber,
    this.paymentMethod,
    this.paymentDate,
    this.paymentNotes,
    this.platformFees,
    this.lrCharges,
    this.additionalCharges,
    this.deductionCharges,
    // Enhanced payment workflow fields
    this.podDocument,
    this.paymentHistory = const [],
    this.isInAdvanceQueue = false,
    this.isInBalanceQueue = false,
    this.advancePaymentInitiatedAt,
    this.advancePaymentCompletedAt,
    this.balancePaymentInitiatedAt,
    this.balancePaymentCompletedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get string values with a default
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    // Helper function to safely parse double values
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        // Remove any commas that might cause parsing errors
        final cleanValue = value.replaceAll(',', '');
        return double.tryParse(cleanValue) ?? 0.0;
      }
      try {
        // Try to convert to double via toString() as a last resort
        return double.tryParse(value.toString()) ?? 0.0;
      } catch (e) {
        print('Error parsing double value: $value, $e');
        return 0.0;
      }
    }

    // Helper function to safely parse DateTime
    DateTime? safeDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is DateTime) return value;
        if (value is String) return DateTime.parse(value);
        return null;
      } catch (e) {
        print('Error parsing DateTime: $e');
        return null;
      }
    }

    try {
      print('Parsing Trip: OrderNumber=${json['orderNumber']}, ID=${json['id']}');
      // Extract and validate essential properties
      final String id = safeString(json['id'], 'unknown_id');
      final String orderNumber = safeString(json['orderNumber'], id); // Use ID as fallback for orderNumber
      final String source = safeString(json['source'], 'Unknown Source');
      final String destination = safeString(json['destination'], 'Unknown Destination');
      final String status = safeString(json['status'], 'Booked');

      // Extract and validate important client information
      final String clientId = safeString(json['clientId']);
      final String clientName = safeString(json['clientName'], 'Unknown Client');
      final String clientAddress = safeString(json['clientAddress']);
      final String clientCity = safeString(json['clientCity'], safeString(json['source']));

      // Extract and validate important vehicle information
      final String vehicleId = safeString(json['vehicleId']);
      final String vehicleNumber = safeString(json['vehicleNumber'], 'Unknown Vehicle');
      final String vehicleType = safeString(json['vehicleType'], 'Truck');
      final String vehicleSize = safeString(json['vehicleSize']);
      final String vehicleCapacity = safeString(json['vehicleCapacity']);
      final String axleType = safeString(json['axleType']);

      // Extract and validate driver information
      final String driverName = safeString(json['driverName'], 'Unknown Driver');
      final String driverPhone = safeString(json['driverPhone']);

      // Extract and validate important supplier information
      final String supplierId = safeString(json['supplierId']);
      final String supplierName = safeString(json['supplierName'], 'Unknown Supplier');

      // Extract destination details
      final String destinationAddress = safeString(json['destinationAddress']);
      final String destinationCity = safeString(json['destinationCity'], safeString(json['destination']));

      // Extract pickup date and time with special handling
      DateTime? pickupDate = safeDateTime(json['pickupDate']);
      if (pickupDate == null && json['startDate'] != null) {
        // Fall back to startDate if pickupDate is not available
        pickupDate = safeDateTime(json['startDate']);
      }

      final String pickupTime = safeString(json['pickupTime'], '9:00 AM');

      // Print field values for diagnosis
      print('Trip fields - Source: $source, Destination: $destination, Status: $status');
      print('Client: $clientName, Vehicle: $vehicleNumber, Type: $vehicleType');
      print('Driver: $driverName, Phone: $driverPhone');
      print('Pickup Date: ${pickupDate?.toString() ?? "Not set"}, Time: $pickupTime');

      // Handle dates with extra validation and debugging info
      DateTime startDate;
      try {
        startDate = json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : DateTime.now();
        print('StartDate parsed successfully: ${startDate.toString()}');
      } catch (e) {
        print('Error parsing startDate: $e');
        startDate = DateTime.now();
      }

      // Parse LR numbers with better error handling
      List<String> lrNumbers = [];
      if (json['lrNumbers'] != null) {
        if (json['lrNumbers'] is List) {
          // Handle potential nulls in the list
          lrNumbers = (json['lrNumbers'] as List)
            .where((lr) => lr != null)
            .map((lr) => lr.toString())
            .toList();
        } else if (json['lrNumbers'] is String && json['lrNumbers'].toString().isNotEmpty) {
          // If it's a single string, add it as an item
          lrNumbers = [json['lrNumbers'].toString()];
        }
      }

      // Handle field operations data
      FieldOps fieldOps;
      if (json['fieldOps'] != null && json['fieldOps'] is Map) {
        try {
          fieldOps = FieldOps.fromJson(json['fieldOps'] as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing fieldOps: $e');
          fieldOps = FieldOps(
            name: safeString(json['fieldOps']['name'], 'N/A'),
            phone: safeString(json['fieldOps']['phone'], 'N/A'),
            email: safeString(json['fieldOps']['email'], 'N/A'),
          );
        }
      } else {
        // Create default fieldOps if not available
        fieldOps = FieldOps(
          name: 'N/A',
          phone: 'N/A',
          email: 'N/A',
        );
      }

      // Handle numeric fields with detailed parsing and validation
      final double clientFreight = safeDouble(json['clientFreight']);
      final double supplierFreight = safeDouble(json['supplierFreight']);
      final double advancePercentage = safeDouble(json['advancePercentage']);
      
      // Extra debug logging
      print('Raw financial values:');
      print('clientFreight: ${json['clientFreight']}');
      print('supplierFreight: ${json['supplierFreight']}');
      print('advancePercentage: ${json['advancePercentage']}');
      print('margin: ${json['margin']}');
      print('advanceSupplierFreight: ${json['advanceSupplierFreight']}');
      print('balanceSupplierFreight: ${json['balanceSupplierFreight']}');

      // Calculate margin if not provided
      double margin;
      if (json['margin'] != null) {
        margin = safeDouble(json['margin']);
      } else {
        margin = clientFreight - supplierFreight;
      }

      // Calculate advance and balance supplier freight if not provided
      double advanceSupplierFreight;
      if (json['advanceSupplierFreight'] != null) {
        advanceSupplierFreight = safeDouble(json['advanceSupplierFreight']);
      } else {
        advanceSupplierFreight = supplierFreight * (advancePercentage / 100);
      }

      double balanceSupplierFreight;
      if (json['balanceSupplierFreight'] != null) {
        balanceSupplierFreight = safeDouble(json['balanceSupplierFreight']);
      } else {
        balanceSupplierFreight = supplierFreight - advanceSupplierFreight;
      }
      
      // Verify our calculations
      print('Calculated financial values:');
      print('clientFreight: $clientFreight');
      print('supplierFreight: $supplierFreight');
      print('advancePercentage: $advancePercentage');
      print('margin: $margin');
      print('advanceSupplierFreight: $advanceSupplierFreight');
      print('balanceSupplierFreight: $balanceSupplierFreight');

      // Extract payment information with better defaults
      final String advancePaymentStatus = safeString(json['advancePaymentStatus'], 'Pending');
      final String balancePaymentStatus = safeString(json['balancePaymentStatus'], 'Pending');
      final String utrNumber = safeString(json['utrNumber']);
      final String paymentMethod = safeString(json['paymentMethod'], 'Bank Transfer');

      // Log freight and payment information for diagnosis
      print('Trip freight info - Client: $clientFreight, Supplier: $supplierFreight, Margin: $margin');
      print('Advance: $advanceSupplierFreight, Balance: $balanceSupplierFreight');
      print('Payment status - Advance: $advancePaymentStatus, Balance: $balancePaymentStatus');
      print('LR Numbers: ${lrNumbers.join(", ")}');

      // Handle pricing with validation
      Pricing pricing;
      try {
        pricing = json['pricing'] != null
            ? Pricing.fromJson(json['pricing'] as Map<String, dynamic>)
            : Pricing(baseAmount: clientFreight, gst: 0, totalAmount: clientFreight);
      } catch (e) {
        print('Error parsing pricing: $e');
        pricing = Pricing(baseAmount: clientFreight, gst: 0, totalAmount: clientFreight);
      }

      // Handle documents with validation
      List<Document> documents = [];
      if (json['documents'] != null && json['documents'] is List) {
        try {
          documents = (json['documents'] as List)
            .where((doc) => doc != null)
            .map((doc) => Document.fromJson(doc as Map<String, dynamic>))
            .toList();
        } catch (e) {
          print('Error parsing documents: $e');
        }
      }

      // Handle materials with validation
      List<TripMaterial> materials = [];
      if (json['materials'] != null && json['materials'] is List) {
        try {
          materials = (json['materials'] as List)
            .where((m) => m != null)
            .map((m) => TripMaterial.fromJson(m as Map<String, dynamic>))
            .toList();
        } catch (e) {
          print('Error parsing materials: $e');
        }
      }

      // Handle ewayBills with validation
      List<EwayBill> ewayBills = [];
      if (json['ewayBills'] != null && json['ewayBills'] is List) {
        try {
          ewayBills = (json['ewayBills'] as List)
            .where((b) => b != null)
            .map((b) => EwayBill.fromJson(b as Map<String, dynamic>))
            .toList();
        } catch (e) {
          print('Error parsing ewayBills: $e');
        }
      }

      // Handle additionalCharges with validation
      List<Charge>? additionalCharges;
      if (json['additionalCharges'] != null && json['additionalCharges'] is List) {
        try {
          additionalCharges = (json['additionalCharges'] as List)
            .where((c) => c != null)
            .map((c) => Charge.fromJson(c as Map<String, dynamic>))
            .toList();
        } catch (e) {
          print('Error parsing additionalCharges: $e');
        }
      }

      // Handle deductionCharges with validation
      List<Charge>? deductionCharges;
      if (json['deductionCharges'] != null && json['deductionCharges'] is List) {
        try {
          deductionCharges = (json['deductionCharges'] as List)
            .where((c) => c != null)
            .map((c) => Charge.fromJson(c as Map<String, dynamic>))
            .toList();
        } catch (e) {
          print('Error parsing deductionCharges: $e');
        }
      }

      // Build and return the complete Trip object
      return Trip(
        id: id,
        orderNumber: orderNumber,
        clientId: clientId,
        clientName: clientName,
        supplierId: supplierId,
        supplierName: supplierName,
        vehicleId: vehicleId,
        vehicleNumber: vehicleNumber,
        vehicleType: vehicleType,
        source: source,
        destination: destination,
        status: status,
        startDate: startDate,
        distance: safeDouble(json['distance']),
        clientFreight: clientFreight,
        supplierFreight: supplierFreight,
        advancePercentage: advancePercentage,
        margin: margin,
        advanceSupplierFreight: advanceSupplierFreight,
        balanceSupplierFreight: balanceSupplierFreight,
        advancePaymentStatus: advancePaymentStatus,
        balancePaymentStatus: balancePaymentStatus,
        driverName: driverName,
        driverPhone: driverPhone,
        clientAddress: clientAddress,
        clientCity: clientCity,
        destinationAddress: destinationAddress,
        destinationCity: destinationCity,
        pickupDate: pickupDate,
        pickupTime: pickupTime,
        vehicleSize: vehicleSize,
        vehicleCapacity: vehicleCapacity,
        axleType: axleType,
        utrNumber: utrNumber,
        paymentMethod: paymentMethod,
        lrCharges: safeDouble(json['lrCharges']),
        platformFees: safeDouble(json['platformFees']),
        pricing: pricing,
        documents: documents,
        lrNumbers: lrNumbers,
        podUploaded: json['podUploaded'] == true,
        fieldOps: fieldOps,
        materials: materials,
        ewayBills: ewayBills,
        additionalCharges: additionalCharges,
        deductionCharges: deductionCharges,
        podDocument: json['podDocument'] != null ? PODDocument.fromJson(json['podDocument'] as Map<String, dynamic>) : null,
        paymentHistory: json['paymentHistory'] != null ? List<PaymentHistoryEntry>.from(json['paymentHistory'].map((p) => PaymentHistoryEntry.fromJson(p as Map<String, dynamic>))) : [],
        isInAdvanceQueue: json['isInAdvanceQueue'] == true,
        isInBalanceQueue: json['isInBalanceQueue'] == true,
        advancePaymentInitiatedAt: safeDateTime(json['advancePaymentInitiatedAt']),
        advancePaymentCompletedAt: safeDateTime(json['advancePaymentCompletedAt']),
        balancePaymentInitiatedAt: safeDateTime(json['balancePaymentInitiatedAt']),
        balancePaymentCompletedAt: safeDateTime(json['balancePaymentCompletedAt']),
      );
    } catch (e) {
      print('Error parsing Trip from JSON: $e');
      print('Problematic JSON: ${json.toString().substring(0, math.min(200, json.toString().length))}...');
      // Return a minimal valid Trip object to avoid app crashes
    return Trip(
        id: safeString(json['id'], 'error_id_${DateTime.now().millisecondsSinceEpoch}'),
        orderNumber: safeString(json['orderNumber'], 'Error: Invalid Data'),
        source: safeString(json['source'], 'Error: Source Missing'),
        destination: safeString(json['destination'], 'Error: Destination Missing'),
        clientId: safeString(json['clientId'], 'unknown'),
        clientName: safeString(json['clientName'], 'Error: Parsing Failed'),
        supplierId: safeString(json['supplierId'], 'unknown'),
        supplierName: safeString(json['supplierName'], 'Error: Parsing Failed'),
        vehicleId: safeString(json['vehicleId'], 'unknown'),
        vehicleNumber: safeString(json['vehicleNumber'], 'Error: Parsing Failed'),
        status: safeString(json['status'], 'Error'),
        startDate: DateTime.now(),
        distance: safeDouble(json['distance']),
        materials: [],
        clientFreight: safeDouble(json['clientFreight']),
        supplierFreight: safeDouble(json['supplierFreight']),
        advancePercentage: safeDouble(json['advancePercentage']),
        margin: safeDouble(json['margin']),
        advanceSupplierFreight: safeDouble(json['advanceSupplierFreight']),
        balanceSupplierFreight: safeDouble(json['balanceSupplierFreight']),
        pricing: Pricing(
          baseAmount: safeDouble(json['clientFreight']),
           gst: 0,
           totalAmount: safeDouble(json['clientFreight'])
        ),
        documents: [],
        lrNumbers: json['lrNumbers'] is List
            ? List<String>.from(json['lrNumbers'])
            : [],
        pickupDate: safeDateTime(json['pickupDate']) ?? safeDateTime(json['startDate']),
        pickupTime: safeString(json['pickupTime']),
        advancePaymentStatus: safeString(json['advancePaymentStatus'], 'Pending'),
        balancePaymentStatus: safeString(json['balancePaymentStatus'], 'Pending'),
        podDocument: null,
        paymentHistory: [],
        isInAdvanceQueue: false,
        isInBalanceQueue: false,
        advancePaymentInitiatedAt: null,
        advancePaymentCompletedAt: null,
        balancePaymentInitiatedAt: null,
        balancePaymentCompletedAt: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'clientId': clientId,
      'clientName': clientName,
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'source': source,
      'destination': destination,
      'distance': distance,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'pricing': pricing.toJson(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'status': status,
      'notes': notes,
      if (lrNumbers.isNotEmpty) 'lrNumbers': lrNumbers,
      if (clientAddress != null) 'clientAddress': clientAddress,
      if (clientCity != null) 'clientCity': clientCity,
      if (destinationAddress != null) 'destinationAddress': destinationAddress,
      if (destinationCity != null) 'destinationCity': destinationCity,
      if (pickupDate != null) 'pickupDate': pickupDate!.toIso8601String(),
      if (pickupTime != null) 'pickupTime': pickupTime,
      if (vehicleSize != null) 'vehicleSize': vehicleSize,
      if (vehicleCapacity != null) 'vehicleCapacity': vehicleCapacity,
      if (axleType != null) 'axleType': axleType,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      if (fieldOps != null) 'fieldOps': fieldOps!.toJson(),
      if (materials.isNotEmpty) 'materials': materials.map((m) => m.toJson()).toList(),
      if (clientFreight != null) 'clientFreight': clientFreight,
      if (supplierFreight != null) 'supplierFreight': supplierFreight,
      if (advancePercentage != null) 'advancePercentage': advancePercentage,
      if (margin != null) 'margin': margin,
      if (advanceSupplierFreight != null) 'advanceSupplierFreight': advanceSupplierFreight,
      if (balanceSupplierFreight != null) 'balanceSupplierFreight': balanceSupplierFreight,
      if (advancePaymentStatus != null) 'advancePaymentStatus': advancePaymentStatus,
      if (balancePaymentStatus != null) 'balancePaymentStatus': balancePaymentStatus,
      if (utrNumber != null) 'utrNumber': utrNumber,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (additionalCharges != null) 'additionalCharges': additionalCharges!.map((c) => c.toJson()).toList(),
      if (lrCharges != null) 'lrCharges': lrCharges,
      if (platformFees != null) 'platformFees': platformFees,
      if (deductionCharges != null) 'deductionCharges': deductionCharges!.map((c) => c.toJson()).toList(),
      if (ewayBills != null && ewayBills!.isNotEmpty) 'ewayBills': ewayBills!.map((b) => b.toJson()).toList(),
      'podUploaded': podUploaded,
      if (podDocument != null) 'podDocument': podDocument!.toJson(),
      'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
      'isInAdvanceQueue': isInAdvanceQueue,
      'isInBalanceQueue': isInBalanceQueue,
      if (advancePaymentInitiatedAt != null) 'advancePaymentInitiatedAt': advancePaymentInitiatedAt!.toIso8601String(),
      if (advancePaymentCompletedAt != null) 'advancePaymentCompletedAt': advancePaymentCompletedAt!.toIso8601String(),
      if (balancePaymentInitiatedAt != null) 'balancePaymentInitiatedAt': balancePaymentInitiatedAt!.toIso8601String(),
      if (balancePaymentCompletedAt != null) 'balancePaymentCompletedAt': balancePaymentCompletedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        clientId,
        vehicleId,
        supplierId,
        source,
        destination,
        startDate,
        status,
      ];
      
  // Sample data for UI demonstration
  static List<Trip> getSampleTrips() {
    return [
      Trip(
        id: 'TR001',
        orderNumber: 'FTL-20240515-0001',
        clientId: 'CL001',
        clientName: 'Tata Steel Ltd',
        vehicleId: 'VH001',
        vehicleNumber: 'MH02AB1234',
        vehicleType: 'LCV',
        supplierId: 'SP001',
        supplierName: 'Mahindra Logistics',
        source: 'Mumbai',
        destination: 'Pune',
        distance: 150,
        startDate: DateTime(2024, 5, 15),
        endDate: DateTime(2024, 5, 16),
        pricing: Pricing(
          baseAmount: 15000,
          gst: 2700,
          totalAmount: 17700,
        ),
        documents: [
          Document(
            type: 'E-Way Bill',
            url: 'https://example.com/ewb001.pdf',
            uploadedAt: DateTime(2024, 5, 14),
          ),
          Document(
            type: 'Invoice',
            url: 'https://example.com/inv001.pdf',
            uploadedAt: DateTime(2024, 5, 16),
          ),
        ],
        status: 'Completed',
        notes: 'Delivery completed on time',
        createdAt: DateTime(2024, 5, 14),
        updatedAt: DateTime(2024, 5, 16),
        lrNumbers: ['LR001'],
        clientAddress: 'Tata Steel Factory, Thane',
        clientCity: 'Mumbai',
        destinationAddress: 'Tata Steel Warehouse, Hinjewadi',
        destinationCity: 'Pune',
        pickupDate: DateTime(2024, 5, 15),
        pickupTime: '10:00 AM',
        vehicleSize: '14ft',
        vehicleCapacity: '7.5T',
        axleType: 'Single',
        driverName: 'Ramesh Kumar',
        driverPhone: '9876543210',
        fieldOps: FieldOps(
          name: 'Suresh Patel',
          phone: '8765432109',
          email: 'suresh@example.com',
        ),
        materials: [
          TripMaterial(
            name: 'Steel Rods',
            weight: 5.5,
            unit: 'MT',
            ratePerMT: 2000,
          ),
        ],
        clientFreight: 15000,
        supplierFreight: 12000,
        advancePercentage: 30,
        advanceSupplierFreight: 3600,
        balanceSupplierFreight: 8400,
        advancePaymentStatus: 'Paid',
        balancePaymentStatus: 'Paid',
        utrNumber: 'UTR123456',
        paymentMethod: 'NEFT',
        lrCharges: 250,
        platformFees: 500,
        podUploaded: true,
        podDocument: PODDocument(
          filename: 'POD_Document',
          url: '',
          uploadedAt: DateTime.now(),
          isDownloadable: true,
        ),
        paymentHistory: [
          PaymentHistoryEntry(
            paymentType: 'advance',
            status: 'Paid',
            amount: 3600,
            timestamp: DateTime.now(),
            utrNumber: 'UTR123456',
            paymentMethod: 'NEFT',
            notes: 'Payment for advance',
          ),
        ],
        isInAdvanceQueue: false,
        isInBalanceQueue: false,
        advancePaymentInitiatedAt: null,
        advancePaymentCompletedAt: null,
        balancePaymentInitiatedAt: null,
        balancePaymentCompletedAt: null,
      ),
      Trip(
        id: 'TR002',
        orderNumber: 'FTL-20240518-0002',
        clientId: 'CL002',
        clientName: 'Reliance Industries',
        vehicleId: 'VH002',
        vehicleNumber: 'HR55CD5678',
        vehicleType: 'HCV',
        supplierId: 'SP002',
        supplierName: 'TCI Freight',
        source: 'Mumbai',
        destination: 'Delhi',
        distance: 1400,
        startDate: DateTime(2024, 5, 18),
        endDate: DateTime(2024, 5, 22),
        pricing: Pricing(
          baseAmount: 45000,
          gst: 8100,
          totalAmount: 53100,
        ),
        documents: [
          Document(
            type: 'E-Way Bill',
            url: 'https://example.com/ewb002.pdf',
            uploadedAt: DateTime(2024, 5, 17),
          ),
        ],
        status: 'In Transit',
        notes: 'Vehicle left Mumbai on schedule',
        createdAt: DateTime(2024, 5, 17),
        updatedAt: DateTime(2024, 5, 18),
        lrNumbers: ['LR002'],
        clientAddress: 'Reliance Refinery, Jamnagar',
        clientCity: 'Mumbai',
        destinationAddress: 'Reliance Warehouse, Gurgaon',
        destinationCity: 'Delhi',
        pickupDate: DateTime(2024, 5, 18),
        pickupTime: '9:00 AM',
        vehicleSize: '32ft',
        vehicleCapacity: '25T',
        axleType: 'Multi',
        driverName: 'Ajay Singh',
        driverPhone: '7654321098',
        clientFreight: 45000,
        supplierFreight: 38000,
        advancePercentage: 40,
        advanceSupplierFreight: 15200,
        balanceSupplierFreight: 22800,
        advancePaymentStatus: 'Paid',
        balancePaymentStatus: 'Pending',
        podUploaded: false,
        podDocument: null,
        paymentHistory: [],
        isInAdvanceQueue: false,
        isInBalanceQueue: false,
        advancePaymentInitiatedAt: null,
        advancePaymentCompletedAt: null,
        balancePaymentInitiatedAt: null,
        balancePaymentCompletedAt: null,
      ),
      Trip(
        id: 'TR003',
        orderNumber: 'FTL-20240525-0003',
        clientId: 'CL003',
        clientName: 'Asian Paints Ltd',
        vehicleId: 'VH003',
        vehicleNumber: 'DL01EF9012',
        vehicleType: 'Container',
        supplierId: 'SP003',
        supplierName: 'Safexpress',
        source: 'Mumbai',
        destination: 'Bangalore',
        distance: 980,
        startDate: DateTime(2024, 5, 25),
        pricing: Pricing(
          baseAmount: 35000,
          gst: 6300,
          totalAmount: 41300,
        ),
        documents: [],
        status: 'Scheduled',
        notes: 'Pickup scheduled for 9 AM',
        createdAt: DateTime(2024, 5, 20),
        updatedAt: DateTime(2024, 5, 20),
        lrNumbers: [],
        clientAddress: 'Asian Paints Factory, Andheri',
        clientCity: 'Mumbai',
        destinationAddress: 'Asian Paints Warehouse, Electronic City',
        destinationCity: 'Bangalore',
        pickupDate: DateTime(2024, 5, 25),
        pickupTime: '9:00 AM',
        vehicleSize: '24ft',
        vehicleCapacity: '15T',
        axleType: 'Double',
        clientFreight: 35000,
        supplierFreight: 30000,
        advancePercentage: 30,
        advancePaymentStatus: 'Pending',
        balancePaymentStatus: 'Pending',
        podUploaded: false,
        podDocument: null,
        paymentHistory: [],
        isInAdvanceQueue: false,
        isInBalanceQueue: false,
        advancePaymentInitiatedAt: null,
        advancePaymentCompletedAt: null,
        balancePaymentInitiatedAt: null,
        balancePaymentCompletedAt: null,
      ),
    ];
  }
} 