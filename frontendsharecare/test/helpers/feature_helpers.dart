import 'dart:async';

import 'package:frontendsharecare/core/services/sharecare_api_service.dart';
import 'package:frontendsharecare/shared/models/donation_transaction.dart';
import 'package:frontendsharecare/shared/models/volunteer_task.dart';

List<String> missingRegistrationFields({
  required String username,
  required String email,
  required String password,
  required String passwordConfirm,
  required String role,
}) {
  final missing = <String>[];
  if (username.trim().isEmpty) missing.add('username');
  if (email.trim().isEmpty) missing.add('email');
  if (password.trim().isEmpty) missing.add('password');
  if (passwordConfirm.trim().isEmpty) missing.add('passwordConfirm');
  if (role.trim().isEmpty) missing.add('role');
  return missing;
}

bool isValidEmail(String email) {
  final value = email.trim();
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return regex.hasMatch(value);
}

String? validateDonationItemInput({
  required String category,
  required String donationType,
  required int quantity,
}) {
  if (category.trim().isEmpty) return 'Category is required.';
  if (donationType.trim().isEmpty) return 'Donation type is required.';
  if (quantity <= 0) return 'Quantity must be greater than zero.';
  return null;
}

String? validateFoodDonationExpiry({
  required DateTime? expiryDate,
  DateTime? now,
}) {
  if (expiryDate == null) {
    return 'Expiry date is required for food donations.';
  }

  final today = (now ?? DateTime.now());
  final dateOnlyNow = DateTime(today.year, today.month, today.day);
  final dateOnlyExpiry = DateTime(
    expiryDate.year,
    expiryDate.month,
    expiryDate.day,
  );

  if (dateOnlyExpiry.isBefore(dateOnlyNow)) {
    return 'Expiry date cannot be in the past.';
  }

  return null;
}

String? validateOfferInput({
  required int donationRequestId,
  required String type,
  required int quantity,
}) {
  if (donationRequestId <= 0) return 'Donation request id is required.';
  if (type.trim().isEmpty) return 'Offer type is required.';
  if (quantity <= 0) return 'Offer quantity must be greater than zero.';
  return null;
}

int countCompletedDonations(Iterable<DonationTransaction> history) {
  return history.where((txn) => txn.isCompleted).length;
}

class OtpSendFlow {
  OtpSendFlow(this._api);

  final ShareCareApiService _api;

  Future<void> sendOtp({required String userId, required String email}) async {
    if (!isValidEmail(email)) {
      throw const FormatException('Invalid email format.');
    }
    await _api.forgotPassword(userId, email);
  }
}

class PasswordResetRequestFlow {
  PasswordResetRequestFlow(this._api);

  final ShareCareApiService _api;

  Future<void> requestReset({required String userId, required String email}) {
    if (!isValidEmail(email)) {
      throw const FormatException('Invalid email format.');
    }
    return _api.forgotPassword(userId, email);
  }
}

class PasswordResetConfirmationFlow {
  PasswordResetConfirmationFlow(this._api);

  final ShareCareApiService _api;

  Future<void> confirmReset({
    required String userId,
    required String email,
    required String otpCode,
    required String newPassword,
    required String newPasswordConfirm,
    DateTime? otpIssuedAt,
    DateTime? now,
    Duration otpTtl = const Duration(minutes: 10),
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      throw const FormatException('OTP code must be 6 digits.');
    }

    if (otpIssuedAt != null) {
      final currentTime = now ?? DateTime.now();
      if (otpIssuedAt.add(otpTtl).isBefore(currentTime)) {
        throw TimeoutException('OTP code has expired.');
      }
    }

    await _api.verifyOtp(userId, email, otpCode);
    await _api.resetPassword(userId, newPassword, newPasswordConfirm);
  }
}

class RewardPointsCalculator {
  int pointsForTaskCompletion(VolunteerTask task) {
    if (task.taskStatus != 'delivered') return 0;
    return task.deliveryPoints;
  }

  int addPointsAfterCompletion({
    required int currentPoints,
    required VolunteerTask task,
  }) {
    return currentPoints + pointsForTaskCompletion(task);
  }
}
