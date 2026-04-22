import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/models/volunteer_task.dart';
import '../../../shared/providers/auth_provider.dart';

/// Volunteer tasks currently assigned to the user.
class VolunteerAssignedTab extends StatefulWidget {
  const VolunteerAssignedTab({super.key});

  @override
  State<VolunteerAssignedTab> createState() => _VolunteerAssignedTabState();
}

class _VolunteerAssignedTabState extends State<VolunteerAssignedTab> {
  final ShareCareApiService _api = ShareCareApiService();
  List<VolunteerTask> _tasks = [];
  bool _loading = true;
  String? _error;

  Future<T> _runWithAuthRetry<T>(
    Future<T> Function(Map<String, String> headers) operation,
  ) async {
    final auth = context.read<AuthProvider>();
    try {
      return await operation(auth.authHeaders);
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await auth.tryRefreshToken();
        if (refreshed) {
          return await operation(auth.authHeaders);
        }
      }
      rethrow;
    }
  }

  List<VolunteerTask> get _activeTasks =>
      _tasks.where((t) => t.taskStatus != 'delivered').toList();

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
      final list = await _api.getMyTasks(auth.authHeaders);
      if (mounted) {
        setState(() {
          _tasks = list;
          _loading = false;
        });
      }
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await auth.tryRefreshToken();
        if (refreshed) {
          _load();
          return;
        }
      }
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

  Future<void> _updateStatus(VolunteerTask task, String newStatus) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      final updated = await _runWithAuthRetry(
        (headers) => _api.updateTask(headers, task.id, taskStatus: newStatus),
      );

      if (newStatus == 'delivered') {
        await auth.loadUser();
      }

      if (mounted) {
        final statusLabel = newStatus == 'picked'
            ? 'Picked Up'
            : newStatus == 'in_transit'
            ? 'In Transit'
            : 'Delivered';
        final pointsMsg =
            (newStatus == 'delivered' && updated.pointsEarnedNow > 0)
            ? ' +${updated.pointsEarnedNow} points'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $statusLabel$pointsMsg'),
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
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Assigned Tasks',
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
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.taskHistory).then((_) => _load()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              )
            : _error != null
            ? Center(
                child: Padding(
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
              )
            : _activeTasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active tasks',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.taskHistory),
                      icon: const Icon(Icons.history_rounded, size: 20),
                      label: const Text('View completed'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _activeTasks.length,
                itemBuilder: (context, i) {
                  final t = _activeTasks[i];
                  return _AssignedTaskCard(
                    task: t,
                    onMarkPickedUp: () => _updateStatus(t, 'picked'),
                    onStartDelivery: () => _updateStatus(t, 'in_transit'),
                    onMarkDelivered: () => _updateStatus(t, 'delivered'),
                    onTapMap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.volunteerMap, arguments: t),
                  );
                },
              ),
      ),
    );
  }
}

class _AssignedTaskCard extends StatelessWidget {
  const _AssignedTaskCard({
    required this.task,
    required this.onMarkPickedUp,
    required this.onStartDelivery,
    required this.onMarkDelivered,
    required this.onTapMap,
  });

  final VolunteerTask task;
  final VoidCallback onMarkPickedUp;
  final VoidCallback onStartDelivery;
  final VoidCallback onMarkDelivered;
  final VoidCallback onTapMap;

  @override
  Widget build(BuildContext context) {
    final categoryLabel =
        task.donationRequestCategoryDisplay ??
        task.donationRequestCategory ??
        'Donation';
    final isUrgent = task.isUrgentDelivery;
    final deliveryPoints = task.deliveryPoints > 0
        ? task.deliveryPoints
        : (isUrgent ? 20 : 10);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.taskStatusDisplay ?? task.taskStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.statusError.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'High Urgency',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.statusError,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$deliveryPoints pts',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.statusSuccess,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.donationRequestTitle ?? 'Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.donorUsername != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Donor: ${task.donorUsername}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _LocationRow(
              icon: Icons.upload_rounded,
              label: 'Pickup',
              address: task.pickupLocation,
            ),
            const SizedBox(height: 4),
            _LocationRow(
              icon: Icons.download_rounded,
              label: 'Delivery',
              address: task.deliveryLocation,
            ),
            if (task.deliveryLatitude != null &&
                task.deliveryLongitude != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: onTapMap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'View on Map',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (task.isAssigned)
                  FilledButton.tonal(
                    onPressed: onMarkPickedUp,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal.withValues(
                        alpha: 0.2,
                      ),
                      foregroundColor: AppTheme.primaryTeal,
                    ),
                    child: const Text('Mark Picked Up'),
                  ),
                if (task.isPickedUp)
                  FilledButton.tonal(
                    onPressed: onStartDelivery,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange.withValues(
                        alpha: 0.2,
                      ),
                      foregroundColor: AppTheme.accentOrange,
                    ),
                    child: const Text('Start Delivery'),
                  ),
                if (task.isInTransit)
                  FilledButton(
                    onPressed: onMarkDelivered,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.statusSuccess,
                    ),
                    child: Text('Mark Delivered (+$deliveryPoints pts)'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.address,
  });
  final IconData icon;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                address,
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.navy),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
