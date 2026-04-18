import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
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
      final list = await _api.getReceivedDonations(auth.authHeaders);
      if (mounted) {
        setState(() {
          _offers = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Donations / Inventory'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
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
          ? const Center(
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
          ? const EmptyStateWidget(
              title: 'No received donations yet',
              subtitle: 'Accepted offers will appear here',
              icon: Icons.inventory_rounded,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
}
