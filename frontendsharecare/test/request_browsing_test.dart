import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';

void main() {
  group('Request browsing', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('parses donation request list and forwards query filters', () async {
      // Mock request list payload and validate query parameters are passed.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/requests/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'title': 'Need rice bags',
            'description': 'For relief distribution',
            'category': 'food',
            'quantity_needed': 20,
            'location': 'Kathmandu',
            'status': 'open',
            'urgency': 'High',
          },
          <String, dynamic>{
            'id': 2,
            'title': 'Need blankets',
            'description': 'Cold weather support',
            'category': 'clothes',
            'quantity_needed': 50,
            'location': 'Bhaktapur',
            'status': 'open',
            'urgency': 'Medium',
          },
        ],
      );

      final requests = await service.getRequests(
        status: 'open',
        category: 'food',
        urgency: 'High',
      );

      final captured = fakeApi.lastRequest(
        'GET',
        '${ApiConstants.donationsPrefix}/requests/',
      );

      expect(requests, hasLength(2));
      expect(requests.first.title, 'Need rice bags');
      expect(captured.queryParams?['status'], 'open');
      expect(captured.queryParams?['category'], 'food');
      expect(captured.queryParams?['urgency'], 'High');
    });

    test('handles empty request list response', () async {
      // Empty arrays should produce an empty parsed list.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/requests/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[],
      );

      final requests = await service.getRequests();

      expect(requests, isEmpty);
    });

    test('throws for malformed request payload data', () async {
      // Missing required fields should break parsing and surface error.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.donationsPrefix}/requests/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 99,
            'description': 'Missing title and other required keys',
          },
        ],
      );

      expect(
        () => service.getRequests(),
        throwsA(anyOf(isA<TypeError>(), isA<Error>(), isA<Exception>())),
      );
    });
  });
}
