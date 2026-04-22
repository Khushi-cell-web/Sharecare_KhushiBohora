import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';

void main() {
  group('Volunteer task update', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('marks task as picked up', () async {
      // Mock successful status update to picked.
      fakeApi.queueJsonResponse(
        method: 'PATCH',
        path: '${ApiConstants.volunteersPrefix}/tasks/77/',
        statusCode: 200,
        jsonBody: <String, dynamic>{
          'id': 77,
          'donation_request': 30,
          'pickup_location': 'A',
          'delivery_location': 'B',
          'task_status': 'picked',
          'delivery_points': 10,
        },
      );

      final updatedTask = await service.updateTask(
        authHeaders,
        77,
        taskStatus: 'picked',
      );

      final request = fakeApi.lastRequest(
        'PATCH',
        '${ApiConstants.volunteersPrefix}/tasks/77/',
      );
      final body = requestBodyAsMap(request);

      expect(updatedTask.taskStatus, 'picked');
      expect(body['task_status'], 'picked');
    });

    test('marks task as completed (delivered)', () async {
      // Mock successful status update to delivered.
      fakeApi.queueJsonResponse(
        method: 'PATCH',
        path: '${ApiConstants.volunteersPrefix}/tasks/77/',
        statusCode: 200,
        jsonBody: <String, dynamic>{
          'id': 77,
          'donation_request': 30,
          'pickup_location': 'A',
          'delivery_location': 'B',
          'task_status': 'delivered',
          'delivery_points': 20,
        },
      );

      final updatedTask = await service.updateTask(
        authHeaders,
        77,
        taskStatus: 'delivered',
      );

      final request = fakeApi.lastRequest(
        'PATCH',
        '${ApiConstants.volunteersPrefix}/tasks/77/',
      );
      final body = requestBodyAsMap(request);

      expect(updatedTask.taskStatus, 'delivered');
      expect(updatedTask.isDelivered, isTrue);
      expect(body['task_status'], 'delivered');
    });

    test('throws ShareCareApiException when task update fails', () async {
      // Mock backend failure for invalid transition.
      fakeApi.queueJsonResponse(
        method: 'PATCH',
        path: '${ApiConstants.volunteersPrefix}/tasks/77/',
        statusCode: 400,
        jsonBody: <String, dynamic>{'detail': 'Invalid task status transition'},
      );

      expect(
        () => service.updateTask(authHeaders, 77, taskStatus: 'picked'),
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
