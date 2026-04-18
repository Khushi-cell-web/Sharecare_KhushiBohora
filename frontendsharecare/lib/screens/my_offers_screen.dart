import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/models/donation_offer.dart';
import '../shared/providers/auth_provider.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../core/utils/app_routes.dart';
import '../core/theme/app_theme.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationOffer> _offers = [];
  bool _loading = true;
  String? _error;

  Future<void> _loadOffers() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _offers = [];
          _error = 'Please log in to view your offers.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getMyOffers(auth.authHeaders);
      if (mounted) setState(() => _offers = list);
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My donation offers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOffers,
        child: _loading
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
                      FilledButton(
                        onPressed: _loadOffers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : _offers.isEmpty
            ? const Center(
                child: Text(
                  'No donation offers yet. Offer from the home screen.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _offers.length,
                itemBuilder: (context, index) {
                  final o = _offers[index];
                  final hasTask = o.deliveryTaskId != null;
                  final canTrack =
                      hasTask &&
                      o.status == 'accepted' &&
                      o.type == 'material' &&
                      (o.fulfillmentType == 'volunteer_pickup');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        o.donationRequestTitle ??
                            'Request #${o.donationRequest}',
                      ),
                      subtitle: Text(
                        '${o.typeDisplay ?? o.type} • Qty: ${o.quantity}\n${o.statusDisplay ?? o.status}',
                      ),
                      isThreeLine: true,
                      trailing: canTrack
                          ? TextButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed(
                                AppRoutes.deliveryTaskTracking,
                                arguments: o.deliveryTaskId,
                              ),
                              icon: const Icon(
                                Icons.podcasts_rounded,
                                size: 18,
                              ),
                              label: const Text('Live'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
