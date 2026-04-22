import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/models/donation_match.dart';
import '../../../shared/providers/auth_provider.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  List<DonationMatch> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please log in to view matches.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final list = await _api.getMyMatches(auth.authHeaders);
      if (mounted) {
        setState(() {
          _matches = list;
          _error = null;
        });
      }
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _titleCase(String v) {
    if (v.trim().isEmpty) return v;
    final s = v.trim();
    return s[0].toUpperCase() + s.substring(1);
  }

  String? _formatIsoDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  bool _canAccept(DonationMatch m) {
    if (m.status != 'pending') return false;
    if (m.myRole == 'donor') return m.donorDecision == 'pending';
    if (m.myRole == 'receiver') return m.receiverDecision == 'pending';
    return false;
  }

  bool _canReject(DonationMatch m) {
    if (m.status != 'pending') return false;
    if (m.myRole == 'donor') return m.donorDecision != 'rejected';
    if (m.myRole == 'receiver') return m.receiverDecision != 'rejected';
    return false;
  }

  Future<void> _respond(DonationMatch m, String decision) async {
    final auth = context.read<AuthProvider>();
    await _api.respondToMatch(
      auth.authHeaders,
      matchId: m.id,
      response: decision,
    );
    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Matchmaking'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.primaryPinkDark,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : _matches.isEmpty
          ? Center(
              child: Text(
                'No matches yet.',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryTeal,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final m = _matches[index];
                  final category = _titleCase(m.category);
                  final distanceText = m.distanceKm != null
                      ? '${m.distanceKm!.toStringAsFixed(1)} km away'
                      : 'Distance unavailable';
                  final expiryText = _formatIsoDate(
                    m.validUntil ?? m.expiryDate,
                  );
                  final nearExpiry = m.isNearExpiry;
                  final expired = m.isExpired;

                  final otherParty = m.myRole == 'donor'
                      ? 'Receiver: ${m.receiverUsername}'
                      : 'Donor: ${m.donorUsername}';

                  final stageLabel = m.stage.isEmpty ? m.status : m.stage;

                  final canAccept = _canAccept(m);
                  final canReject = _canReject(m);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: expired
                            ? AppTheme.statusError.withValues(alpha: 0.45)
                            : nearExpiry
                            ? AppTheme.statusWarning.withValues(alpha: 0.7)
                            : Colors.transparent,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${m.requestTitle.isNotEmpty ? m.requestTitle : 'Request'} • ${m.requestLocation}',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Donation: ${_titleCase(m.donationType)} • Qty: ${m.quantity}',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (expiryText != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Expiry date: $expiryText',
                              style: GoogleFonts.poppins(
                                color: expired
                                    ? AppTheme.statusError
                                    : nearExpiry
                                    ? AppTheme.statusWarning
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: nearExpiry || expired
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            distanceText,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _StatusChip(
                                label: 'Stage: $stageLabel',
                                color: AppTheme.primaryTeal.withValues(
                                  alpha: 0.12,
                                ),
                                textColor: AppTheme.primaryTeal,
                              ),
                              _StatusChip(
                                label: 'Status: ${m.status}',
                                color: AppTheme.primaryTeal.withValues(
                                  alpha: 0.06,
                                ),
                                textColor: AppTheme.navy,
                              ),
                              if (nearExpiry)
                                _StatusChip(
                                  label: 'Near Expiry (<24h)',
                                  color: AppTheme.statusWarning.withValues(
                                    alpha: 0.15,
                                  ),
                                  textColor: AppTheme.statusWarning,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            otherParty,
                            style: GoogleFonts.poppins(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (m.myRole == 'donor')
                            Text(
                              'Your decision: ${m.donorDecision}',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          if (m.myRole == 'receiver')
                            Text(
                              'Your decision: ${m.receiverDecision}',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 14),
                          if (m.status == 'pending')
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: canAccept
                                        ? () => _respond(m, 'accepted')
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryTeal,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AppTheme
                                          .primaryTeal
                                          .withValues(alpha: 0.25),
                                    ),
                                    child: const Text('Accept Match'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: canReject
                                        ? () => _respond(m, 'rejected')
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.statusError,
                                      side: BorderSide(
                                        color: AppTheme.statusError.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Waiting for the other user to respond.',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
