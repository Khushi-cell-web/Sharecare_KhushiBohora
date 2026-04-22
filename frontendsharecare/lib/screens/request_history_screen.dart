import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/models/donation_request.dart';
import '../features/home/widgets/dashboard_card.dart';
import '../widgets/empty_error_state.dart';

/// Request History: NGO's past donation requests from API (all statuses).
class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
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
          _error = 'Please log in to view request history.';
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

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Request History'),
        backgroundColor: AppTheme.primaryTeal,
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
          : _requests.isEmpty
          ? const EmptyStateWidget(
              title: 'No requests yet',
              subtitle: 'Create a donation request from your dashboard',
              icon: Icons.assignment_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final r = _requests[index];
                final statusDisplay = r.statusDisplay ?? r.status;
                return DashboardCard(
                  title: r.title,
                  subtitle:
                      '${r.categoryDisplay ?? r.category} • Qty: ${r.quantityNeeded} • ${_timeAgo(r.createdAt)}',
                  badge: statusDisplay,
                  badgeColor: r.status == 'fulfilled'
                      ? AppTheme.primaryTeal
                      : AppTheme.ctaOrange,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.ngoRequestDetails,
                    arguments: r.toMap(),
                  ),
                );
              },
            ),
    );
  }
}
