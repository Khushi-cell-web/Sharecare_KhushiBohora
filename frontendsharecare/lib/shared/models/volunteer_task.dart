/// Volunteer pickup/delivery task.
class VolunteerTask {
  VolunteerTask({
    required this.id,
    this.donationRequest,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.taskStatus,
    this.volunteerId,
    this.donationRequestTitle,
    this.taskStatusDisplay,
    this.donationRequestCategory,
    this.donationRequestCategoryDisplay,
    this.donationOffer,
    this.donorUsername,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.pickupLatitude,
    this.pickupLongitude,
    this.donationId,
    this.donorId,
    this.requestCreatorId,
    this.createdAt,
    this.updatedAt,
    this.pointsAwarded = false,
    this.pointsEarned = 0,
    this.pointsEarnedNow = 0,
    this.volunteerPoints,
    this.donationRequestUrgency,
    this.isUrgentDelivery = false,
    this.deliveryPoints = 10,
  });

  factory VolunteerTask.fromJson(Map<String, dynamic> json) {
    final dr = json['donation_request'];
    final drId = dr == null ? null : (dr is int ? dr : (dr as num).toInt());
    final urgency = json['donation_request_urgency'] as String?;
    final urgent = (json['is_urgent_delivery'] as bool?) ?? urgency == 'High';
    return VolunteerTask(
      id: json['id'] as int,
      donationRequest: drId,
      pickupLocation: json['pickup_location'] as String? ?? '',
      deliveryLocation: json['delivery_location'] as String? ?? '',
      taskStatus: json['task_status'] as String? ?? 'assigned',
      volunteerId: json['volunteer'] as int?,
      donationRequestTitle: json['donation_request_title'] as String?,
      taskStatusDisplay: json['task_status_display'] as String?,
      donationRequestCategory: json['donation_request_category'] as String?,
      donationRequestCategoryDisplay:
          json['donation_request_category_display'] as String?,
      donationOffer: json['donation_offer'] as int?,
      donorUsername: json['donor_username'] as String?,
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      donationId: json['donation'] as int?,
      donorId: (json['donor_id'] as num?)?.toInt(),
      requestCreatorId: (json['request_creator_id'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      pointsAwarded: (json['points_awarded'] as bool?) ?? false,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      pointsEarnedNow: (json['points_earned_now'] as num?)?.toInt() ?? 0,
      volunteerPoints: (json['volunteer_points'] as num?)?.toInt(),
      donationRequestUrgency: urgency,
      isUrgentDelivery: urgent,
      deliveryPoints:
          (json['delivery_points'] as num?)?.toInt() ?? (urgent ? 20 : 10),
    );
  }

  final int id;
  final int? donationRequest;
  final int? volunteerId;
  final String pickupLocation;
  final String deliveryLocation;
  final String taskStatus;
  final String? donationRequestTitle;
  final String? taskStatusDisplay;
  final String? donationRequestCategory;
  final String? donationRequestCategoryDisplay;
  final int? donationOffer;
  final String? donorUsername;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final int? donationId;
  final int? donorId;
  final int? requestCreatorId;
  final String? createdAt;
  final String? updatedAt;
  final bool pointsAwarded;
  final int pointsEarned;
  final int pointsEarnedNow;
  final int? volunteerPoints;
  final String? donationRequestUrgency;
  final bool isUrgentDelivery;
  final int deliveryPoints;

  bool get pendingVolunteer => taskStatus == 'pending_volunteer';
  bool get isAssigned => taskStatus == 'assigned';
  bool get isPickedUp => taskStatus == 'picked';
  bool get isInTransit => taskStatus == 'in_transit';
  bool get isDelivered => taskStatus == 'delivered';

  /// Shape expected by task detail/update screens.
  Map<String, dynamic> toMap() => {
    'id': id,
    'pickup': pickupLocation,
    'delivery': deliveryLocation,
    'requestTitle': donationRequestTitle ?? 'Task',
    'status': taskStatusDisplay ?? taskStatus,
    'donation_request': donationRequest ?? 0,
    'task_status': taskStatus,
    'donor_username': donorUsername,
    'category': donationRequestCategoryDisplay ?? donationRequestCategory,
    'delivery_latitude': deliveryLatitude,
    'delivery_longitude': deliveryLongitude,
    'pickup_latitude': pickupLatitude,
    'pickup_longitude': pickupLongitude,
    'donation': donationId,
    'donor_id': donorId,
    'request_creator_id': requestCreatorId,
    'points_awarded': pointsAwarded,
    'points_earned': pointsEarned,
    'points_earned_now': pointsEarnedNow,
    'volunteer_points': volunteerPoints,
    'donation_request_urgency': donationRequestUrgency,
    'is_urgent_delivery': isUrgentDelivery,
    'delivery_points': deliveryPoints,
  };
}
