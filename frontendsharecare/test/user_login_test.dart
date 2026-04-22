import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';

void main() {
  group('User login flow', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('returns token data for valid credentials', () async {
      // Mock a successful login API response.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/login/',
        statusCode: 200,
        jsonBody: <String, dynamic>{
          'access': 'access-token',
          'refresh': 'refresh-token',
          'user': <String, dynamic>{'id': 7, 'username': 'alice'},
        },
      );

      final result = await service.login('alice', 'correct-password');

      expect(result['access'], 'access-token');
      expect(result['refresh'], 'refresh-token');
      expect((result['user'] as Map<String, dynamic>)['username'], 'alice');
    });

    test('throws ShareCareApiException for invalid credentials', () async {
      // Mock backend authentication failure.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/login/',
        statusCode: 401,
        jsonBody: <String, dynamic>{'detail': 'Invalid credentials'},
      );

      expect(
        () => service.login('alice', 'wrong-password'),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('sends expected login request payload', () async {
      // Mock success so we can inspect sent payload.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/login/',
        statusCode: 200,
        jsonBody: <String, dynamic>{'access': 'token'},
      );

      await service.login('payloadUser', 'payloadPass');

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/login/',
      );
      final body = requestBodyAsMap(request);

      expect(request.path, '${ApiConstants.authPrefix}/login/');
      expect(body['username'], 'payloadUser');
      expect(body['password'], 'payloadPass');
    });
  });
}
