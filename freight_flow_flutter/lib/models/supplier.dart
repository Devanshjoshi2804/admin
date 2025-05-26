class Supplier {
  final String id;
  final String name;
  final String city;
  final String address;
  final String? state;
  final String? pinCode;
  
  // GST Information
  final bool hasGST;
  final String gstNumber;
  
  // Identity Documents
  final String aadharCardNumber;
  final String panCardNumber;
  
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? representativeName;
  final String? representativeDesignation;
  final String? representativePhone;
  final String? representativeEmail;
  final String? bankName;
  final String? accountType;
  final String? accountNumber;
  final String? accountHolderName;
  final String? ifscCode;
  final String? serviceType;
  final List<SupplierDocument> documents;
  final bool isActive;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final List<String> verificationNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional fields for backward compatibility
  final String? panNumber;

  Supplier({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    this.state,
    this.pinCode,
    this.hasGST = true,
    required this.gstNumber,
    required this.aadharCardNumber,
    required this.panCardNumber,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.representativeName,
    this.representativeDesignation,
    this.representativePhone,
    this.representativeEmail,
    this.bankName,
    this.accountType,
    this.accountNumber,
    this.accountHolderName,
    this.ifscCode,
    this.serviceType,
    this.documents = const [],
    this.isActive = true,
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
    this.verificationNotes = const [],
    this.createdAt,
    this.updatedAt,
    this.panNumber,
  });

  // Computed properties for compatibility with payment dashboard
  String get email => contactEmail ?? representativeEmail ?? 'N/A';
  String get phone => contactPhone ?? representativePhone ?? 'N/A';
  String get status => isActive ? 'Active' : 'Inactive';

  factory Supplier.fromJson(Map<String, dynamic> json) {
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
      
      // Handle contact person data from nested structure
      String? contactName = json['contactName'];
      String? contactPhone = json['contactPhone'];
      String? contactEmail = json['contactEmail'];
      
      if (contactName == null && json['contactPerson'] != null && json['contactPerson'] is Map) {
        final contactPerson = json['contactPerson'] as Map<String, dynamic>;
        contactName = contactPerson['name'];
        contactPhone = contactPerson['phone'];
        contactEmail = contactPerson['email'];
      }
      
      // Handle bank details from nested structure
      String? bankName = json['bankName'];
      String? accountType = json['accountType'];
      String? accountNumber = json['accountNumber'];
      String? ifscCode = json['ifscCode'];
      String? accountHolderName = json['accountHolderName'];
      
      if (bankName == null && json['accountDetails'] != null && json['accountDetails'] is Map) {
        final accountDetails = json['accountDetails'] as Map<String, dynamic>;
        bankName = accountDetails['bankName'];
        accountType = accountDetails['accountType'];
        accountNumber = accountDetails['accountNumber'];
        ifscCode = accountDetails['ifscCode'];
        accountHolderName = accountDetails['accountHolderName'];
      }
      
      // Handle documents array with better error handling
      List<SupplierDocument> documents = [];
      if (json['documents'] != null) {
        try {
          if (json['documents'] is List) {
            final List<dynamic> docList = List.from(json['documents']); // Convert JSArray to Dart List
            for (var e in docList) {
              try {
                if (e is Map<String, dynamic>) {
                  final doc = SupplierDocument.fromJson(e);
                  documents.add(doc);
                } else if (e is Map) {
                  final docMap = Map<String, dynamic>.from(e);
                  final doc = SupplierDocument.fromJson(docMap);
                  documents.add(doc);
                } else {
                  print('Warning: Document item is not a Map: $e (${e.runtimeType})');
                }
              } catch (docError) {
                print('Error parsing individual document: $docError');
                // Continue with other documents instead of failing completely
              }
            }
          } else {
            print('Warning: Documents field is not a List: ${json['documents'].runtimeType}');
          }
        } catch (docsError) {
          print('Error parsing documents array: $docsError');
          print('Documents data type: ${json['documents'].runtimeType}');
          print('Documents content: ${json['documents']}');
          documents = [];
        }
      }
      
      return Supplier(
        id: id,
        name: json['name'] ?? '',
        city: json['city'] ?? '',
        address: json['address'] ?? '',
        state: json['state'],
        pinCode: json['pinCode'],
        hasGST: json['hasGST'] ?? true,
        gstNumber: json['gstNumber'] ?? '',
        aadharCardNumber: json['aadharCardNumber'] ?? '',
        panCardNumber: json['panCardNumber'] ?? '',
        contactName: contactName,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        representativeName: json['representativeName'],
        representativeDesignation: json['representativeDesignation'],
        representativePhone: json['representativePhone'],
        representativeEmail: json['representativeEmail'],
        bankName: bankName,
        accountType: accountType,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        ifscCode: ifscCode,
        serviceType: json['serviceType'],
        documents: documents,
        isActive: json['isActive'] ?? true,
        isVerified: json['isVerified'] ?? false,
        verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt']) : null,
        verifiedBy: json['verifiedBy'],
        verificationNotes: List<String>.from(json['verificationNotes'] ?? []),
        createdAt: createdAt,
        updatedAt: updatedAt,
        panNumber: json['panNumber'],
      );
    } catch (e) {
      print('Error creating Supplier from JSON: $e');
      // Return a minimal valid object rather than crashing
      return Supplier(
        id: json['id'] ?? json['_id']?.toString() ?? 'unknown',
        name: json['name'] ?? 'Unknown Supplier',
        city: json['city'] ?? '',
        address: json['address'] ?? '',
        state: json['state'],
        pinCode: json['pinCode'],
        hasGST: json['hasGST'] ?? true,
        gstNumber: json['gstNumber'] ?? '',
        aadharCardNumber: '',
        panCardNumber: '',
      );
    }
  }
  
  // Convert to JSON for API operations
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'state': state,
      'pinCode': pinCode,
      'hasGST': hasGST,
      'gstNumber': gstNumber,
      'aadharCardNumber': aadharCardNumber,
      'panCardNumber': panCardNumber,
      'isActive': isActive,
    };
    
    // Add contact person data
    if (contactName != null) data['contactName'] = contactName;
    if (contactPhone != null) data['contactPhone'] = contactPhone;
    if (contactEmail != null) data['contactEmail'] = contactEmail;
    
    // Add contact person as nested object for API compatibility
    if (contactName != null || contactPhone != null || contactEmail != null) {
      data['contactPerson'] = {
        'name': contactName ?? '',
        'phone': contactPhone ?? '',
        'email': contactEmail ?? '',
      };
    }
    
    // Add representative data
    if (representativeName != null) data['representativeName'] = representativeName;
    if (representativeDesignation != null) data['representativeDesignation'] = representativeDesignation;
    if (representativePhone != null) data['representativePhone'] = representativePhone;
    if (representativeEmail != null) data['representativeEmail'] = representativeEmail;
    
    // Add bank details
    if (bankName != null) data['bankName'] = bankName;
    if (accountType != null) data['accountType'] = accountType;
    if (accountNumber != null) data['accountNumber'] = accountNumber;
    if (ifscCode != null) data['ifscCode'] = ifscCode;
    if (accountHolderName != null) data['accountHolderName'] = accountHolderName;
    
    // Add bank details as nested object for API compatibility
    if (bankName != null || accountNumber != null || ifscCode != null) {
      data['accountDetails'] = {
        'bankName': bankName ?? '',
        'accountType': accountType ?? '',
        'accountNumber': accountNumber ?? '',
        'ifscCode': ifscCode ?? '',
        'accountHolderName': accountHolderName ?? '',
      };
    }
    
    // Add additional fields
    if (panNumber != null) data['panNumber'] = panNumber;
    if (serviceType != null) data['serviceType'] = serviceType;
    
    // Add verification data
    if (isVerified) {
      data['isVerified'] = isVerified;
      if (verifiedAt != null) data['verifiedAt'] = verifiedAt!.toIso8601String();
      if (verifiedBy != null) data['verifiedBy'] = verifiedBy;
      if (verificationNotes.isNotEmpty) data['verificationNotes'] = verificationNotes;
    }
    
    // Add documents if available
    if (documents.isNotEmpty) {
      data['documents'] = documents.map((e) => e.toJson()).toList();
    }
    
    return data;
  }

  // Get contact person as a formatted string
  String get contactPersonDisplay {
    if (contactName != null && contactName!.isNotEmpty) {
      return contactName!;
    }
    return 'N/A';
  }

  // Get bank details as a formatted string
  String get bankDetailsDisplay {
    if (bankName != null && bankName!.isNotEmpty) {
      return '$bankName - $accountNumber';
    }
    return 'N/A';
  }
  
  // Create a copy with updated fields
  Supplier copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    String? state,
    String? pinCode,
    bool? hasGST,
    String? gstNumber,
    String? aadharCardNumber,
    String? panCardNumber,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? representativeName,
    String? representativeDesignation,
    String? representativePhone,
    String? representativeEmail,
    String? bankName,
    String? accountType,
    String? accountNumber,
    String? accountHolderName,
    String? ifscCode,
    String? serviceType,
    List<SupplierDocument>? documents,
    bool? isActive,
    bool? isVerified,
    DateTime? verifiedAt,
    String? verifiedBy,
    List<String>? verificationNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? panNumber,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      hasGST: hasGST ?? this.hasGST,
      gstNumber: gstNumber ?? this.gstNumber,
      aadharCardNumber: aadharCardNumber ?? this.aadharCardNumber,
      panCardNumber: panCardNumber ?? this.panCardNumber,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      representativeName: representativeName ?? this.representativeName,
      representativeDesignation: representativeDesignation ?? this.representativeDesignation,
      representativePhone: representativePhone ?? this.representativePhone,
      representativeEmail: representativeEmail ?? this.representativeEmail,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      ifscCode: ifscCode ?? this.ifscCode,
      serviceType: serviceType ?? this.serviceType,
      documents: documents ?? this.documents,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      panNumber: panNumber ?? this.panNumber,
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
  
  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      designation: json['designation'],
    );
  }
}

class BankDetails {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;

  BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountType': accountType,
    };
  }
  
  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      accountType: json['accountType'] ?? '',
    );
  }
}

class SupplierDocument {
  final String type; // 'aadhar_card', 'pan_card', 'gst_certificate', 'non_gst_declaration', 'itr_year_1', 'itr_year_2', 'itr_year_3', 'lr_copy', 'loading_slip', 'bank_passbook', 'cancelled_cheque', 'other'
  final String url;
  final String filename;
  final String originalName;
  final String mimeType;
  final int size;
  final String? number; // For document numbers like Aadhar number, PAN number, etc.
  final int? year; // For ITR documents
  final DateTime uploadedAt;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  SupplierDocument({
    required this.type,
    required this.url,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.size,
    this.number,
    this.year,
    required this.uploadedAt,
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory SupplierDocument.fromJson(Map<String, dynamic> json) {
    return SupplierDocument(
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? json['filename'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: json['size'] ?? 0,
      number: json['number'],
      year: json['year'],
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
      isVerified: json['isVerified'] ?? false,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt']) : null,
      verifiedBy: json['verifiedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'type': type,
      'url': url,
      'filename': filename,
      'originalName': originalName,
      'mimeType': mimeType,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isVerified': isVerified,
    };
    
    if (number != null) data['number'] = number!;
    if (year != null) data['year'] = year!;
    if (verifiedAt != null) data['verifiedAt'] = verifiedAt!.toIso8601String();
    if (verifiedBy != null) data['verifiedBy'] = verifiedBy!;
    
    return data;
  }

  // Helper method to get display name for document type
  String get displayName {
    switch (type) {
      case 'aadhar_card':
        return 'Aadhar Card';
      case 'pan_card':
        return 'PAN Card';
      case 'gst_certificate':
        return 'GST Certificate';
      case 'non_gst_declaration':
        return 'Non-GST Declaration Form';
      case 'itr_year_1':
        return 'ITR Year 1';
      case 'itr_year_2':
        return 'ITR Year 2';
      case 'itr_year_3':
        return 'ITR Year 3';
      case 'lr_copy':
        return 'LR Copy';
      case 'loading_slip':
        return 'Loading Slip';
      case 'bank_passbook':
        return 'Bank Passbook';
      case 'cancelled_cheque':
        return 'Cancelled Cheque';
      default:
        return 'Other Document';
    }
  }

  // Helper method to get file size in human readable format
  String get humanReadableSize {
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  SupplierDocument copyWith({
    String? type,
    String? url,
    String? filename,
    String? originalName,
    String? mimeType,
    int? size,
    String? number,
    int? year,
    DateTime? uploadedAt,
    bool? isVerified,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return SupplierDocument(
      type: type ?? this.type,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      number: number ?? this.number,
      year: year ?? this.year,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
} 