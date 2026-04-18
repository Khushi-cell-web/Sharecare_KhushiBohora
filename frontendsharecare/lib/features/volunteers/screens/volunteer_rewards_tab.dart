import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/services/sharecare_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/models/volunteer_reward.dart';
import '../../../shared/providers/auth_provider.dart';

class VolunteerRewardsTab extends StatefulWidget {
  const VolunteerRewardsTab({super.key});

  @override
  State<VolunteerRewardsTab> createState() => _VolunteerRewardsTabState();
}

class _VolunteerRewardsTabState extends State<VolunteerRewardsTab> {
  final ShareCareApiService _api = ShareCareApiService();

  VolunteerPointsSummary _summary = VolunteerPointsSummary(
    points: 0,
    rank: 'Beginner',
  );
  List<VolunteerReward> _rewards = [];
  List<RewardRedemption> _history = [];
  bool _loading = true;
  int? _redeemingRewardId;
  String? _error;

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
      final results = await Future.wait([
        _api.getVolunteerPoints(auth.authHeaders),
        _api.getVolunteerRewards(auth.authHeaders),
        _api.getVolunteerRedemptions(auth.authHeaders),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as VolunteerPointsSummary;
          _rewards = results[1] as List<VolunteerReward>;
          _history = results[2] as List<RewardRedemption>;
          _loading = false;
        });
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

  Future<void> _redeem(VolunteerReward reward) async {
    if (_redeemingRewardId != null) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _redeemingRewardId = reward.id);

    try {
      final result = await _api.redeemVolunteerReward(
        auth.authHeaders,
        reward.id,
      );

      if (!mounted) return;
      setState(() {
        _summary = VolunteerPointsSummary(
          points: result.points,
          rank: result.rank,
        );
        if (result.redemption != null) {
          _history = [result.redemption!, ..._history];
        }
      });

      await auth.loadUser();
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
    } on ShareCareApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: AppTheme.statusError,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: AppTheme.statusError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _redeemingRewardId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Rewards',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    _error!,
                    style: GoogleFonts.poppins(color: AppTheme.statusError),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _pointsCard(context),
                  const SizedBox(height: 18),
                  Text(
                    'Available Rewards',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._rewards.map((r) => _rewardCard(context, r)),
                  const SizedBox(height: 18),
                  Text(
                    'Redemption History',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No rewards redeemed yet.',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._history.take(20).map((h) => _historyCard(h)),
                ],
              ),
      ),
    );
  }

  Widget _pointsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryTeal, AppTheme.primaryTealDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Points',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_summary.points}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rank: ${_summary.rank}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardCard(BuildContext context, VolunteerReward reward) {
    final canRedeem = _summary.points >= reward.requiredPoints;
    final remaining = reward.requiredPoints - _summary.points;
    final redeeming = _redeemingRewardId == reward.id;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reward.requiredPoints} points required',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (canRedeem && !redeeming)
                  ? () => _redeem(reward)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: canRedeem
                    ? AppTheme.primaryTeal
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(
                redeeming
                    ? '...'
                    : canRedeem
                    ? 'Redeem'
                    : 'Need $remaining',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(RewardRedemption redemption) {
    final when = redemption.dateRedeemed;
    final dateText = when.length >= 10 ? when.substring(0, 10) : when;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.verified_rounded,
          color: AppTheme.statusSuccess,
        ),
        title: Text(
          redemption.rewardName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$dateText • -${redemption.pointsSpent} pts',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ),
    );
  }
}
