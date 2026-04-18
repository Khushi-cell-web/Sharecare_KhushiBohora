import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../home/widgets/dashboard_card.dart';
import '../../../widgets/empty_error_state.dart';

class VerifyOrganizationsScreen extends StatefulWidget {
  const VerifyOrganizationsScreen({super.key});

  @override
  State<VerifyOrganizationsScreen> createState() =>
      _VerifyOrganizationsScreenState();
}

class _VerifyOrganizationsScreenState extends State<VerifyOrganizationsScreen> {
  final _api = ShareCareApiService();
  List<Map<String, dynamic>> _profiles = [];
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
      final list = await _api.getAdminVerificationList(
        auth.authHeaders,
        status: 'pending',
      );
      if (mounted) {
        setState(() {
          _profiles = list;
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

  Future<void> _approve(int profileId, bool approve) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      await _api.approveNgo(
        auth.authHeaders,
        profileId,
        action: approve ? 'approve' : 'reject',
      );
      if (mounted) _load();
    } on ShareCareApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Organizations'),
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
          : _profiles.isEmpty
          ? const EmptyStateWidget(
              title: 'No pending verifications',
              subtitle: 'All organizations are verified',
              icon: Icons.verified_rounded,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _profiles.map((e) {
                final id = e['id'] as int? ?? 0;
                final name = e['username'] ?? 'NGO';
                final status =
                    e['verification_status_display'] ??
                    e['verification_status'] ??
                    'Pending';
                final verificationId = e['verification_id'] as String?;
                final subtitle =
                    verificationId != null && verificationId.isNotEmpty
                    ? 'Verification ID: $verificationId'
                    : 'Profile #$id';
                return DashboardCard(
                  title: name.toString(),
                  subtitle: subtitle,
                  badge: status.toString(),
                  badgeColor: status == 'Verified'
                      ? AppTheme.primaryGreen
                      : AppTheme.ctaOrange,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _approve(id, true),
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: () => _approve(id, false),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
