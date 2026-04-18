import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/receipt_file_helper.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../core/utils/app_routes.dart';
import '../shared/models/donation_transaction.dart';
import '../shared/providers/auth_provider.dart';
import '../widgets/status_badge.dart';

/// Donation History: list of user's past donations with status (from API).
class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  static const Color _pinkPrimary = Color(0xFFFFC1CC);
  static const Color _pinkLight = Color(0xFFFFEEF3);
  static const Color _pinkSoft = Color(0xFFFFD9E2);
  static const Color _roseText = Color(0xFF8A4E5E);
  static const Color _roseMutedText = Color(0xFFB07A88);

  String _filter = 'all';
  List<DonationTransaction> _history = [];
  _ImpactMetrics _impact = const _ImpactMetrics();
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Defer load to after first frame so UI shows loading state immediately (avoids ANR)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadHistory(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _downloadReceipt(BuildContext context, int transactionId) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      final api = ShareCareApiService();
      final bytes = await api.downloadReceiptForTransaction(
        auth.authHeaders,
        transactionId,
      );
      await saveAndOpenReceipt(bytes, 'sharecare_receipt_$transactionId.pdf');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt opened'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.authHeaders.isEmpty) {
      setState(() {
        _loading = false;
        _history = [];
        _impact = const _ImpactMetrics();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ShareCareApiService();
      final list = await api.getDonationHistory(auth.authHeaders);
      final currentUserId = auth.user?.id;
      final userScopedHistory = currentUserId == null
          ? list
          : list
                .where(
                  (txn) => txn.userId == null || txn.userId == currentUserId,
                )
                .toList();
      final impact = _calculateImpact(userScopedHistory);
      if (mounted) {
        setState(() {
          _history = userScopedHistory;
          _impact = impact;
          _loading = false;
          _error = null;
        });
      }
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        final refreshed = await auth.tryRefreshToken();
        if (refreshed) {
          _loadHistory();
          return;
        }
        await auth.logout();
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = NetworkErrorHelper.toUserMessage(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = NetworkErrorHelper.toUserMessage(e);
        });
      }
    }
  }

  List<DonationTransaction> get _filtered {
    if (_filter == 'active') {
      return _history
          .where((e) => e.status.toLowerCase().trim() == 'confirmed')
          .toList();
    }
    if (_filter == 'done') return _history.where((e) => e.isCompleted).toList();
    if (_filter == 'pending') {
      return _history.where((e) => e.isPending).toList();
    }
    return List.from(_history);
  }

  _ImpactMetrics _calculateImpact(List<DonationTransaction> items) {
    final completed = items.where((e) => e.isCompleted).length;
    final pending = items.where((e) => e.isPending).length;
    return _ImpactMetrics(
      completed: completed,
      pending: pending,
      total: items.length,
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
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
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: _roseText,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildGradientHeader()),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: _roseText),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _pinkPrimary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadHistory,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _roseText,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildContent(
                    list,
                    completed: _impact.completed,
                    pending: _impact.pending,
                    total: _impact.total,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pinkLight, _pinkPrimary, _pinkSoft],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _pinkPrimary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _roseText,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Donation History',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _roseText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loading ? null : _loadHistory,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _pinkPrimary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: _roseText,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pinkPrimary.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _pinkPrimary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your giving journey',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _roseText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track completed and pending donations in one place.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _roseMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection({
    required int completed,
    required int pending,
    required int total,
  }) {
    final completedCard = _buildStatCard(
      label: 'Completed',
      value: '$completed',
      icon: Icons.check_circle_rounded,
      tint: const Color(0xFF66BB6A),
    );
    final pendingCard = _buildStatCard(
      label: 'Pending',
      value: '$pending',
      icon: Icons.schedule_rounded,
      tint: const Color(0xFFFFB74D),
    );
    final totalCard = _buildStatCard(
      label: 'Total',
      value: '$total',
      icon: Icons.inventory_2_rounded,
      tint: _roseText,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: completedCard),
                  const SizedBox(width: 10),
                  Expanded(child: pendingCard),
                ],
              ),
              const SizedBox(height: 10),
              totalCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: completedCard),
            const SizedBox(width: 10),
            Expanded(child: pendingCard),
            const SizedBox(width: 10),
            Expanded(child: totalCard),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pinkPrimary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: _pinkPrimary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2F3442),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6D7688),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<DonationTransaction> list, {
    required int completed,
    required int pending,
    required int total,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _roseText,
            ),
          ),
          const SizedBox(height: 10),
          _buildStatsSection(
            completed: completed,
            pending: pending,
            total: total,
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', _filter == 'all'),
                const SizedBox(width: 8),
                _chip('Active', _filter == 'active'),
                const SizedBox(width: 8),
                _chip('Done', _filter == 'done'),
                const SizedBox(width: 8),
                _chip('Pending', _filter == 'pending'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 28),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _pinkPrimary.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: _pinkPrimary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: _pinkLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 46,
                      color: _roseText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No donations yet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _roseText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filter == 'all'
                        ? 'Your donation records will appear here once you make a contribution.'
                        : 'Try a different filter to view your donations.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF7D8698),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            )
          else
            ...list.map((e) => _buildDonationCard(e)),
        ],
      ),
    );
  }

  Widget _buildDonationCard(DonationTransaction e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, _pinkLight.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pinkPrimary.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: _pinkPrimary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_pinkPrimary, _roseText],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pinkLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: _roseText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.donationRequestTitle ?? 'Donation #${e.id}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF3B4150),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.amount} ${e.currency} • ${_formatDate(e.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D8698),
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.isCompleted)
                  IconButton(
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      color: _roseText,
                    ),
                    onPressed: () => _downloadReceipt(context, e.id),
                    tooltip: 'Download receipt',
                  ),
                StatusBadge(label: e.statusDisplay ?? e.status, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _filter = label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _pinkPrimary.withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _pinkPrimary : const Color(0xFFE2E7EF),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _pinkPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _roseText : const Color(0xFF7D8698),
          ),
        ),
      ),
    );
  }
}

class _ImpactMetrics {
  const _ImpactMetrics({this.completed = 0, this.pending = 0, this.total = 0});

  final int completed;
  final int pending;
  final int total;
}
