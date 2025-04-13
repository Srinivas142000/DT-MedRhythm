import 'package:health/health.dart';
import 'package:medrhythms/constants/constants.dart';
import 'package:medrhythms/helpers/datasyncmanager.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Workout {
  CreateDataService csd = CreateDataService();
  DataSyncManager dsm = DataSyncManager();

  Future<void> recordWorkoutSession(
    Health h,
    DateTime startTime,
    int sessionTiming,
    String userId,
  ) async {
    // Calculate the end time based on the session timing
    DateTime endTime = startTime.add(Duration(minutes: sessionTiming));

    // Define the types of data you want to collect

    // Check if the data types are supported
    bool stepsSupported = await h.isDataTypeAvailable(HealthDataType.STEPS);
    bool distanceSupported = await h.isDataTypeAvailable(
      HealthDataType.DISTANCE_DELTA,
    );
    bool caloriesSupported = await h.isDataTypeAvailable(
      HealthDataType.TOTAL_CALORIES_BURNED,
    );
    bool heartSupported = await h.isDataTypeAvailable(
      HealthDataType.HEART_RATE,
    );

    if (!stepsSupported ||
        !distanceSupported ||
        !caloriesSupported ||
        !heartSupported) {
      print('One or more data types are not supported on this device.');
      return;
    }

    // Request authorization to access health data
    bool requestedHealthData = await h.requestAuthorization(
      Constants.healthDataTypes,
    );

    if (requestedHealthData) {
      // Fetch the health data
      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: Constants.healthDataTypes,
      );

      // Process and store the data
      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0.0;
      double totalHeartRate = 0.0;

      for (var dataPoint in healthData) {
        if (dataPoint.type == HealthDataType.STEPS) {
          totalSteps += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
          totalDistance += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.HEART_RATE) {
          totalHeartRate += dataPoint.value as double;
        }
      }

      print('Total steps: $totalSteps');
      print('Total calories: $totalCalories');
      print('Total distance: $totalDistance');
      print('Total Heartrate: $totalHeartRate');

      final isConnected =
          await Connectivity().checkConnectivity() != ConnectivityResult.none;

      double totalSpeed = (totalDistance) / (60000);

      if (isConnected) {
        // Save the data to the database
        await csd.createSessionData(
          userId.toString(),
          startTime,
          endTime,
          totalSteps,
          totalDistance,
          totalCalories,
          (totalDistance / (sessionTiming * 60)),
          "Phone",
        );
      } else {
        await dsm.store(
          userId: userId,
          startTime: startTime,
          endTime: endTime,
          steps: totalSteps,
          distance: totalDistance,
          calories: totalCalories,
          speed: speed,
          source: "Phone - Offline",
        );
      }
    } else {
      print('Authorization not granted');
    }
  }
}
