import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soft_design_system.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/donation_request.dart' as shared;
import '../models/donation_request.dart';
import 'donation_details_screen.dart';

class BrowseDonationRequestsScreen extends StatefulWidget {
  const BrowseDonationRequestsScreen({super.key});

  @override
  State<BrowseDonationRequestsScreen> createState() =>
      _BrowseDonationRequestsScreenState();
}

class _BrowseDonationRequestsScreenState
    extends State<BrowseDonationRequestsScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<shared.DonationRequest> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getRequests(
        authHeaders: auth.authHeaders,
        status: 'open',
      );
      if (mounted) {
        setState(() {
          _requests = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftTheme.background,
      appBar: AppBar(
        title: const Text('Available Requests'),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: SoftTheme.primaryTeal),
            )
          : _error != null
          ? Center(
              child: Text(_error!),
            ) // Replace with your EmptyErrorState if needed
          : _requests.isEmpty
          ? const Center(child: Text('No active requests right now.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final req = _requests[index];
                return _StyledRequestCard(request: req);
              },
            ),
    );
  }
}

class _StyledRequestCard extends StatelessWidget {
  final shared.DonationRequest request;
  const _StyledRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor = SoftTheme.statusWarning; // Default
    if (request.status.toLowerCase() == 'fulfilled') {
      statusColor = SoftTheme.statusSuccess;
    }

    return CustomCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        final featReq = DonationRequestModel.fromDonationRequest(request);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DonationDetailsScreen(request: featReq),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SoftTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SoftTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(request.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: SoftTheme.textLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.location,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
