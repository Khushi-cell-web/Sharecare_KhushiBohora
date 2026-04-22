import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/models/volunteer_task.dart';
import '../shared/providers/auth_provider.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../core/utils/app_routes.dart';
import '../core/theme/app_theme.dart';

class VolunteerTasksScreen extends StatefulWidget {
  const VolunteerTasksScreen({super.key});

  @override
  State<VolunteerTasksScreen> createState() => _VolunteerTasksScreenState();
}

class _VolunteerTasksScreenState extends State<VolunteerTasksScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<VolunteerTask> _tasks = [];
  bool _loading = true;
  String? _error;

  Future<void> _loadTasks() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _tasks = [];
          _error = 'Please log in to view tasks.';
        });
      }
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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _updateStatus(VolunteerTask task, String status) async {
    final auth = context.read<AuthProvider>();
    try {
      await _api.updateTask(auth.authHeaders, task.id, taskStatus: status);
      if (mounted) _loadTasks();
    } on ShareCareApiException catch (e) {
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
        title: const Text('My volunteer tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _loading
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
                      FilledButton(
                        onPressed: _loadTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : _tasks.isEmpty
            ? const Center(
                child: Text(
                  'No volunteer tasks. Accept a task from a donation request.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final t = _tasks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.donationRequestTitle ??
                                (t.donationId != null
                                    ? 'Standalone donation'
                                    : 'Volunteer task'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Pickup: ${t.pickupLocation}'),
                          Text('Delivery: ${t.deliveryLocation}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                label: Text(
                                  t.taskStatusDisplay ?? t.taskStatus,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.deliveryTaskTracking,
                                      arguments: t.id,
                                    ),
                                icon: const Icon(
                                  Icons.podcasts_rounded,
                                  size: 18,
                                ),
                                label: const Text('Live'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                ),
                              ),
                              if (t.taskStatus == 'assigned')
                                TextButton(
                                  onPressed: () => _updateStatus(t, 'picked'),
                                  child: const Text('Mark picked'),
                                ),
                              if (t.taskStatus == 'picked')
                                TextButton(
                                  onPressed: () =>
                                      _updateStatus(t, 'delivered'),
                                  child: const Text('Mark delivered'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
