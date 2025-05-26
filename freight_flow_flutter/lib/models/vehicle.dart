class Vehicle {
  final String id;
  final String vehicleNumber;
  final String vehicleType;
  final String vehicleSize;
  final String vehicleCapacity;
  final String axleType;
  final String? supplierId;
  final String? supplierName;
  final String? ownerName;
  final String? driverName;
  final String? driverPhone;
  final String? driverLicense;
  final String? rcNumber;
  final String? insuranceExpiry;
  final String? pucExpiry;
  final String? fitnessExpiry;
  final String? permitExpiry;
  final bool isActive;
  final String? ownerId;
  final List<dynamic> documents;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Legacy fields for backward compatibility
  final DateTime? insuranceExpiryDate;
  final DateTime? pucExpiryDate;
  final DateTime? fitnessExpiryDate;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleSize,
    required this.vehicleCapacity,
    required this.axleType,
    this.supplierId,
    this.supplierName,
    this.ownerName,
    this.driverName,
    this.driverPhone,
    this.driverLicense,
    this.rcNumber,
    this.insuranceExpiry,
    this.pucExpiry,
    this.fitnessExpiry,
    this.permitExpiry,
    this.isActive = true,
    this.ownerId,
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
    this.insuranceExpiryDate,
    this.pucExpiryDate,
    this.fitnessExpiryDate,
  });

  // Factory constructor to create a Vehicle from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB _id field if present
    String id = json['id'] ?? '';
    if (id.isEmpty && json['_id'] != null) {
      id = json['_id'].toString();
    }
    
    // Handle multiple potential field name formats from different APIs
    String vehicleNumber = json['vehicleNumber'] ?? json['registrationNumber'] ?? '';
    String vehicleType = json['vehicleType'] ?? json['type'] ?? '';
    String vehicleSize = json['vehicleSize'] ?? json['size'] ?? '';
    String vehicleCapacity = json['vehicleCapacity'] ?? json['capacity'] ?? '';
    String axleType = json['axleType'] ?? '';
    
    // Handle supplier/owner field name differences
    String? ownerId = json['ownerId'] ?? json['supplierId'];
    String? ownerName = json['ownerName'] ?? json['supplierName'];
    
    // Handle date parsing with proper error handling
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
      return null;
    }
    
    return Vehicle(
      id: id,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      vehicleSize: vehicleSize,
      vehicleCapacity: vehicleCapacity,
      axleType: axleType,
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      ownerName: ownerName,
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      driverLicense: json['driverLicense'],
      rcNumber: json['rcNumber'],
      insuranceExpiry: json['insuranceExpiry'],
      pucExpiry: json['pucExpiry'],
      fitnessExpiry: json['fitnessExpiry'],
      permitExpiry: json['permitExpiry'],
      isActive: json['isActive'] ?? true,
      ownerId: ownerId,
      documents: json['documents'] ?? [],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      insuranceExpiryDate: parseDate(json['insuranceExpiryDate'] ?? json['insuranceExpiry']),
      pucExpiryDate: parseDate(json['pucExpiryDate']),
      fitnessExpiryDate: parseDate(json['fitnessExpiryDate']),
    );
  }

  // Convert Vehicle to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'vehicleSize': vehicleSize,
      'vehicleCapacity': vehicleCapacity,
      'axleType': axleType,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'ownerName': ownerName,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverLicense': driverLicense,
      'rcNumber': rcNumber,
      'insuranceExpiry': insuranceExpiry,
      'pucExpiry': pucExpiry,
      'fitnessExpiry': fitnessExpiry,
      'permitExpiry': permitExpiry,
      'isActive': isActive,
      'ownerId': ownerId,
      'documents': documents,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'insuranceExpiryDate': insuranceExpiryDate?.toIso8601String(),
      'pucExpiryDate': pucExpiryDate?.toIso8601String(),
      'fitnessExpiryDate': fitnessExpiryDate?.toIso8601String(),
    };
  }
  
  // Create a copy of this Vehicle with the given field values changed
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? vehicleType,
    String? vehicleSize,
    String? vehicleCapacity,
    String? axleType,
    String? supplierId,
    String? supplierName,
    String? ownerName,
    String? driverName,
    String? driverPhone,
    String? driverLicense,
    String? rcNumber,
    String? insuranceExpiry,
    String? pucExpiry,
    String? fitnessExpiry,
    String? permitExpiry,
    bool? isActive,
    String? ownerId,
    List<dynamic>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? insuranceExpiryDate,
    DateTime? pucExpiryDate,
    DateTime? fitnessExpiryDate,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleSize: vehicleSize ?? this.vehicleSize,
      vehicleCapacity: vehicleCapacity ?? this.vehicleCapacity,
      axleType: axleType ?? this.axleType,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      ownerName: ownerName ?? this.ownerName,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLicense: driverLicense ?? this.driverLicense,
      rcNumber: rcNumber ?? this.rcNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      pucExpiry: pucExpiry ?? this.pucExpiry,
      fitnessExpiry: fitnessExpiry ?? this.fitnessExpiry,
      permitExpiry: permitExpiry ?? this.permitExpiry,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      pucExpiryDate: pucExpiryDate ?? this.pucExpiryDate,
      fitnessExpiryDate: fitnessExpiryDate ?? this.fitnessExpiryDate,
    );
  }
  
  // Override toString for better debugging
  @override
  String toString() {
    return 'Vehicle{id: $id, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType, '
        'vehicleSize: $vehicleSize, vehicleCapacity: $vehicleCapacity, axleType: $axleType, '
        'driverName: $driverName, driverPhone: $driverPhone, isActive: $isActive, '
        'ownerId: $ownerId, ownerName: $ownerName, documents: ${documents.length}, '
        'rcNumber: $rcNumber, insuranceExpiry: $insuranceExpiry, '
        'pucExpiry: $pucExpiry, fitnessExpiry: $fitnessExpiry, '
        'permitExpiry: $permitExpiry, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
} 