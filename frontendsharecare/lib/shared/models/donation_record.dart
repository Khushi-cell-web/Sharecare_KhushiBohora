/// Donation lifecycle record returned by the backend.
class DonationRecord {
  DonationRecord({
    required this.id,
    required this.status,
    this.statusDisplay,
    this.category,
    this.categoryDisplay,
    this.donationType,
    this.typeDisplay,
    this.quantity = 0,
    this.description,
    this.pickupLocation,
    this.deliveryLocation,
    this.acceptedByNgoUsername,
    this.assignedVolunteerUsername,
    this.donorUsername,
    this.donationRequest,
    this.deliveryTaskId,
    this.isExpired = false,
    this.isNearExpiry = false,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      statusDisplay: json['status_display'] as String?,
      category: json['category'] as String?,
      categoryDisplay: json['category_display'] as String?,
      donationType: json['donation_type'] as String?,
      typeDisplay: json['type_display'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      pickupLocation: json['pickup_location'] as String?,
      deliveryLocation: json['delivery_location'] as String?,
      acceptedByNgoUsername: json['accepted_by_ngo_username'] as String?,
      assignedVolunteerUsername: json['assigned_volunteer_username'] as String?,
      donorUsername: json['donor_username'] as String?,
      donationRequest: json['donation_request'] as int?,
      deliveryTaskId: json['delivery_task_id'] as int?,
      isExpired: json['is_expired'] as bool? ?? false,
      isNearExpiry: json['is_near_expiry'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final int id;
  final String status;
  final String? statusDisplay;
  final String? category;
  final String? categoryDisplay;
  final String? donationType;
  final String? typeDisplay;
  final int quantity;
  final String? description;
  final String? pickupLocation;
  final String? deliveryLocation;
  final String? acceptedByNgoUsername;
  final String? assignedVolunteerUsername;
  final String? donorUsername;
  final int? donationRequest;
  final int? deliveryTaskId;
  final bool isExpired;
  final bool isNearExpiry;
  final String? createdAt;
  final String? updatedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'confirmed';
  bool get isAssigned => status == 'assigned';
  bool get isPickedUp => status == 'picked_up';
  bool get isInTransit => status == 'in_transit';
  bool get isCompleted => status == 'completed';

  String get headline {
    final text = (description ?? '').trim();
    if (text.isNotEmpty) {
      return text.split('\n').first;
    }
    return categoryDisplay ?? category ?? 'Donation';
  }
}
