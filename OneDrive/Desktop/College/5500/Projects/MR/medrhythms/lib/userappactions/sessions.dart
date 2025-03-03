import 'package:health/health.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'dart:async';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:url_launcher/url_launcher.dart';

class Sessions {
  final CreateDataService csd = CreateDataService();
  bool _isTracking = false;
  List<HealthDataPoint> _liveData = [];
  final StreamController<Map<String, double>> _liveDataController =
      StreamController<Map<String, double>>.broadcast();
  UserSession us = UserSession();
  Stream<Map<String, double>> get liveDataStream => _liveDataController.stream;

  Future<void> startLiveWorkout(Health h, String userId) async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.TOTAL_CALORIES_BURNED
    ];

    // Request permissions
    bool permissionsGranted = us.hasPermissions;
    bool isHealthConnectAvailable = false;
    try {
      print(await HealthConnectFactory.isApiSupported());
      await HealthConnectFactory.installHealthConnect();
      isHealthConnectAvailable = await HealthConnectFactory.isAvailable();
    } catch (err) {
      launchUrl(
        Uri.parse("market://details?id=com.google.android.apps.healthdata"),
        mode: LaunchMode.externalApplication,
      );
    }
    if (isHealthConnectAvailable) {
      print("Yes");
    } else {}
    if (permissionsGranted) {
      // Check if Google Health Connect is available
      if (true) {
        print("Google Health Connect is not available on this device.");
        // bool k = await HealthConnectFactory.installHealthConnect();
        if (true) {
          return;
        } else {
          throw Exception("Google Health Connect installation failed.");
        }
      }

      bool authorized = await h.requestAuthorization(types);

      if (authorized) {
        _isTracking = true;
        _liveData.clear();
        print("Live workout tracking started.");

        while (_isTracking) {
          DateTime now = DateTime.now();
          List<HealthDataPoint> data = await h.getHealthDataFromTypes(
              startTime: now.subtract(Duration(seconds: 10)),
              endTime: now,
              types: types);

          _liveData.addAll(data);

          double totalSteps = 0;
          double totalCalories = 0;
          double totalDistance = 0;

          for (var dataPoint in _liveData) {
            if (dataPoint.type == HealthDataType.STEPS) {
              totalSteps += dataPoint.value as double;
            } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
              totalCalories += dataPoint.value as double;
            } else if (dataPoint.type ==
                HealthDataType.DISTANCE_WALKING_RUNNING) {
              totalDistance += dataPoint.value as double;
            }
          }

          _liveDataController.add({
            'steps': totalSteps,
            'calories': totalCalories,
            'distance': totalDistance,
          });

          await Future.delayed(
              Duration(seconds: 10)); // Collect data every 10 seconds
        }
      } else {
        print("Authorization not granted for live tracking.");
      }
    } else {
      print("Permissions not granted.");
    }
  }

  Future<void> stopLiveWorkout(String userId, Duration selectedDuration) async {
    _isTracking = false;
    print("Live workout tracking stopped.");

    double totalSteps = 0;
    double totalCalories = 0;
    double totalDistance = 0;

    for (var dataPoint in _liveData) {
      if (dataPoint.type == HealthDataType.STEPS) {
        totalSteps += dataPoint.value as double;
      } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
        totalCalories += dataPoint.value as double;
      } else if (dataPoint.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
        totalDistance += dataPoint.value as double;
      }
    }

    print('Total Steps: $totalSteps');
    print('Total Calories Burned: $totalCalories');
    print('Total Distance: $totalDistance');

    await csd.createSessionData(
      userId.toString(),
      DateTime.now().subtract(selectedDuration), // Example start time
      DateTime.now(), // End time
      totalSteps,
      totalDistance,
      totalCalories,
      (totalDistance / (10 * 60)), // Speed estimate
      "Phone",
    );

    _liveData.clear();
  }

  Future<void> collectDailyHealthData(Health h, Uuid userId) async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.TOTAL_CALORIES_BURNED
    ];

    bool authorized = await h.requestAuthorization(types);

    if (authorized) {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
          startTime: startOfDay, endTime: endOfDay, types: types);

      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0;

      for (var dataPoint in healthData) {
        if (dataPoint.type == HealthDataType.STEPS) {
          totalSteps += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += dataPoint.value as double;
        } else if (dataPoint.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
          totalDistance += dataPoint.value as double;
        }
      }

      print("📊 Daily Summary:");
      print("✅ Steps: $totalSteps");
      print("🔥 Calories: $totalCalories");
      print("📏 Distance: $totalDistance km");

      // Save daily summary data to the database
      await csd.createSessionData(
        userId.toString(),
        startOfDay,
        endOfDay,
        totalSteps,
        totalDistance,
        totalCalories,
        (totalDistance / (24 * 60 * 60)), // Average speed per second
        "Phone",
      );
    } else {
      print("Authorization not granted for daily tracking.");
    }
  }
}
