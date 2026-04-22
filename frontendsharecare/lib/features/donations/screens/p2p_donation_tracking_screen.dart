import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../shared/providers/auth_provider.dart';

class P2PDonationTrackingScreen extends StatefulWidget {
  final String donationId;

  const P2PDonationTrackingScreen({super.key, required this.donationId});

  @override
  State<P2PDonationTrackingScreen> createState() =>
      _P2PDonationTrackingScreenState();
}

class _P2PDonationTrackingScreenState extends State<P2PDonationTrackingScreen> {
  Map<String, dynamic>? _donation;
  bool _isLoading = true;

  final List<String> _orderedStatuses = [
    'CREATED',
    'REQUESTED',
    'ACCEPTED',
    'SCHEDULED',
    'ON_THE_WAY',
    'COMPLETED',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDonation();
  }

  Future<void> _fetchDonation() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>().authHeaders;
      final data = await ShareCareApiService().getP2PDonationDetail(
        widget.donationId,
        auth,
      );
      setState(() {
        _donation = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String action) async {
    try {
      final auth = context.read<AuthProvider>().authHeaders;
      final data = await ShareCareApiService().updateP2PDonationStatus(
        widget.donationId,
        action,
        auth,
      );
      setState(() {
        _donation = data;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildTimelineAndActions() {
    if (_donation == null) return const SizedBox();

    final currentStatus = _donation!['status'] as String;
    final int currentIndex = _orderedStatuses.indexOf(currentStatus);
    final history = _donation!['status_history'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentStatus == 'COMPLETED')
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryPinkColor.withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration, color: AppTheme.primaryPinkDark),
                SizedBox(width: 8),
                Text(
                  '🎊 Donation Successful!',
                  style: TextStyle(
                    color: AppTheme.primaryPinkDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Tracking Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._orderedStatuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;

          final historyEntry = history.firstWhere(
            (h) => h['status'] == status,
            orElse: () => null,
          );

          return ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCurrent
                  ? Colors.blue
                  : (isCompleted ? AppTheme.primaryPinkDark : Colors.grey),
            ),
            title: Text(
              status,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: historyEntry != null
                ? Text(
                    'Updated: ${DateTime.parse(historyEntry["timestamp"]).toLocal().toString().split(".")[0]}',
                  )
                : null,
          );
        }),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final currentStatus = _donation!['status'] as String;
    final currentUser = context.read<AuthProvider>().user;
    final isDonor = _donation!['donor']['id'] == currentUser?.id;
    final isReceiver =
        _donation!['receiver'] != null &&
        _donation!['receiver']['id'] == currentUser?.id;
    final hasNoReceiver = _donation!['receiver'] == null;

    if (currentStatus == 'COMPLETED') {
      return const SizedBox(); // No active buttons
    }

    if (currentStatus == 'CREATED') {
      if (isDonor) {
        return const Center(child: Text('Waiting for requests...'));
      } else if (hasNoReceiver) {
        return ElevatedButton(
          onPressed: () => _updateStatus('request_donation'),
          child: const Text('Request Donation'),
        );
      }
    }

    if (currentStatus == 'REQUESTED') {
      if (isDonor) {
        return ElevatedButton(
          onPressed: () => _updateStatus('accept_request'),
          child: const Text('Accept Request'),
        );
      } else if (isReceiver) {
        return const Center(child: Text('Waiting for Donor to accept...'));
      }
    }

    if (currentStatus == 'ACCEPTED') {
      if (isDonor || isReceiver) {
        return ElevatedButton(
          onPressed: () => _updateStatus('schedule_pickup'),
          child: const Text('Schedule Pickup / Meeting'),
        );
      }
    }

    if (currentStatus == 'SCHEDULED') {
      if (isDonor || isReceiver) {
        return ElevatedButton(
          onPressed: () => _updateStatus('dispatch_item'),
          child: const Text('Mark as On The Way'),
        );
      }
    }

    if (currentStatus == 'ON_THE_WAY') {
      if (isReceiver) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPinkDark,
          ),
          onPressed: () => _updateStatus('complete_donation'),
          child: const Text('Confirm Item Received'),
        );
      } else if (isDonor) {
        return const Center(
          child: Text('Waiting for Receiver to confirm delivery...'),
        );
      }
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Donation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item: ${_donation!["title"]}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${_donation!["status"]}'),
                  const SizedBox(height: 24),
                  _buildTimelineAndActions(),
                ],
              ),
            ),
    );
  }
}
