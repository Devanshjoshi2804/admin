class Client {
  final String id;
  final String name;
  final String city;
  final String address;
  final String addressType;
  final String invoicingType;
  final String gstNumber;
  final String panNumber;
  final String? msmeNumber;
  final ContactPerson logisticsPOC;
  final ContactPerson financePOC;
  final ContactPerson salesRepresentative;
  final List<dynamic> documents;
  final String status;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.addressType,
    required this.invoicingType,
    required this.gstNumber,
    required this.panNumber,
    this.msmeNumber,
    required this.logisticsPOC,
    required this.financePOC,
    required this.salesRepresentative,
    this.documents = const [],
    this.status = 'Active',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a Client from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    try {
      // Handle MongoDB _id field if present
      String id = json['id'] ?? '';
      if (id.isEmpty && json['_id'] != null) {
        id = json['_id'].toString();
      }
      
      // Handle timestamps
      DateTime? createdAt;
      if (json['createdAt'] != null) {
        createdAt = DateTime.tryParse(json['createdAt']);
      }
      
      DateTime? updatedAt;
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.tryParse(json['updatedAt']);
      }
      
      // Create POC objects from either nested or flat structure
      ContactPerson logisticsPOC = _createLogisticsPOC(json);
      ContactPerson financePOC = _createFinancePOC(json);
      ContactPerson salesRep = _createSalesRep(json);
      
      // Handle documents array
      List<dynamic> documents = [];
      if (json['documents'] != null && json['documents'] is List) {
        documents = json['documents'];
      }
      
      return Client(
        id: id,
        name: json['name'] ?? '',
        city: json['city'] ?? '',
        address: json['address'] ?? '',
        addressType: json['addressType'] ?? '',
        invoicingType: json['invoicingType'] ?? 'Monthly',
        gstNumber: json['gstNumber'] ?? '',
        panNumber: json['panNumber'] ?? '',
        msmeNumber: json['msmeNumber'],
        logisticsPOC: logisticsPOC,
        financePOC: financePOC,
        salesRepresentative: salesRep,
        documents: documents,
        status: json['status'] ?? 'Active',
        isActive: json['isActive'] ?? true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error creating Client from JSON: $e');
      // Return a minimal valid object rather than crashing
      return Client(
        id: json['id'] ?? json['_id']?.toString() ?? 'unknown',
        name: json['name'] ?? 'Unknown Client',
        city: json['city'] ?? '',
        address: json['address'] ?? '',
        addressType: json['addressType'] ?? '',
        invoicingType: 'Monthly',
        gstNumber: '',
        panNumber: '',
        logisticsPOC: ContactPerson(name: '', phone: '', email: ''),
        financePOC: ContactPerson(name: '', phone: '', email: ''),
        salesRepresentative: ContactPerson(name: '', phone: '', email: ''),
      );
    }
  }
  
  // Helper method to create logistics POC from either nested or flat structure
  static ContactPerson _createLogisticsPOC(Map<String, dynamic> json) {
    if (json['logisticsPOC'] != null && json['logisticsPOC'] is Map<String, dynamic>) {
      return ContactPerson.fromJson(json['logisticsPOC'] as Map<String, dynamic>);
    } else {
      // Try to create from flat fields
      return ContactPerson(
        name: json['logisticsName'] ?? '',
        phone: json['logisticsPhone'] ?? '',
        email: json['logisticsEmail'] ?? '',
      );
    }
  }
  
  // Helper method to create finance POC from either nested or flat structure
  static ContactPerson _createFinancePOC(Map<String, dynamic> json) {
    if (json['financePOC'] != null && json['financePOC'] is Map<String, dynamic>) {
      return ContactPerson.fromJson(json['financePOC'] as Map<String, dynamic>);
    } else {
      // Try to create from flat fields
      return ContactPerson(
        name: json['financeName'] ?? '',
        phone: json['financePhone'] ?? '',
        email: json['financeEmail'] ?? '',
      );
    }
  }
  
  // Helper method to create sales rep from either nested or flat structure
  static ContactPerson _createSalesRep(Map<String, dynamic> json) {
    // Check for salesRep field first
    if (json['salesRep'] != null && json['salesRep'] is Map<String, dynamic>) {
      return ContactPerson.fromJson(json['salesRep'] as Map<String, dynamic>);
    }
    // Check for salesRepresentative field next
    else if (json['salesRepresentative'] != null && json['salesRepresentative'] is Map<String, dynamic>) {
      return ContactPerson.fromJson(json['salesRepresentative'] as Map<String, dynamic>);
    } else {
      // Try to create from flat fields
      return ContactPerson(
        name: json['salesRepName'] ?? '',
        phone: json['salesRepPhone'] ?? '',
        email: json['salesRepEmail'] ?? '',
        designation: json['salesRepDesignation'],
      );
    }
  }

  // Convert Client to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'addressType': addressType,
      'invoicingType': invoicingType,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'msmeNumber': msmeNumber,
      'logisticsPOC': logisticsPOC.toJson(),
      'financePOC': financePOC.toJson(),
      'salesRepresentative': salesRepresentative.toJson(),
      'documents': documents,
      'status': status,
      'isActive': isActive,
    };
  }
  
  // Create a copy with updated fields
  Client copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    String? addressType,
    String? invoicingType,
    String? gstNumber,
    String? panNumber,
    String? msmeNumber,
    ContactPerson? logisticsPOC,
    ContactPerson? financePOC,
    ContactPerson? salesRepresentative,
    List<dynamic>? documents,
    String? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      addressType: addressType ?? this.addressType,
      invoicingType: invoicingType ?? this.invoicingType,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      msmeNumber: msmeNumber ?? this.msmeNumber,
      logisticsPOC: logisticsPOC ?? this.logisticsPOC,
      financePOC: financePOC ?? this.financePOC,
      salesRepresentative: salesRepresentative ?? this.salesRepresentative,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContactPerson {
  final String name;
  final String phone;
  final String email;
  final String? designation;

  ContactPerson({
    required this.name,
    required this.phone,
    required this.email,
    this.designation,
  });

  // Factory constructor to create a ContactPerson from JSON
  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      designation: json['designation'],
    );
  }

  // Convert ContactPerson to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'phone': phone,
      'email': email,
    };
    
    if (designation != null) {
      data['designation'] = designation;
    }
    
    return data;
  }
  
  // Create a copy with updated fields
  ContactPerson copyWith({
    String? name,
    String? phone,
    String? email,
    String? designation,
  }) {
    return ContactPerson(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      designation: designation ?? this.designation,
    );
  }
} 