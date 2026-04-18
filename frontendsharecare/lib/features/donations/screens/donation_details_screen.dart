import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soft_design_system.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/donation_request.dart';
import 'offer_donation_screen.dart';

class DonationDetailsScreen extends StatefulWidget {
  const DonationDetailsScreen({super.key, required this.request});
  final DonationRequestModel request;

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  Map<String, dynamic>? _progress;
  bool _progressLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final id = int.tryParse(widget.request.id);
    if (id == null) return;
    final auth = context.read<AuthProvider>();
    setState(() => _progressLoading = true);
    try {
      final p = await ShareCareApiService().getCampaignProgress(
        auth.authHeaders,
        id,
      );
      if (mounted) {
        setState(() {
          _progress = p;
          _progressLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _progressLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final goalAmount = (_progress?['goal_amount'] as num?)?.toDouble() ?? 0.0;
    final raisedAmount =
        (_progress?['raised_amount'] as num?)?.toDouble() ?? 0.0;
    final percentFunded =
        (_progress?['percent_funded'] as num?)?.toDouble() ?? 0.0;

    // Fallback for non-monetary requests using provided quantities
    final double displayProgress = goalAmount > 0
        ? (percentFunded / 100).clamp(0.0, 1.0)
        : (req.quantity > 0
              ? ((req.quantity - (req.remainingQuantity ?? req.quantity)) /
                        req.quantity)
                    .clamp(0.0, 1.0)
              : 0.0);

    final String amountText = goalAmount > 0
        ? 'NPR $raisedAmount / NPR $goalAmount'
        : '${req.quantity - (req.remainingQuantity ?? req.quantity)} / ${req.quantity} collected\n(${req.remainingQuantity ?? req.quantity} remaining)';

    return Scaffold(
      backgroundColor: SoftTheme.background,
      appBar: AppBar(title: const Text('Donation Details'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  req.category.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SoftTheme.primaryTeal,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: req.status.toLowerCase() == 'fulfilled'
                        ? SoftTheme.statusSuccess.withOpacity(0.1)
                        : SoftTheme.statusWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: req.status.toLowerCase() == 'fulfilled'
                          ? SoftTheme.statusSuccess
                          : SoftTheme.statusWarning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              req.title,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),

            // Subtitle info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: SoftTheme.textLight),
                const SizedBox(width: 8),
                Text(
                  'By ${req.organizationName ?? req.requestedByLabel ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_progressLoading)
              const Center(
                child: CircularProgressIndicator(color: SoftTheme.primaryTeal),
              )
            else
              // Progress Section
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: displayProgress.clamp(0.0, 1.0),
                      label: 'Funded',
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal Progress',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            amountText,
                            style: const TextStyle(
                              color: SoftTheme.primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Description
            const SectionHeader(title: "Description"),
            Text(
              req.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),

            // Details Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: req.location,
                  ),
                  const Divider(height: 24, color: SoftTheme.background),
                  _DetailRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Urgency',
                    value: req.urgency.toUpperCase(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Action Button
            if (req.status.toLowerCase() != 'fulfilled')
              GradientButton(
                text: 'Donate Now',
                icon: Icons.favorite,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OfferDonationScreen(request: req),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SoftTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: SoftTheme.primaryTeal, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
