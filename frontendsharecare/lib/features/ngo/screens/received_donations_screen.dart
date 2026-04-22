import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/donation_record.dart';
import '../../../shared/models/donation_offer.dart';
import '../../home/widgets/dashboard_card.dart';
import '../../../widgets/empty_error_state.dart';
import '../../../core/utils/app_routes.dart';

/// NGO: Received Donations / Inventory from API (accepted offers).
class ReceivedDonationsScreen extends StatefulWidget {
  const ReceivedDonationsScreen({super.key});

  @override
  State<ReceivedDonationsScreen> createState() =>
      _ReceivedDonationsScreenState();
}

class _ReceivedDonationsScreenState extends State<ReceivedDonationsScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRecord> _pendingDonations = [];
  List<DonationRecord> _acceptedDonations = [];
  List<DonationOffer> _offers = [];
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
          _error = 'Please log in.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getNgoPendingDonations(auth.authHeaders),
        _api.getNgoAcceptedDonations(auth.authHeaders),
        _api.getReceivedDonations(auth.authHeaders),
      ]);
      if (mounted) {
        setState(() {
          _pendingDonations = results[0] as List<DonationRecord>;
          _acceptedDonations = results[1] as List<DonationRecord>;
          _offers = results[2] as List<DonationOffer>;
          _loading = false;
          _error = null;
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

  Future<void> _acceptDonation(DonationRecord donation) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    try {
      await _api.acceptDonation(auth.authHeaders, donation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation accepted')),
        );
        _load();
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkErrorHelper.toUserMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkErrorHelper.toUserMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Donations / Inventory'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.primaryPinkDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : _offers.isEmpty
          ? _pendingDonations.isEmpty && _acceptedDonations.isEmpty
              ? const EmptyStateWidget(
                  title: 'No received donations yet',
                  subtitle: 'Pending donations and accepted offers will appear here',
                  icon: Icons.inventory_rounded,
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_pendingDonations.isNotEmpty) ...[
                      Text(
                        'Pending donations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._pendingDonations.map(
                        (donation) => _pendingDonationCard(donation),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_acceptedDonations.isNotEmpty) ...[
                      Text(
                        'Accepted donations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._acceptedDonations.map(
                        (donation) => _acceptedDonationCard(donation),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_offers.isNotEmpty) ...[
                      Text(
                        'Inventory summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._offers.map(_offerCard),
                    ],
                  ],
                )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_pendingDonations.isNotEmpty) ...[
                  Text(
                    'Pending donations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._pendingDonations.map((donation) => _pendingDonationCard(donation)),
                  const SizedBox(height: 20),
                ],
                if (_acceptedDonations.isNotEmpty) ...[
                  Text(
                    'Accepted donations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._acceptedDonations.map((donation) => _acceptedDonationCard(donation)),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Inventory summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 12),
                ..._offers.map((e) {
                  final tid = e.deliveryTaskId;
                  final track =
                      tid != null &&
                      e.status == 'accepted' &&
                      e.type == 'material' &&
                      e.fulfillmentType == 'volunteer_pickup';
                  return DashboardCard(
                    title:
                        e.donationRequestTitle ??
                        'Request #${e.donationRequest}',
                    subtitle: '${e.typeDisplay ?? e.type} • Qty: ${e.quantity}',
                    badge: e.statusDisplay ?? e.status,
                    badgeColor: e.status == 'accepted'
                        ? AppTheme.primaryGreen
                        : AppTheme.ctaOrange,
                    onTap: track
                        ? () => Navigator.of(context).pushNamed(
                            AppRoutes.deliveryTaskTracking,
                            arguments: tid,
                          )
                        : null,
                  );
                }),
              ],
            ),
    );
  }

  Widget _pendingDonationCard(DonationRecord donation) {
    final acceptedBy = donation.acceptedByNgoUsername ?? 'Any NGO';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.primaryTeal.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.headline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusBadge(donation),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${donation.typeDisplay ?? donation.donationType ?? 'Donation'} • Qty ${donation.quantity}',
            ),
            const SizedBox(height: 6),
            Text('Donor: ${donation.donorUsername ?? 'Unknown'}'),
            const SizedBox(height: 6),
            Text('Accepted by: $acceptedBy'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _acceptDonation(donation),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acceptedDonationCard(DonationRecord donation) {
    final tid = donation.deliveryTaskId;
    final track = tid != null;
    return DashboardCard(
      title: donation.headline,
      subtitle:
          '${donation.typeDisplay ?? donation.donationType ?? 'Donation'} • Qty: ${donation.quantity}',
      badge: donation.statusDisplay ?? donation.status,
      badgeColor: AppTheme.primaryGreen,
      onTap: track
          ? () => Navigator.of(context).pushNamed(
              AppRoutes.deliveryTaskTracking,
              arguments: tid,
            )
          : null,
    );
  }

  Widget _offerCard(DonationOffer e) {
    final tid = e.deliveryTaskId;
    final track =
        tid != null &&
        e.status == 'accepted' &&
        e.type == 'material' &&
        e.fulfillmentType == 'volunteer_pickup';
    return DashboardCard(
      title: e.donationRequestTitle ?? 'Request #${e.donationRequest}',
      subtitle: '${e.typeDisplay ?? e.type} • Qty: ${e.quantity}',
      badge: e.statusDisplay ?? e.status,
      badgeColor: e.status == 'accepted' ? AppTheme.primaryGreen : AppTheme.ctaOrange,
      onTap: track
          ? () => Navigator.of(context).pushNamed(
              AppRoutes.deliveryTaskTracking,
              arguments: tid,
            )
          : null,
    );
  }

  Widget _statusBadge(DonationRecord donation) {
    final color = switch (donation.status) {
      'pending' => AppTheme.ctaOrange,
      'confirmed' => AppTheme.primaryGreen,
      'assigned' => AppTheme.primaryTeal,
      'picked_up' => AppTheme.primaryPinkColor,
      'in_transit' => AppTheme.primaryTeal,
      'completed' => AppTheme.statusSuccess,
      _ => AppTheme.primaryTeal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        donation.statusDisplay ?? donation.status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
