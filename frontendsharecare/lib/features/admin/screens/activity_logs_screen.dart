import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../home/widgets/dashboard_card.dart';
import '../../../widgets/empty_error_state.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final _api = ShareCareApiService();
  List<Map<String, dynamic>> _logs = [];
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
      final list = await _api.getActivityLogs(auth.authHeaders);
      if (mounted) {
        setState(() {
          _logs = list;
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

  String _formatTime(String? iso) {
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
      appBar: AppBar(
        title: const Text('Activity Logs'),
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
          : _logs.isEmpty
          ? const EmptyStateWidget(
              title: 'No activity logs',
              subtitle: 'System activity will appear here',
              icon: Icons.history_rounded,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _logs.map((e) {
                final message = e['message'] ?? e['action'] ?? 'Activity';
                final createdAt = e['created_at'] as String?;
                final action = e['action'] ?? 'System';
                return DashboardCard(
                  title: message.toString(),
                  subtitle: _formatTime(createdAt),
                  badge: action.toString(),
                  badgeColor: AppTheme.primaryGreen,
                );
              }).toList(),
            ),
    );
  }
}
