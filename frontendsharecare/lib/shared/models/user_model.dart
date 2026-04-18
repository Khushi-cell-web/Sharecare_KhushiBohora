/// User model for ShareCare (from /auth/me). AbstractUser with role on model.
class UserModel {
  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.roleDisplay,
    this.phone,
    this.organization,
    this.profile,
    this.points = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      role: json['role'] as String?,
      roleDisplay: json['role_display'] as String?,
      phone: json['phone'] as String?,
      organization: json['organization'] as String?,
      points: json['points'] as int? ?? 0,
      profile: json['profile'] != null
          ? UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? roleDisplay;
  final String? phone;
  final String? organization;
  final int points;
  final UserProfileModel? profile;

  bool get isDonor => role == 'donor';
  bool get isNgo => role == 'ngo';
  bool get isVolunteer => role == 'volunteer';
  bool get isAdmin => role == 'admin';
}

/// User profile (verification status for organizations).
class UserProfileModel {
  UserProfileModel({
    required this.verificationStatus,
    this.verificationStatusDisplay,
    this.verificationId,
    this.verificationNotes,
    this.verifiedAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verificationStatusDisplay: json['verification_status_display'] as String?,
      verificationId: json['verification_id'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      verifiedAt: json['verified_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final String verificationStatus;
  final String? verificationStatusDisplay;
  final String? verificationId;
  final String? verificationNotes;
  final String? verifiedAt;
  final String? updatedAt;

  bool get isVerified => verificationStatus == 'verified';
}
