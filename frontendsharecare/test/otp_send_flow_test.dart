import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('OTP send flow', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;
    late OtpSendFlow otpFlow;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
      otpFlow = OtpSendFlow(service);
    });

    test('sends expected email payload to OTP endpoint', () async {
      // Mock successful OTP dispatch.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/forgot-password/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'detail': 'OTP sent'},
      );

      await otpFlow.sendOtp(userId: '42', email: 'otp.user@sharecare.org');

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/forgot-password/',
      );
      final body = requestBodyAsMap(request);

      expect(body['user_id'], '42');
      expect(body['email'], 'otp.user@sharecare.org');
    });

    test('completes without error on API success', () async {
      // OTP send should complete when backend returns 200.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/forgot-password/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'detail': 'OTP sent'},
      );

      await otpFlow.sendOtp(userId: '12', email: 'valid@mail.com');

      expect(fakeApi.requests.length, 1);
    });

    test('throws ShareCareApiException when OTP API fails', () async {
      // Simulate backend failure while sending OTP.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/forgot-password/',
        statusCode: 500,
        jsonBody: <String, dynamic>{'detail': 'Temporary error'},
      );

      expect(
        () => otpFlow.sendOtp(userId: '12', email: 'valid@mail.com'),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });
  });
}
