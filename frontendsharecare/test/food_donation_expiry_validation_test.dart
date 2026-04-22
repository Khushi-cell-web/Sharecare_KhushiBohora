import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Food donation expiry validation', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('requires expiry date for food donations', () {
      // Food donations must always include an expiry date.
      final message = validateFoodDonationExpiry(expiryDate: null);
      expect(message, 'Expiry date is required for food donations.');
    });

    test('rejects past expiry date', () {
      // Past dates should not be accepted.
      final message = validateFoodDonationExpiry(
        expiryDate: DateTime(2026, 4, 10),
        now: DateTime(2026, 4, 19),
      );
      expect(message, 'Expiry date cannot be in the past.');
    });

    test('accepts future expiry date and sends expiry in payload', () async {
      // Future dates are valid and should be serialized to API payload.
      final expiry = DateTime(2026, 4, 25, 18, 00);

      expect(
        validateFoodDonationExpiry(
          expiryDate: expiry,
          now: DateTime(2026, 4, 19),
        ),
        isNull,
      );

      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.donationsPrefix}/donations/',
        statusCode: 201,
        jsonBody: <String, dynamic>{
          'id': 900,
          'category': 'food',
          'quantity': 3,
        },
      );

      await service.createDonationRecord(
        authHeaders,
        category: 'food',
        donationType: 'material',
        quantity: 3,
        expiryDate: expiry,
      );

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.donationsPrefix}/donations/',
      );
      final body = requestBodyAsMap(request);

      expect(body.containsKey('expiry_date'), isTrue);
      expect(body['expiry_date'], contains('2026-04-25'));
    });
  });
}
