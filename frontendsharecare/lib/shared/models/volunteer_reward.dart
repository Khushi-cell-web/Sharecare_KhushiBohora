class VolunteerPointsSummary {
  VolunteerPointsSummary({required this.points, required this.rank});

  factory VolunteerPointsSummary.fromJson(Map<String, dynamic> json) {
    return VolunteerPointsSummary(
      points: (json['points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as String?) ?? 'Beginner',
    );
  }

  final int points;
  final String rank;
}

class VolunteerReward {
  VolunteerReward({
    required this.id,
    required this.name,
    required this.requiredPoints,
    this.isActive = true,
  });

  factory VolunteerReward.fromJson(Map<String, dynamic> json) {
    return VolunteerReward(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'Reward',
      requiredPoints: (json['required_points'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  final int id;
  final String name;
  final int requiredPoints;
  final bool isActive;
}

class RewardRedemption {
  RewardRedemption({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.rewardRequiredPoints,
    required this.pointsSpent,
    required this.dateRedeemed,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: (json['id'] as num).toInt(),
      rewardId: (json['reward'] as num?)?.toInt() ?? 0,
      rewardName: (json['reward_name'] as String?) ?? 'Reward',
      rewardRequiredPoints:
          (json['reward_required_points'] as num?)?.toInt() ??
          (json['points_spent'] as num?)?.toInt() ??
          0,
      pointsSpent: (json['points_spent'] as num?)?.toInt() ?? 0,
      dateRedeemed: (json['date_redeemed'] as String?) ?? '',
    );
  }

  final int id;
  final int rewardId;
  final String rewardName;
  final int rewardRequiredPoints;
  final int pointsSpent;
  final String dateRedeemed;
}

class RewardRedeemResult {
  RewardRedeemResult({
    required this.points,
    required this.rank,
    required this.message,
    this.redemption,
  });

  factory RewardRedeemResult.fromJson(Map<String, dynamic> json) {
    return RewardRedeemResult(
      points: (json['points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as String?) ?? 'Beginner',
      message: (json['detail'] as String?) ?? 'Redeemed successfully.',
      redemption: json['redemption'] == null
          ? null
          : RewardRedemption.fromJson(
              json['redemption'] as Map<String, dynamic>,
            ),
    );
  }

  final int points;
  final String rank;
  final String message;
  final RewardRedemption? redemption;
}
