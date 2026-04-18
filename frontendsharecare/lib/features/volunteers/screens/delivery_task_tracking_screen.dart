import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

/// Live delivery status for donor, NGO, and volunteer (WebSocket).
class DeliveryTaskTrackingScreen extends StatefulWidget {
  const DeliveryTaskTrackingScreen({super.key, required this.taskId});

  final int taskId;

  @override
  State<DeliveryTaskTrackingScreen> createState() =>
      _DeliveryTaskTrackingScreenState();
}

class _DeliveryTaskTrackingScreenState
    extends State<DeliveryTaskTrackingScreen> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  String _statusDisplay = 'Connecting…';
  String _statusCode = '';
  String _pickup = '—';
  String _delivery = '—';
  String _volunteer = '—';
  String _updated = '—';
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  void _connect() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.accessToken == null) {
      setState(() => _error = 'Please log in to track this delivery.');
      return;
    }
    final wsUrl =
        '${ApiConstants.wsBaseUrl}/ws/delivery-tasks/${widget.taskId}/?token=${auth.accessToken}';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _sub = _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            if (msg['type'] != 'delivery_task_update') return;
            if (mounted) {
              setState(() {
                _error = null;
                _connected = true;
                _statusCode = msg['task_status'] as String? ?? '';
                _statusDisplay =
                    msg['task_status_display'] as String? ?? _statusCode;
                _pickup = msg['pickup_location'] as String? ?? '—';
                _delivery = msg['delivery_location'] as String? ?? '—';
                final vu = msg['volunteer_username'] as String?;
                _volunteer = (vu != null && vu.isNotEmpty)
                    ? vu
                    : 'Not assigned yet';
                _updated = msg['updated_at'] as String? ?? '—';
              });
            }
          } catch (_) {}
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _error =
                  'Connection error. Pull to reconnect or check your network.';
              _connected = false;
            });
          }
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
      );
    } catch (e) {
      setState(() => _error = 'Could not open live connection.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live delivery status'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryTeal,
        onRefresh: () async {
          _sub?.cancel();
          _channel?.sink.close();
          _channel = null;
          _sub = null;
          setState(() {
            _statusDisplay = 'Connecting…';
            _error = null;
          });
          _connect();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              children: [
                Icon(
                  _connected ? Icons.podcasts_rounded : Icons.cloud_off_rounded,
                  color: _connected ? AppTheme.primaryGreen : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _connected ? 'Live updates' : 'Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _connected ? AppTheme.primaryGreenDark : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusPill(),
                    const SizedBox(height: 12),
                    _row(Icons.person_outline_rounded, 'Volunteer', _volunteer),
                    _row(Icons.local_shipping_rounded, 'Pickup', _pickup),
                    _row(Icons.location_on_rounded, 'Delivery', _delivery),
                    _row(Icons.schedule_rounded, 'Last update', _updated),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Donor, organization, and volunteer share the same live status. '
              'Volunteers can open this before claiming to watch for assignment.',
              style: TextStyle(fontSize: 13, color: AppTheme.navyLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill() {
    final bg = switch (_statusCode) {
      'pending_volunteer' => AppTheme.statusPendingPastel,
      'assigned' => AppTheme.statusVolunteerPastel,
      'picked' => AppTheme.statusVolunteerPastel,
      'in_transit' => AppTheme.pastelBlueDeep,
      'delivered' => AppTheme.statusCompletedPastel,
      _ => AppTheme.pastelMintLight,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 22, color: AppTheme.primaryGreenDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(fontSize: 12, color: AppTheme.navyLight),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppTheme.navyLight),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
