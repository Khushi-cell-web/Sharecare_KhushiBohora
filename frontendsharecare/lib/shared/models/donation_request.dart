/// Donation request model.
class DonationRequest {
  DonationRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quantityNeeded,
    this.remainingQuantity,
    required this.location,
    required this.status,
    this.categoryDisplay,
    this.statusDisplay,
    this.createdBy,
    this.createdByUsername,
    this.organization,
    this.creatorFullName,
    this.creatorProfileLocation,
    this.requestedByLabel,
    this.urgency,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.galleryImages,
    this.latitude,
    this.longitude,
  });

  factory DonationRequest.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    final id = idVal is int ? idVal : int.parse(idVal.toString());
    return DonationRequest(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      quantityNeeded: json['quantity_needed'] as int? ?? 1,
      remainingQuantity: json['remaining_quantity'] as int?,
      location: json['location'] as String,
      status: json['status'] as String? ?? 'open',
      categoryDisplay: json['category_display'] as String?,
      statusDisplay: json['status_display'] as String?,
      createdBy: json['created_by'] as int?,
      createdByUsername: json['created_by_username'] as String?,
      organization: json['organization'] as String?,
      creatorFullName: json['creator_full_name'] as String?,
      creatorProfileLocation: json['creator_profile_location'] as String?,
      requestedByLabel: json['requested_by_label'] as String?,
      urgency: json['urgency'] as String? ?? 'Medium',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      image: json['image'] as String?,
      galleryImages: (json['gallery_images'] as List?)?.cast<String>(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String title;
  final String description;
  final String category;
  final int quantityNeeded;
  final int? remainingQuantity;
  final String location;
  final String status;
  final String? categoryDisplay;
  final String? statusDisplay;
  final int? createdBy;
  final String? createdByUsername;
  final String? organization;
  final String? creatorFullName;
  final String? creatorProfileLocation;
  final String? requestedByLabel;
  final String? urgency;
  final String? createdAt;
  final String? updatedAt;
  final String? image;
  final List<String>? galleryImages;
  final double? latitude;
  final double? longitude;

  bool get isOpen => status == 'open';
  bool get isMatched => status == 'matched';
  bool get isFulfilled => status == 'fulfilled';

  /// Shape expected by screens that read a map payload.
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'quantity': quantityNeeded,
    'quantity_needed': quantityNeeded,
    'location': location,
    'status': status,
    'status_display': statusDisplay ?? status,
    'category_display': categoryDisplay ?? category,
    'urgency': urgency,
    'created_at': createdAt,
    'image': image,
    'gallery_images': galleryImages,
    'latitude': latitude,
    'longitude': longitude,
    'requested_by_label': requestedByLabel,
    'creator_full_name': creatorFullName,
    'creator_profile_location': creatorProfileLocation,
  };
}
