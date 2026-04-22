import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('User registration flow', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('validates required registration fields before submission', () {
      // Validate that all mandatory fields are present.
      final missing = missingRegistrationFields(
        username: '',
        email: '',
        password: '',
        passwordConfirm: '',
        role: '',
      );

      expect(
        missing,
        containsAll(<String>[
          'username',
          'email',
          'password',
          'passwordConfirm',
          'role',
        ]),
      );
    });

    test('throws duplicate email error from API', () async {
      // Mock duplicate email validation error from backend.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/register/',
        statusCode: 400,
        jsonBody: <String, dynamic>{
          'email': <String>['A user with that email already exists.'],
        },
      );

      expect(
        () => service.register(
          username: 'newuser',
          email: 'already@used.com',
          password: 'StrongPass123!',
          passwordConfirm: 'StrongPass123!',
          role: 'donor',
        ),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('registers successfully and sends expected payload', () async {
      // Mock successful registration response.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.authPrefix}/register/',
        statusCode: 201,
        jsonBody: <String, dynamic>{
          'id': 15,
          'username': 'freshuser',
          'email': 'fresh@sharecare.org',
          'role': 'donor',
        },
      );

      final result = await service.register(
        username: 'freshuser',
        email: 'fresh@sharecare.org',
        password: 'StrongPass123!',
        passwordConfirm: 'StrongPass123!',
        role: 'donor',
        firstName: 'Fresh',
        lastName: 'User',
        phone: '9800000000',
      );

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.authPrefix}/register/',
      );
      final body = requestBodyAsMap(request);

      expect(result['username'], 'freshuser');
      expect(body['username'], 'freshuser');
      expect(body['email'], 'fresh@sharecare.org');
      expect(body['password_confirm'], 'StrongPass123!');
      expect(body['role'], 'donor');
      expect(body['first_name'], 'Fresh');
      expect(body['last_name'], 'User');
      expect(body['phone'], '9800000000');
    });
  });
}
