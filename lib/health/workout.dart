import 'package:health/health.dart';
import 'package:medrhythms/constants/constants.dart';
import 'package:medrhythms/helpers/datasyncmanager.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/**
 * A class to handle workout session data recording and synchronization.
 */
class Workout {
  CreateDataService csd = CreateDataService();
  DataSyncManager dsm = DataSyncManager();

  /**
   * Records the workout session data, including steps, distance, calories, and heart rate.
   * It checks the device's capabilities for tracking health data, requests authorization, 
   * and then processes and stores the workout data.
   * 
   * @param h [Health] The Health instance used to interact with the health data API.
   * @param startTime [DateTime] The start time of the workout session.
   * @param sessionTiming [int] The duration of the session in minutes.
   * @param userId [String] The user identifier for the session.
   */
  Future<void> recordWorkoutSession(
    Health h,
    DateTime startTime,
    int sessionTiming,
    String userId,
  ) async {
    // Calculate the end time based on the session timing
    DateTime endTime = startTime.add(Duration(minutes: sessionTiming));

    // Define the types of data you want to collect
    // Check if the data types are supported by the device
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

    // If any of the required data types are not supported, return early
    if (!stepsSupported ||
        !distanceSupported ||
        !caloriesSupported ||
        !heartSupported) {
      print('One or more data types are not supported on this device.');
      return;
    }

    // Request authorization to access the health data
    bool requestedHealthData = await h.requestAuthorization(
      Constants.healthDataTypes,
    );

    // If authorization is granted, proceed to fetch the health data
    if (requestedHealthData) {
      // Fetch the health data for the specified time range
      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: Constants.healthDataTypes,
      );

      // Variables to accumulate the data
      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0.0;
      double totalHeartRate = 0.0;

      // Process the fetched health data
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

      // Log the collected data
      print('Total steps: $totalSteps');
      print('Total calories: $totalCalories');
      print('Total distance: $totalDistance');
      print('Total Heartrate: $totalHeartRate');

      // Check the network connectivity status
      final isConnected =
          await Connectivity().checkConnectivity() != ConnectivityResult.none;

      // Calculate the total speed (distance per minute)
      double totalSpeed = (totalDistance) / (60000);

      // If the device is online, save the data to the database
      if (isConnected) {
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
        // If the device is offline, store the data for later synchronization
        await dsm.store(
          userId: userId,
          startTime: startTime,
          endTime: endTime,
          steps: totalSteps,
          distance: totalDistance,
          calories: totalCalories,
          speed: totalSpeed,
          source: "Phone - Offline",
        );
      }
    } else {
      // If the authorization was not granted, print a message
      print('Authorization not granted');
    }
  }
}
