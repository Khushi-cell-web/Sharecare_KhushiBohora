import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Donation item creation', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('validates required donation item fields', () {
      // Local validation prevents malformed payloads.
      expect(
        validateDonationItemInput(
          category: '',
          donationType: 'material',
          quantity: 2,
        ),
        'Category is required.',
      );

      expect(
        validateDonationItemInput(
          category: 'clothes',
          donationType: '',
          quantity: 2,
        ),
        'Donation type is required.',
      );

      expect(
        validateDonationItemInput(
          category: 'clothes',
          donationType: 'material',
          quantity: 0,
        ),
        'Quantity must be greater than zero.',
      );
    });

    test(
      'creates donation item with correct payload and parses response',
      () async {
        // Mock successful donation creation.
        fakeApi.queueJsonResponse(
          method: 'POST',
          path: '${ApiConstants.donationsPrefix}/donations/',
          statusCode: 201,
          jsonBody: <String, dynamic>{
            'id': 301,
            'category': 'clothes',
            'donation_type': 'material',
            'quantity': 5,
          },
        );

        final result = await service.createDonationRecord(
          authHeaders,
          category: 'clothes',
          donationType: 'material',
          quantity: 5,
          description: 'Winter jackets and blankets',
        );

        final request = fakeApi.lastRequest(
          'POST',
          '${ApiConstants.donationsPrefix}/donations/',
        );
        final body = requestBodyAsMap(request);

        expect(result['id'], 301);
        expect(body['category'], 'clothes');
        expect(body['donation_type'], 'material');
        expect(body['quantity'], 5);
        expect(body['description'], 'Winter jackets and blankets');
      },
    );

    test('throws ShareCareApiException when creation fails', () async {
      // Mock backend validation failure.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.donationsPrefix}/donations/',
        statusCode: 400,
        jsonBody: <String, dynamic>{'detail': 'Invalid donation payload'},
      );

      expect(
        () => service.createDonationRecord(
          authHeaders,
          category: 'clothes',
          donationType: 'material',
          quantity: 5,
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
  });
}
