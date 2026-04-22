import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Password reset confirmation', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;
    late PasswordResetConfirmationFlow confirmationFlow;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
      confirmationFlow = PasswordResetConfirmationFlow(service);
    });

    test('confirms reset with valid OTP code and updates password', () async {
      // Mock OTP verification and password reset success.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/verify-otp/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'detail': 'OTP verified'},
      );
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/reset-password/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'detail': 'Password reset successful'},
      );

      final now = DateTime(2026, 4, 19, 10, 00);
      await confirmationFlow.confirmReset(
        userId: '55',
        email: 'confirm@sharecare.org',
        otpCode: '123456',
        newPassword: 'NewStrongPass123!',
        newPasswordConfirm: 'NewStrongPass123!',
        otpIssuedAt: now.subtract(const Duration(minutes: 3)),
        now: now,
      );

      final verifyRequest = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/verify-otp/',
      );
      final resetRequest = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/reset-password/',
      );
      final verifyBody = requestBodyAsMap(verifyRequest);
      final resetBody = requestBodyAsMap(resetRequest);

      expect(verifyBody['otp'], '123456');
      expect(resetBody['user_id'], '55');
      expect(resetBody['new_password'], 'NewStrongPass123!');
      expect(resetBody['new_password_confirm'], 'NewStrongPass123!');
    });

    test('rejects invalid reset code format before API call', () async {
      // OTP code must be exactly 6 digits.
      expect(
        () => confirmationFlow.confirmReset(
          userId: '55',
          email: 'confirm@sharecare.org',
          otpCode: '12AB',
          newPassword: 'NewStrongPass123!',
          newPasswordConfirm: 'NewStrongPass123!',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(fakeApi.requests, isEmpty);
    });

    test('handles expired OTP code using TTL validation', () async {
      // Simulate code expiry before API call.
      final now = DateTime(2026, 4, 19, 10, 00);
      expect(
        () => confirmationFlow.confirmReset(
          userId: '55',
          email: 'confirm@sharecare.org',
          otpCode: '123456',
          newPassword: 'NewStrongPass123!',
          newPasswordConfirm: 'NewStrongPass123!',
          otpIssuedAt: now.subtract(const Duration(minutes: 20)),
          now: now,
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(fakeApi.requests, isEmpty);
    });
  });
}
