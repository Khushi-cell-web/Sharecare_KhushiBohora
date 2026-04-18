import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';

/// Volunteer: Update Task Status (API) + live sync if another session updates.
class UpdateTaskStatusScreen extends StatefulWidget {
  const UpdateTaskStatusScreen({super.key, this.task});

  final Map<String, dynamic>? task;

  @override
  State<UpdateTaskStatusScreen> createState() => _UpdateTaskStatusScreenState();
}

class _UpdateTaskStatusScreenState extends State<UpdateTaskStatusScreen> {
  final _api = ShareCareApiService();
  String _status = 'assigned';
  bool _loading = false;
  String? _error;
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  int? _taskId;

  @override
  void initState() {
    super.initState();
    _status =
        widget.task?['task_status'] as String? ??
        widget.task?['status'] as String? ??
        'assigned';
    _taskId = widget.task?['id'] as int?;
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWs());
  }

  void _connectWs() {
    final id = _taskId;
    if (id == null) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.accessToken == null) return;
    final wsUrl =
        '${ApiConstants.wsBaseUrl}/ws/delivery-tasks/$id/?token=${auth.accessToken}';
    try {
      _wsSub?.cancel();
      _ws?.sink.close();
      _ws = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsSub = _ws!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            if (msg['type'] != 'delivery_task_update') return;
            final tid = msg['task_id'];
            final tidInt = tid is int ? tid : (tid is num ? tid.toInt() : null);
            if (tidInt != id) return;
            final next = msg['task_status'] as String?;
            if (next != null && mounted) {
              setState(() => _status = next);
            }
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws?.sink.close();
    super.dispose();
  }

  Future<void> _save() async {
    final taskId = _taskId;
    if (taskId == null) {
      setState(() => _error = 'Invalid task');
      return;
    }
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.updateTask(auth.authHeaders, taskId, taskStatus: _status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.maybePop(context, true);
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
        title: const Text('Update Task Status'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(_status),
              initialValue: _status,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: 'assigned',
                  child: Text('Accepted by Volunteer'),
                ),
                DropdownMenuItem(value: 'picked', child: Text('Picked Up')),
                DropdownMenuItem(
                  value: 'in_transit',
                  child: Text('In Transit'),
                ),
                DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'assigned'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
