import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/donation_request.dart';
import '../../home/widgets/dashboard_card.dart';
import '../../../widgets/empty_error_state.dart';

/// NGO: Manage My Requests - list from API.
class ManageMyRequestsScreen extends StatefulWidget {
  const ManageMyRequestsScreen({super.key});

  @override
  State<ManageMyRequestsScreen> createState() => _ManageMyRequestsScreenState();
}

class _ManageMyRequestsScreenState extends State<ManageMyRequestsScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationRequest> _requests = [];
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
      final list = await _api.getMyRequests(auth.authHeaders);
      if (mounted) {
        setState(() {
          _requests = list;
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
        title: const Text('Manage My Requests'),
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
          : _requests.isEmpty
          ? const EmptyStateWidget(
              title: 'No requests yet',
              subtitle: 'Create a donation request from your dashboard',
              icon: Icons.assignment_rounded,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _requests
                  .map(
                    (r) => DashboardCard(
                      title: r.title,
                      subtitle:
                          '${r.categoryDisplay ?? r.category} • Qty: ${r.quantityNeeded}',
                      badge: r.statusDisplay ?? r.status,
                      badgeColor: r.status == 'fulfilled'
                          ? AppTheme.primaryGreen
                          : AppTheme.ctaOrange,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.ngoRequestDetails,
                        arguments: r.toMap(),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
