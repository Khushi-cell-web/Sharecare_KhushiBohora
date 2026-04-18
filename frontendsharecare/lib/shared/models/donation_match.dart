/// Donation/receiver matchmaking card shared across donor + NGO flows.
class DonationMatch {
  DonationMatch({
    required this.id,
    required this.status,
    required this.donorDecision,
    required this.receiverDecision,
    this.distanceKm,
    required this.category,
    required this.urgency,
    required this.requestTitle,
    required this.requestLocation,
    required this.donorUsername,
    required this.receiverUsername,
    required this.myRole,
    required this.donationType,
    required this.quantity,
    required this.pickupLocation,
    this.expiryDate,
    this.validUntil,
    this.isNearExpiry = false,
    this.isExpired = false,
    required this.stage,
    required this.taskStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationMatch.fromJson(Map<String, dynamic> json) {
    return DonationMatch(
      id: json['id'] as int,
      status: (json['status'] as String?) ?? 'pending',
      donorDecision: (json['donor_decision'] as String?) ?? 'pending',
      receiverDecision: (json['receiver_decision'] as String?) ?? 'pending',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      category: (json['category'] as String?) ?? '',
      urgency: (json['urgency'] as String?) ?? 'Medium',
      requestTitle: (json['request_title'] as String?) ?? '',
      requestLocation: (json['request_location'] as String?) ?? '',
      donorUsername: (json['donor_username'] as String?) ?? '',
      receiverUsername: (json['receiver_username'] as String?) ?? '',
      myRole: (json['my_role'] as String?) ?? 'unknown',
      donationType: (json['donation_type'] as String?) ?? 'unknown',
      quantity: (json['quantity'] as int?) ?? 0,
      pickupLocation: (json['pickup_location'] as String?) ?? '',
      expiryDate: json['expiry_date'] as String?,
      validUntil: json['valid_until'] as String?,
      isNearExpiry: (json['is_near_expiry'] as bool?) ?? false,
      isExpired: (json['is_expired'] as bool?) ?? false,
      stage: (json['stage'] as String?) ?? 'pending',
      taskStatus: (json['task_status'] as String?) ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final int id;
  final String status;
  final String donorDecision;
  final String receiverDecision;

  final double? distanceKm;
  final String category;
  final String urgency;
  final String requestTitle;
  final String requestLocation;
  final String donorUsername;
  final String receiverUsername;

  /// Computed by backend for this viewer: `donor` or `receiver`.
  final String myRole;

  final String donationType;
  final int quantity;
  final String pickupLocation;
  final String? expiryDate;
  final String? validUntil;
  final bool isNearExpiry;
  final bool isExpired;

  final String stage;
  final String taskStatus;
  final String? createdAt;
  final String? updatedAt;
}
