import 'donation_request.dart';

/// Request item shown in the donation request list.
class RequestModel {
  const RequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quantityNeeded,
    required this.urgency,
    required this.organizationName,
    required this.location,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int quantityNeeded;

  /// Low, Medium, or High.
  final String urgency;
  final String organizationName;
  final String location;

  /// Adapts this list model to [DonationRequestModel].
  DonationRequestModel toDonationRequestModel() {
    final urgencyMap = {'Low': 'normal', 'Medium': 'high', 'High': 'urgent'};
    final slug = _inferCategorySlug(category);
    return DonationRequestModel(
      id: id,
      title: title,
      description: description,
      category: category,
      categorySlug: slug,
      quantity: quantityNeeded,
      status: 'open',
      urgency: urgencyMap[urgency] ?? urgency,
      location: location,
      organizationName: organizationName,
      requestedByLabel: organizationName.isNotEmpty
          ? 'Requested by $organizationName'
          : null,
    );
  }
}

String _inferCategorySlug(String label) {
  final s = label.toLowerCase();
  if (s.contains('blood')) return 'blood';
  if (s.contains('food')) return 'food';
  if (s.contains('clothes') || s.contains('cloth')) return 'clothes';
  if (s.contains('fund') || s.contains('money')) return 'funds';
  if (s.contains('organ')) return 'organ';
  if (s.contains('other')) return 'other';
  return 'other';
}
