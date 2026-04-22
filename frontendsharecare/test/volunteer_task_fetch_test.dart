import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';

void main() {
  group('Volunteer task fetch', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('parses available volunteer tasks', () async {
      // Mock a pending volunteer task list.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.volunteersPrefix}/pending-tasks/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 501,
            'donation_request': 90,
            'pickup_location': 'Donor Home',
            'delivery_location': 'NGO Warehouse',
            'task_status': 'assigned',
            'delivery_points': 10,
          },
        ],
      );

      final tasks = await service.getPendingVolunteerTasks(authHeaders);

      expect(tasks, hasLength(1));
      expect(tasks.first.id, 501);
      expect(tasks.first.pickupLocation, 'Donor Home');
      expect(tasks.first.deliveryLocation, 'NGO Warehouse');
      expect(tasks.first.taskStatus, 'assigned');
    });

    test('handles empty available task list', () async {
      // Empty task list should parse safely.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.volunteersPrefix}/pending-tasks/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[],
      );

      final tasks = await service.getPendingVolunteerTasks(authHeaders);

      expect(tasks, isEmpty);
    });

    test('throws when available task payload is malformed', () async {
      // Missing required task fields should fail parsing.
      fakeApi.queueJsonResponse(
        method: 'GET',
        path: '${ApiConstants.volunteersPrefix}/pending-tasks/',
        statusCode: 200,
        jsonBody: <Map<String, dynamic>>[
          <String, dynamic>{'pickup_location': 'Unknown'},
        ],
      );

      expect(
        () => service.getPendingVolunteerTasks(authHeaders),
        throwsA(anyOf(isA<TypeError>(), isA<Error>(), isA<Exception>())),
      );
    });
  });
}
