/// Donation offer from a Donor.
class DonationOffer {
  DonationOffer({
    required this.id,
    required this.donationRequest,
    required this.type,
    required this.quantity,
    required this.status,
    this.donationRequestTitle,
    this.typeDisplay,
    this.statusDisplay,
    this.message,
    this.fulfillmentType,
    this.fulfillmentTypeDisplay,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryTaskId,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationOffer.fromJson(Map<String, dynamic> json) {
    return DonationOffer(
      id: json['id'] as int,
      donationRequest: json['donation_request'] as int,
      type: json['type'] as String,
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
      donationRequestTitle: json['donation_request_title'] as String?,
      typeDisplay: json['type_display'] as String?,
      statusDisplay: json['status_display'] as String?,
      message: json['message'] as String?,
      fulfillmentType: json['fulfillment_type'] as String?,
      fulfillmentTypeDisplay: json['fulfillment_type_display'] as String?,
      pickupLocation: json['pickup_location'] as String?,
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      deliveryTaskId: (json['delivery_task_id'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final int id;
  final int donationRequest;
  final String type;
  final int quantity;
  final String status;
  final String? donationRequestTitle;
  final String? typeDisplay;
  final String? statusDisplay;
  final String? message;
  final String? fulfillmentType;
  final String? fulfillmentTypeDisplay;
  final String? pickupLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;

  /// Volunteer delivery task (material + volunteer pickup), when created.
  final int? deliveryTaskId;
  final String? createdAt;
  final String? updatedAt;
}
