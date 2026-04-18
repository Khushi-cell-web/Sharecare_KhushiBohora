/// Donation transaction (monetary donation record).
class DonationTransaction {
  DonationTransaction({
    required this.id,
    this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.donationType,
    this.donationRequest,
    this.donationRequestTitle,
    this.paymentReference,
    this.createdAt,
    this.statusDisplay,
    this.typeDisplay,
  });

  factory DonationTransaction.fromJson(Map<String, dynamic> json) {
    return DonationTransaction(
      id: json['id'] as int,
      userId: json['user'] as int?,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'pending',
      donationType: json['donation_type'] as String? ?? 'one_time',
      donationRequest: json['donation_request'] as int?,
      donationRequestTitle: json['donation_request_title'] as String?,
      paymentReference: json['payment_reference'] as String?,
      createdAt: json['created_at'] as String?,
      statusDisplay: json['status_display'] as String?,
      typeDisplay: json['type_display'] as String?,
    );
  }

  final int id;
  final int? userId;
  final double amount;
  final String currency;
  final String status;
  final String donationType;
  final int? donationRequest;
  final String? donationRequestTitle;
  final String? paymentReference;
  final String? createdAt;
  final String? statusDisplay;
  final String? typeDisplay;

  bool get isCompleted {
    final s = status.toLowerCase().trim();
    return s == 'completed' || s == 'confirmed';
  }

  bool get isPending => status.toLowerCase().trim() == 'pending';
}
