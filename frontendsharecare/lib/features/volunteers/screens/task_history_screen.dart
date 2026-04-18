import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/models/volunteer_task.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../home/widgets/dashboard_card.dart';

/// Volunteer: Task History from API (all tasks, sorted by date).
class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<VolunteerTask> _tasks = [];
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
      setState(() {
        _loading = false;
        _error = 'Please log in to view task history.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getMyTasks(auth.authHeaders);
      if (mounted) setState(() => _tasks = list);
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
      return '${diff.inDays ~/ 30} months ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
          : _tasks.isEmpty
          ? Center(
              child: Text(
                'No tasks yet.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _tasks
                  .map(
                    (t) => DashboardCard(
                      title: '${t.pickupLocation} → ${t.deliveryLocation}',
                      subtitle:
                          _formatDate(t.createdAt) +
                          (t.donationRequestTitle != null
                              ? ' • ${t.donationRequestTitle}'
                              : ''),
                      badge: t.taskStatusDisplay ?? t.taskStatus,
                      badgeColor: t.taskStatus == 'delivered'
                          ? AppTheme.primaryGreen
                          : AppTheme.ctaOrange,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
