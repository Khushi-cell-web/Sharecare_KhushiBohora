import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Your Impact calculation', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('counts completed and confirmed donations correctly', () async {
      // Mock history with completed, confirmed, and pending records.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/history/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 11,
            'amount': 100,
            'currency': 'NPR',
            'status': 'completed',
            'donation_type': 'one_time',
          },
          <String, dynamic>{
            'id': 12,
            'amount': 75,
            'currency': 'NPR',
            'status': 'confirmed',
            'donation_type': 'one_time',
          },
          <String, dynamic>{
            'id': 13,
            'amount': 20,
            'currency': 'NPR',
            'status': 'pending',
            'donation_type': 'monthly',
          },
        ],
      );

      final history = await service.getDonationHistory(authHeaders);
      final impactCount = countCompletedDonations(history);

      expect(impactCount, 2);
    });

    test('returns zero when there are no completed donations', () async {
      // Zero completed records should produce zero impact count.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/history/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 21,
            'amount': 50,
            'currency': 'USD',
            'status': 'pending',
            'donation_type': 'one_time',
          },
        ],
      );

      final history = await service.getDonationHistory(authHeaders);
      final impactCount = countCompletedDonations(history);

      expect(impactCount, 0);
    });

    test('returns zero for empty donation history', () async {
      // Empty history should still be handled safely.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/history/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[],
      );

      final history = await service.getDonationHistory(authHeaders);
      final impactCount = countCompletedDonations(history);

      expect(history, isEmpty);
      expect(impactCount, 0);
    });
  });
}
