import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/network_error_helper.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, this.task});
  final Map<String, dynamic>? task;

  int? _positiveInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v > 0 ? v : null;
    final p = int.tryParse(v.toString());
    return (p != null && p > 0) ? p : null;
  }

  @override
  Widget build(BuildContext context) {
    final t =
        task ??
        <String, dynamic>{
          'pickup': 'Warehouse A',
          'delivery': 'Shelter North',
          'status': 'Assigned',
          'requestTitle': 'Food',
        };
    final donorId = _positiveInt(t['donor_id']);
    final ngoId = _positiveInt(t['request_creator_id']);
    final donationRequestId = _positiveInt(t['donation_request']);
    final donationId = _positiveInt(t['donation']);
    final requestTitle = t['requestTitle'] as String? ?? 'Task';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.primaryPinkDark,
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
                    _r(
                      Icons.local_shipping_rounded,
                      'Pickup',
                      t['pickup'] as String? ?? '—',
                    ),
                    _r(
                      Icons.location_on_rounded,
                      'Delivery',
                      t['delivery'] as String? ?? '—',
                    ),
                    _r(
                      Icons.assignment_rounded,
                      'Request',
                      t['requestTitle'] as String? ?? '—',
                    ),
                    _r(
                      Icons.info_rounded,
                      'Status',
                      t['status'] as String? ?? '—',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (t['id'] is int) ...[
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.deliveryTaskTracking,
                    arguments: t['id'] as int,
                  ),
                  icon: const Icon(Icons.podcasts_rounded, size: 20),
                  label: const Text('Live delivery status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (donorId != null) ...[
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.chatRoom,
                        arguments: <String, dynamic>{
                          'receiver_id': donorId,
                          'receiver_name': (t['donor_username'] ?? 'Donor')
                              .toString(),
                          'request_id': ?donationRequestId,
                          'donation_id': ?donationId,
                          'context_subtitle': requestTitle,
                        },
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(NetworkErrorHelper.toUserMessage(e)),
                          backgroundColor: AppTheme.statusError,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('Chat with donor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryTeal,
                    side: BorderSide(color: AppTheme.primaryTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (ngoId != null) ...[
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.chatRoom,
                        arguments: <String, dynamic>{
                          'receiver_id': ngoId,
                          'receiver_name': 'NGO/Hospital',
                          'request_id': ?donationRequestId,
                          'context_subtitle': requestTitle,
                        },
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(NetworkErrorHelper.toUserMessage(e)),
                          backgroundColor: AppTheme.statusError,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('Chat with NGO'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.updateTaskStatus, arguments: t),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text('Update Task Status'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _r(IconData icon, String label, String value) {
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
