import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/models/donation_record.dart';
import '../shared/providers/auth_provider.dart';

/// Donor-side view of donation lifecycle records.
class MyDonationRecordsScreen extends StatefulWidget {
  const MyDonationRecordsScreen({super.key});

  @override
  State<MyDonationRecordsScreen> createState() => _MyDonationRecordsScreenState();
}

class _MyDonationRecordsScreenState extends State<MyDonationRecordsScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please log in to view your donation records.';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getMyDonationRecords(auth.authHeaders);
      if (mounted) {
        setState(() {
          _records = list;
          _loading = false;
        });
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkErrorHelper.toUserMessage(e);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkErrorHelper.toUserMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Donations'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.primaryPinkDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.statusError),
                    ),
                  ),
                ],
              )
            : _records.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Icon(Icons.volunteer_activism_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No donations yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final item = _records[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.headline,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _statusChip(item),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.typeDisplay ?? item.donationType ?? 'Donation'} • Qty ${item.quantity}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          if ((item.pickupLocation ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Pickup: ${item.pickupLocation}'),
                          ],
                          if ((item.deliveryLocation ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Delivery: ${item.deliveryLocation}'),
                          ],
                          if ((item.acceptedByNgoUsername ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Accepted by: ${item.acceptedByNgoUsername}'),
                          ],
                          if ((item.assignedVolunteerUsername ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Volunteer: ${item.assignedVolunteerUsername}'),
                          ],
                          if (item.deliveryTaskId != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed(
                                  AppRoutes.deliveryTaskTracking,
                                  arguments: item.deliveryTaskId,
                                ),
                                icon: const Icon(Icons.track_changes_rounded),
                                label: const Text('Track delivery'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _statusChip(DonationRecord item) {
    final color = switch (item.status) {
      'pending' => AppTheme.statusWarning,
      'confirmed' => AppTheme.primaryGreen,
      'assigned' => AppTheme.primaryTeal,
      'picked_up' => AppTheme.primaryPinkColor,
      'in_transit' => AppTheme.primaryTeal,
      'completed' => AppTheme.statusSuccess,
      'expired' => AppTheme.statusError,
      _ => AppTheme.primaryTeal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        item.statusDisplay ?? item.status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
