import 'package:health/health.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'dart:async';
import 'package:medrhythms/constants/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medrhythms/userappactions/audios.dart'; 

class Sessions {
  bool _isTracking = false;
  List<HealthDataPoint> _liveData = [];
  final StreamController<Map<String, double>> _liveDataController =
      StreamController<Map<String, double>>.broadcast();
  UserSession us = UserSession();
  final CreateDataService csd = CreateDataService();

  // Public stream for live updates
  Stream<Map<String, double>> get liveDataStream => _liveDataController.stream;

  String? _userId;
  Duration? _totalSelectedDuration;

  final LocalAudioManager _audioManager = LocalAudioManager(threshold: 10.0);

  // Set user Id
  void setUserId(String userId) {
    _userId = userId;
  }

  // Set session duration
  void setSelectedDuration(Duration selectedDuration) {
    _totalSelectedDuration = selectedDuration;
  }

  /// Returns the distance in meters between two GPS positions.
  Future<double> calculateDistance(Position start, Position end) async {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Starts live workout tracking.
  Future<void> startLiveWorkout(
      Health h, String userId, Duration selectedDuration) async {
    setUserId(userId);
    bool permissionsGranted = us.hasPermissions;
    if (permissionsGranted) {
      bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
      if (authorized && permissionsGranted) {
        _isTracking = true;
        _liveData.clear();

        Position? previousLocation;
        DateTime? previousTime;

        DateTime startTime = DateTime.now();

        while (_isTracking &&
            DateTime.now().difference(startTime) < selectedDuration) {
          DateTime currentTime = DateTime.now();

          // Retrieve recent health data (last 10 seconds)
          List<HealthDataPoint> data = await h.getHealthDataFromTypes(
            startTime: currentTime.subtract(const Duration(seconds: 10)),
            endTime: currentTime,
            types: Constants.healthDataTypes,
          );
          _liveData.addAll(data);

          // Get the current location.
          Position currentLocation = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Calculate location-based BPM.
          double locationBpm = 0.0;
          if (previousLocation != null && previousTime != null) {
            double distance = await calculateDistance(previousLocation, currentLocation);
            double timeDiff = currentTime.difference(previousTime!).inSeconds.toDouble();
            if (timeDiff > 0) {
              double estimatedSteps = distance / 0.762; 
              locationBpm = (estimatedSteps / timeDiff) * 60;
              print("Location BPM: $locationBpm");
            }
          }
          previousLocation = currentLocation;
          previousTime = currentTime;

          // Calculate heart rate-based BPM.
          double totalBpm = 0;
          int count = 0;
          for (var dp in data) {
            if (dp.type == HealthDataType.HEART_RATE) {
              double value = dp.value is double
                  ? dp.value as double
                  : (dp.value as num).toDouble();
              totalBpm += value;
              count++;
            }
          }
          double heartRateBpm = count > 0 ? totalBpm / count : 110.0;
          print("Heart Rate BPM: $heartRateBpm");
          // Use location BPM if it is non-zero; otherwise fallback to heart rate BPM.
          double currentBpm = (locationBpm > 0) ? locationBpm : heartRateBpm;
          print("Using BPM: $currentBpm");

          await _audioManager.playSongForBpm(currentBpm);

          double totalSteps = 0;
          for (var dp in _liveData) {
            if (dp.type == HealthDataType.STEPS) {
              totalSteps += dp.value as double;
            }
          }
          _liveDataController.add({
            'steps': totalSteps,
            'bpm': currentBpm,
          });

          await Future.delayed(const Duration(seconds: 2));
        }
        // End the session.
        await stopLiveWorkout(h, userId, selectedDuration);
      } else {
        print("Authorization not granted for live tracking.");
      }
    } else {
      print("Permissions not granted.");
    }
  }
  Future<void> stopLiveWorkout(Health h, String userId, Duration selectedDuration) async {
    _isTracking = false;
    print("Live workout tracking stopped.");
    
    // Stop audio playback when the session ends.
    await _audioManager.stop();

    double totalSteps = 0;
    double totalCalories = 0;
    double totalDistance = 0;
    double totalHeartRate = 0;
    DateTime now = DateTime.now();

    List<HealthDataPoint> data = await h.getHealthDataFromTypes(
      startTime: now.subtract(
        selectedDuration + const Duration(seconds: 10) + const Duration(minutes: 8),
      ),
      endTime: now,
      types: Constants.healthDataTypes,
    );
    _liveData.addAll(data);
    for (var dp in _liveData) {
      if (dp.type == HealthDataType.STEPS) {
        totalSteps += (dp.value as NumericHealthValue).numericValue;
      } else if (dp.type == HealthDataType.TOTAL_CALORIES_BURNED) {
        totalCalories += (dp.value as NumericHealthValue).numericValue;
      } else if (dp.type == HealthDataType.DISTANCE_DELTA) {
        totalDistance += (dp.value as NumericHealthValue).numericValue;
      } else if (dp.type == HealthDataType.HEART_RATE) {
        totalHeartRate += (dp.value as NumericHealthValue).numericValue;
      }
    }
    print('Total Steps: $totalSteps');
    print('Total Calories Burned: $totalCalories');
    print('Total Distance: $totalDistance');
    print('Total Heart Rate: $totalHeartRate');

    // Save the session data.
    await csd.createSessionData(
      userId.toString(),
      now.subtract(selectedDuration),
      now,
      totalSteps,
      totalDistance,
      totalCalories,
      totalDistance / (10 * 60), 
      "Phone",
    );
    _liveData.clear();
  }
  Future<void> collectDailyHealthData(Health h, Uuid userId) async {
    bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
    if (authorized) {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: Constants.healthDataTypes,
      );
      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0;
      double totalHeartRate = 0;
      for (var dp in _liveData) {
        if (dp.type == HealthDataType.STEPS) {
          totalSteps += (dp.value as NumericHealthValue).numericValue;
        } else if (dp.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += (dp.value as NumericHealthValue).numericValue;
        } else if (dp.type == HealthDataType.DISTANCE_DELTA) {
          totalDistance += (dp.value as NumericHealthValue).numericValue;
        } else if (dp.type == HealthDataType.HEART_RATE) {
          totalHeartRate += (dp.value as NumericHealthValue).numericValue;
        }
      }
      print("Daily Summary:");
      print("Steps: $totalSteps, Calories: $totalCalories, Distance: $totalDistance km");
      await csd.createSessionData(
        userId.toString(),
        startOfDay,
        endOfDay,
        totalSteps,
        totalDistance,
        totalCalories,
        totalDistance / (24 * 60 * 60),
        "Phone",
      );
    } else {
      print("Authorization not granted for daily tracking.");
    }
  }

  Future<void> syncSession(Duration selectedDuration) async {
    UserSession user = UserSession();
    final CreateDataService csd = CreateDataService();
    Health h = Health();
    DateTime now = DateTime.now();

    _totalSelectedDuration = _totalSelectedDuration != null
        ? _totalSelectedDuration! + selectedDuration
        : const Duration(minutes: 1);

    if (user.userId == null) {
      print("Error: userId is null.");
      return;
    }

    List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
      startTime: now.subtract(Duration(minutes: selectedDuration.inMinutes + 10)),
      endTime: now,
      types: Constants.healthDataTypes,
    );
    double totalSteps = 0, totalCalories = 0, totalDistance = 0, totalHeartRate = 0;
    if (healthData.isNotEmpty) {
      for (var dp in healthData) {
        if (dp.type == HealthDataType.STEPS) {
          totalSteps += (dp.value as NumericHealthValue).numericValue;
        } else if (dp.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += (dp.value as NumericHealthValue).numericValue;
        } else if (dp.type == HealthDataType.DISTANCE_DELTA) {
          totalDistance += (dp.value as NumericHealthValue).numericValue;
        } else if (dp.type == HealthDataType.HEART_RATE) {
          totalHeartRate += (dp.value as NumericHealthValue).numericValue;
        }
      }
      double totalSpeed = totalDistance / 60000;
      await csd.createSessionData(
        user.userId.toString(),
        now.subtract(_totalSelectedDuration! + selectedDuration),
        now.subtract(selectedDuration),
        totalSteps,
        totalDistance,
        totalCalories,
        totalSpeed,
        "Phone",
      );
      print("Sync Session Data:");
      print("Steps: $totalSteps, Calories: $totalCalories, Distance: $totalDistance, Speed: $totalSpeed");
    }
  }

  Future<void> syncSessionInBackground(Duration selectedDuration) async {
    UserSession user = UserSession();
    final CreateDataService csd = CreateDataService();
    Health h = Health();
    DateTime now = DateTime.now();

    _totalSelectedDuration = _totalSelectedDuration != null
        ? _totalSelectedDuration! + selectedDuration
        : const Duration(minutes: 1);

    if (user.userId == null) {
      print("Error: userId is null.");
      return;
    }

    Timer.periodic(const Duration(minutes: 45), (timer) async {
      DateTime now = DateTime.now();
      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: now.subtract(Duration(minutes: selectedDuration.inMinutes + 10)),
        endTime: now,
        types: Constants.healthDataTypes,
      );
      double totalSteps = 0, totalCalories = 0, totalDistance = 0, totalHeartRate = 0;
      if (healthData.isNotEmpty) {
        for (var dp in healthData) {
          if (dp.type == HealthDataType.STEPS) {
            totalSteps += (dp.value as NumericHealthValue).numericValue;
          } else if (dp.type == HealthDataType.TOTAL_CALORIES_BURNED) {
            totalCalories += (dp.value as NumericHealthValue).numericValue;
          } else if (dp.type == HealthDataType.DISTANCE_DELTA) {
            totalDistance += (dp.value as NumericHealthValue).numericValue;
          } else if (dp.type == HealthDataType.HEART_RATE) {
            totalHeartRate += (dp.value as NumericHealthValue).numericValue;
          }
        }
        double totalSpeed = totalDistance / 60000;
        await csd.createSessionData(
          user.userId.toString(),
          now.subtract(_totalSelectedDuration! + selectedDuration),
          now.subtract(selectedDuration),
          totalSteps,
          totalDistance,
          totalCalories,
          totalSpeed,
          "Phone",
        );
        print("Automatic Sync Session Data:");
        print("Steps: $totalSteps, Calories: $totalCalories, Distance: $totalDistance, Speed: $totalSpeed");
      } else {
        print("No health data available for sync.");
      }
    });
  }
}