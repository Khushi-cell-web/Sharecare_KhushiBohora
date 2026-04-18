import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';

/// NGO: Request Details - full request info, status, timeline, contact, actions.
class RequestDetailsNgoScreen extends StatelessWidget {
  const RequestDetailsNgoScreen({super.key, required this.request});

  final Map<String, dynamic> request;

  String _statusDisplay(dynamic v) {
    if (v == null) return 'Open';
    final s = v.toString().toLowerCase();
    if (s == 'matched') return 'Partially Fulfilled';
    if (s == 'fulfilled') return 'Fulfilled';
    if (s == 'closed') return 'Closed';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final title = request['title'] as String? ?? 'Request';
    final description = request['description'] as String? ?? '—';
    final category = request['category_display'] ?? request['category'] ?? '—';
    final quantity = request['quantity'] ?? request['quantity_needed'] ?? 0;
    final remainingQuantity = request['remaining_quantity'] ?? quantity;
    final donatedAmount =
        request['raised_amount'] ?? (quantity - remainingQuantity);
    final status = request['status_display'] ?? request['status'];
    final location = request['location'] as String? ?? '—';
    final contactPerson = request['contact_person'] as String? ?? '—';
    final contactPhone = request['contact_phone'] as String? ?? '—';
    final createdAt = request['created_at'] as String?;
    final expectedDate = request['expected_fulfillment_date'] as String?;
    final urgency = request['urgency'] as String? ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (description != '—')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    _row(
                      Icons.category_rounded,
                      'Category',
                      category.toString(),
                    ),
                    _row(Icons.numbers_rounded, 'Total Requested', '$quantity'),
                    _row(
                      Icons.inventory_rounded,
                      'Donated Amount',
                      '$donatedAmount',
                    ),
                    _row(
                      Icons.pending_actions_rounded,
                      'Remaining Amount',
                      '$remainingQuantity',
                    ),
                    _row(
                      Icons.warning_amber_rounded,
                      'Urgency',
                      urgency.toString(),
                    ),
                    _row(
                      Icons.info_rounded,
                      'Request Status',
                      _statusDisplay(status),
                    ),
                    _row(
                      Icons.location_on_rounded,
                      'Location of Need',
                      location,
                    ),
                    _row(
                      Icons.person_outline_rounded,
                      'Contact Person',
                      contactPerson,
                    ),
                    _row(Icons.phone_outlined, 'Contact Phone', contactPhone),
                    if (createdAt != null)
                      _row(
                        Icons.calendar_today_rounded,
                        'Created Date',
                        _formatDate(createdAt),
                      ),
                    if (expectedDate != null)
                      _row(
                        Icons.event_rounded,
                        'Expected Fulfillment Date',
                        _formatDate(expectedDate),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.receivedDonations),
                icon: const Icon(Icons.inventory_2_rounded, size: 20),
                label: const Text('View Received Donations / Inventory'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request closed')),
                    );
                    Navigator.maybePop(context);
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Close Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ctaOrange,
                    side: const BorderSide(color: AppTheme.ctaOrange),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as fulfilled')),
                    );
                    Navigator.maybePop(context);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Mark as Fulfilled'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
