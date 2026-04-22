import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Password reset request', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;
    late PasswordResetRequestFlow resetFlow;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
      resetFlow = PasswordResetRequestFlow(service);
    });

    test('submits reset request email payload correctly', () async {
      // Mock successful password reset request.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/forgot-password/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'detail': 'Reset OTP sent'},
      );

      await resetFlow.requestReset(
        userId: '88',
        email: 'reset.me@sharecare.org',
      );

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/forgot-password/',
      );
      final body = requestBodyAsMap(request);

      expect(body['user_id'], '88');
      expect(body['email'], 'reset.me@sharecare.org');
    });

    test('rejects invalid email before calling API', () async {
      // Validation should fail locally for malformed emails.
      expect(
        () => resetFlow.requestReset(userId: '88', email: 'not-an-email'),
        throwsA(isA<FormatException>()),
      );
      expect(fakeApi.requests, isEmpty);
    });

    test('propagates backend errors for reset request', () async {
      // Mock backend failure for unknown account/email.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/forgot-password/',
        statusCode: 404,
        jsonBody: <String, dynamic>{'detail': 'User not found'},
      );

      expect(
        () => resetFlow.requestReset(
          userId: '88',
          email: 'reset.me@sharecare.org',
        ),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });
}
