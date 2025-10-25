import 'package:cloud_firestore/cloud_firestore.dart';

/// Service request model for storing customer inquiries and leads
class ServiceRequest {
  final String id;
  final RequestType requestType;
  final String? name;
  final String? email;
  final String? phone;
  final String? company;
  final String? address;
  final String? city;
  final String? state;
  final String zipCode;
  final Map<String, dynamic> requestDetails;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isHighPriority;
  final String? assignedTo;
  final List<String> followUpNotes;

  ServiceRequest({
    required this.id,
    required this.requestType,
    this.name,
    this.email,
    this.phone,
    this.company,
    this.address,
    this.city,
    this.state,
    this.zipCode = '',
    required this.requestDetails,
    this.status = RequestStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.isHighPriority = false,
    this.assignedTo,
    this.followUpNotes = const [],
  });

  factory ServiceRequest.fromMap(String id, Map<String, dynamic> map) {
    return ServiceRequest(
      id: id,
      requestType: RequestType.values.firstWhere(
        (e) => e.toString() == map['requestType'],
        orElse: () => RequestType.generalInquiry,
      ),
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      company: map['company'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'] ?? '',
      requestDetails: Map<String, dynamic>.from(map['requestDetails'] ?? {}),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHighPriority: map['isHighPriority'] ?? false,
      assignedTo: map['assignedTo'],
      followUpNotes: List<String>.from(map['followUpNotes'] ?? []),
    );
  }

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'requestType': requestType.toString(),
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'requestDetails': requestDetails,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isHighPriority': isHighPriority,
      'assignedTo': assignedTo,
      'followUpNotes': followUpNotes,
    };
  }

  ServiceRequest copyWith({
    String? id,
    RequestType? requestType,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    Map<String, dynamic>? requestDetails,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHighPriority,
    String? assignedTo,
    List<String>? followUpNotes,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      requestDetails: requestDetails ?? this.requestDetails,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      assignedTo: assignedTo ?? this.assignedTo,
      followUpNotes: followUpNotes ?? this.followUpNotes,
    );
  }
}

enum RequestType {
  generalInquiry,
  containerQuote('Container Service Quote'),
  scrapPickup('Scrap Metal Pickup'),
  rollOffService('Roll-Off Service'),
  emergencyService('Emergency Service'),
  wasteRemoval('Waste Removal');

  const RequestType([this.displayName]);

  final String? displayName;

  String get display => displayName ?? name;
}

enum RequestStatus {
  pending('Pending Review'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled'),
  onHold('On Hold');

  const RequestStatus([this.displayName]);

  final String? displayName;

  String get display => displayName ?? name;
}
