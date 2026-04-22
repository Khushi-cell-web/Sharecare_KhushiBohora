import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';

void main() {
  group('OTP verification flow', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('verifies a valid OTP successfully', () async {
      // Mock successful OTP verification.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/verify-otp/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'detail': 'OTP valid'},
      );

      await service.verifyOtp('21', 'otp.valid@sharecare.org', '123456');

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/verify-otp/',
      );
      final body = requestBodyAsMap(request);

      expect(body['user_id'], '21');
      expect(body['email'], 'otp.valid@sharecare.org');
      expect(body['otp'], '123456');
    });

    test('throws error for invalid OTP', () async {
      // Mock invalid OTP scenario.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/verify-otp/',
        statusCode: 400,
        jsonBody: <String, dynamic>{'detail': 'Invalid OTP'},
      );

      expect(
        () => service.verifyOtp('21', 'otp.valid@sharecare.org', '000000'),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('throws error for expired OTP', () async {
      // Mock expired OTP scenario from backend.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/verify-otp/',
        statusCode: 410,
        jsonBody: <String, dynamic>{'detail': 'OTP expired'},
      );

      expect(
        () => service.verifyOtp('21', 'otp.valid@sharecare.org', '999999'),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            410,
          ),
        ),
      );
    });
  });
}
