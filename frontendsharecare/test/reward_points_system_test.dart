import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';
import 'package:frontendsharecare/shared/models/volunteer_task.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Reward points system', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;
    late RewardPointsCalculator calculator;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
      calculator = RewardPointsCalculator();
    });

    test('adds points after completing an urgent delivery task', () async {
      // Mock a delivered task that carries 20 points.
      fakeApi.queueJsonResponse(
        method: 'PATCH',
        path: '${ApiConstants.volunteersPrefix}/tasks/44/',
        statusCode: 200,
        jsonBody: <String, dynamic>{
          'id': 44,
          'donation_request': 10,
          'pickup_location': 'P1',
          'delivery_location': 'D1',
          'task_status': 'delivered',
          'is_urgent_delivery': true,
          'delivery_points': 20,
        },
      );

      final completedTask = await service.updateTask(
        authHeaders,
        44,
        taskStatus: 'delivered',
      );
      final newPoints = calculator.addPointsAfterCompletion(
        currentPoints: 50,
        task: completedTask,
      );

      expect(calculator.pointsForTaskCompletion(completedTask), 20);
      expect(newPoints, 70);
    });

    test('does not add points when task is not completed', () {
      // Non-delivered task should not increase points.
      final inProgressTask = VolunteerTask.fromJson(<String, dynamic>{
        'id': 45,
        'donation_request': 11,
        'pickup_location': 'P2',
        'delivery_location': 'D2',
        'task_status': 'picked',
        'delivery_points': 10,
      });

      final newPoints = calculator.addPointsAfterCompletion(
        currentPoints: 30,
        task: inProgressTask,
      );

      expect(calculator.pointsForTaskCompletion(inProgressTask), 0);
      expect(newPoints, 30);
    });

    test('applies standard point calculation for normal completed task', () {
      // Delivered non-urgent task should use standard 10 points.
      final normalCompletedTask = VolunteerTask.fromJson(<String, dynamic>{
        'id': 46,
        'donation_request': 12,
        'pickup_location': 'P3',
        'delivery_location': 'D3',
        'task_status': 'delivered',
        'is_urgent_delivery': false,
        'delivery_points': 10,
      });

      final earned = calculator.pointsForTaskCompletion(normalCompletedTask);

      expect(earned, 10);
    });
  });
}
