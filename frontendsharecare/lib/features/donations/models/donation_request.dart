import '../../../shared/models/donation_request.dart' as shared;

/// Donation request model for Donation Module UI.
class DonationRequestModel {
  const DonationRequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categorySlug,
    required this.quantity,
    this.remainingQuantity,
    required this.status,
    required this.urgency,
    required this.location,
    this.organizationName,
    this.requestedByLabel,
    this.creatorProfileLocation,
    this.createdByUserId,
    this.imageUrl,
    this.galleryUrls,
  });

  /// From shared [shared.DonationRequest] (API).
  factory DonationRequestModel.fromDonationRequest(dynamic r) {
    final idVal = r.id;
    final id = idVal is int ? idVal.toString() : idVal.toString();
    final urgency = (r.urgency ?? 'Medium').toString();
    final slug = (r.category as String?) ?? 'other';
    final displayCat = (r.categoryDisplay ?? r.category ?? slug).toString();
    return DonationRequestModel(
      id: id,
      title: r.title as String,
      description: r.description as String,
      category: displayCat,
      categorySlug: slug,
      quantity: r.quantityNeeded as int? ?? 1,
      remainingQuantity: r.remainingQuantity as int?,
      status: r.status as String? ?? 'open',
      urgency: urgency,
      location: r.location as String,
      organizationName:
          r.organization as String? ?? r.createdByUsername as String?,
      requestedByLabel: r.requestedByLabel as String?,
      creatorProfileLocation: r.creatorProfileLocation as String?,
      createdByUserId: r.createdBy as int?,
      imageUrl: r.image as String?,
      galleryUrls: (r.galleryImages as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  final String id;
  final String title;
  final String description;

  /// Display label (e.g. "Food").
  final String category;

  /// API key (e.g. `food`, `blood`).
  final String categorySlug;
  final int quantity;
  final int? remainingQuantity;
  final String status;
  final String urgency;
  final String location;
  final String? organizationName;
  final String? requestedByLabel;
  final String? creatorProfileLocation;
  final int? createdByUserId;
  final String? imageUrl;
  final List<String>? galleryUrls;

  bool get isUrgent => urgency.toLowerCase() == 'urgent';
  bool get isHigh => urgency.toLowerCase() == 'high';
  bool get isBloodRequest => categorySlug == 'blood';
}
