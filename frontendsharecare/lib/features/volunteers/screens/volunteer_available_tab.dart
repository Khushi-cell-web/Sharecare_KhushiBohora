import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/models/donation_request.dart';
import '../../../shared/models/volunteer_task.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/modern_button.dart';
import '../../../shared/widgets/donation_card_widget.dart';

/// Pending NGO-accepted pickups (claim/decline) + legacy open requests without a task row.
class VolunteerAvailableTab extends StatefulWidget {
  const VolunteerAvailableTab({super.key});

  @override
  State<VolunteerAvailableTab> createState() => _VolunteerAvailableTabState();
}

class _VolunteerAvailableTabState extends State<VolunteerAvailableTab> {
  final ShareCareApiService _api = ShareCareApiService();
  List<VolunteerTask> _pending = [];
  List<DonationRequest> _legacy = [];
  bool _loading = true;
  String? _error;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
    try {
      final results = await Future.wait([
        _api.getPendingVolunteerTasks(auth.authHeaders),
        _api.getAvailableRequestsForVolunteer(auth.authHeaders),
      ]);
      if (mounted) {
        setState(() {
          _pending = results[0] as List<VolunteerTask>;
          _legacy = results[1] as List<DonationRequest>;
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

  double? _distanceKm(DonationRequest r) {
    if (_userLat == null ||
        _userLng == null ||
        r.latitude == null ||
        r.longitude == null) {
      return null;
    }
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((r.latitude! - _userLat!) * p) / 2 +
        cos(_userLat! * p) *
            cos(r.latitude! * p) *
            (1 - cos((r.longitude! - _userLng!) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _claim(VolunteerTask task) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      await _api.claimVolunteerTask(auth.authHeaders, task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You claimed: ${task.donationRequestTitle ?? "task"}',
            ),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        _load();
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  Future<void> _decline(VolunteerTask task) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      await _api.declineVolunteerTask(auth.authHeaders, task.id);
      if (mounted) _load();
    } on ShareCareApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  Future<void> _acceptLegacy(DonationRequest request) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.volunteerAcceptTask, arguments: request);
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final empty =
        !_loading && _error == null && _pending.isEmpty && _legacy.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Available for Pickup',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
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
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              )
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.statusError),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : empty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No pickups available right now',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_pending.isNotEmpty) ...[
                    _sectionTitle('Pending pickups — tap Claim'),
                    const SizedBox(height: 8),
                    ..._pending.map((t) => _pendingTaskCard(t)),
                    if (_legacy.isNotEmpty) const SizedBox(height: 20),
                  ],
                  if (_legacy.isNotEmpty) ...[
                    _sectionTitle('Other campaigns (no task yet)'),
                    const SizedBox(height: 8),
                    ..._legacy.map((r) {
                      final dist = _distanceKm(r);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ModernDonationCard(
                          request: r,
                          distanceKm: dist,
                          onTap: () => _acceptLegacy(r),
                          showDistance: true,
                          trailing: ModernButton(
                            label: 'Accept',
                            onPressed: () => _acceptLegacy(r),
                            variant: ButtonVariant.primary,
                            size: ButtonSize.small,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.navy,
      ),
    );
  }

  Widget _pendingTaskCard(VolunteerTask t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.donationRequestTitle ?? 'Donation pickup',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            if (t.donorUsername != null) ...[
              const SizedBox(height: 4),
              Text(
                'Donor: ${t.donorUsername}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pickup: ${t.pickupLocation}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: 18,
                  color: AppTheme.secondaryGreen,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Deliver to: ${t.deliveryLocation}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.deliveryTaskTracking, arguments: t.id),
                icon: const Icon(Icons.podcasts_rounded, size: 20),
                label: const Text('Live delivery status'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(t),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _claim(t),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Claim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
