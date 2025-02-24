import 'package:health/health.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';

class Workout {
  CreateDataService csd = CreateDataService();

  Future<void> recordWorkoutSession(
      Health h, DateTime startTime, int sessionTiming, String userId) async {
    // Calculate the end time based on the session timing
    DateTime endTime = startTime.add(Duration(minutes: sessionTiming));

    // Define the types of data you want to collect
    final types = [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.TOTAL_CALORIES_BURNED
    ];

    // Request authorization to access health data
    bool requestedHealthData = await h.requestAuthorization(types);

    if (requestedHealthData) {
      // Fetch the health data
      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
          startTime: startTime, endTime: endTime, types: types);

      // Process and store the data
      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0.0;

      for (var dataPoint in healthData) {
        if (dataPoint.type == HealthDataType.STEPS) {
          totalSteps += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
          totalDistance += dataPoint.value as double;
        }
      }

      print('Total steps: $totalSteps');
      print('Total calories: $totalCalories');
      print('Total distance: $totalDistance');

      // Save the data to the database
      await csd.createSessionData(
          userId.toString(),
          startTime,
          endTime,
          totalSteps,
          totalDistance,
          totalCalories,
          (totalDistance / (sessionTiming * 60)),
          "Phone");
    } else {
      print('Authorization not granted');
    }
  }
}
