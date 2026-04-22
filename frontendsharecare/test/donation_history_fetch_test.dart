import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';

void main() {
  group('Donation history fetch', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('parses donation history list correctly', () async {
      // Mock donation transaction history with mixed statuses.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/history/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'amount': '250.5',
            'currency': 'NPR',
            'status': 'completed',
            'donation_type': 'one_time',
          },
          <String, dynamic>{
            'id': 2,
            'amount': 100,
            'currency': 'USD',
            'status': 'pending',
            'donation_type': 'monthly',
          },
        ],
      );

      final history = await service.getDonationHistory(authHeaders);

      expect(history, hasLength(2));
      expect(history.first.amount, 250.5);
      expect(history.first.isCompleted, isTrue);
      expect(history.last.isPending, isTrue);
    });

    test('handles empty donation history response', () async {
      // Empty arrays should parse to an empty list.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/history/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[],
      );

      final history = await service.getDonationHistory(authHeaders);

      expect(history, isEmpty);
    });

    test('throws when history payload is malformed', () async {
      // Missing required fields in list items should fail parsing.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/history/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{'amount': 50, 'status': 'completed'},
        ],
      );

      expect(
        () => service.getDonationHistory(authHeaders),
        throwsA(anyOf(isA<TypeError>(), isA<Error>(), isA<Exception>())),
      );
    });
  });
}
