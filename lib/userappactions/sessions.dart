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


  Stream<Map<String, double>> get liveDataStream => _liveDataController.stream;

  String? _userId;
  Duration? _totalSelectedDuration;

  final LocalAudioManager _audioManager = LocalAudioManager(threshold: 10.0);
  LocalAudioManager get audioManager => _audioManager;

  // Set the user id.
  void setUserId(String userId) {
    _userId = userId;
  }

  // Set the session duration.
  void setSelectedDuration(Duration selectedDuration) {
    _totalSelectedDuration = selectedDuration;
  }

  Future<double> calculateDistance(Position start, Position end) async {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /**
   * Starts a live workout session:
   * - Requests health authorization if needed.
   * - Tracks steps and estimates BPM from GPS.
   * - Plays music matched to the current BPM.
   * - Streams live data updates.
   * @param {Health} h - Health API instance.
   * @param {string} userId - Unique user identifier.
   * @param {Duration} selectedDuration - Desired session duration.
   * @returns {Future<void>}
   */
  Future<void> startLiveWorkout(
    Health h,
    String userId,
    Duration selectedDuration,
  ) async {
    setUserId(userId);

    bool permissionsGranted = us.hasPermissions;
    if (!permissionsGranted) {
      print("Permissions not granted.");
      return;
    }

    bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
    if (!authorized) {
      print("Authorization not granted for live tracking.");
      return;
    }

    _isTracking = true;
    _liveData.clear();  

    Position? previousLocation;
    DateTime? previousTime;
    DateTime startTime = DateTime.now();
    DateTime lastSwitchTime = DateTime.now();
    const Duration switchCooldown = Duration(seconds: 10);

    while (_isTracking &&
        DateTime.now().difference(startTime) < selectedDuration) {
      DateTime currentTime = DateTime.now();

      // Fetch recent health data points
      List<HealthDataPoint> data = await h.getHealthDataFromTypes(
        startTime: currentTime.subtract(const Duration(seconds: 10)),
        endTime: currentTime,
        types: Constants.healthDataTypes,
      );
      _liveData.addAll(data);

      // Obtain current GPS location
      Position currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double locationBpm = 0.0;
        // If we have a previous location, estimate BPM from movement
        if (previousLocation != null && previousTime != null) {
          // Compute distance traveled since last sample
          double distance = await calculateDistance(
            previousLocation,
            currentLocation,
          );
          // Compute time difference in seconds
          double timeDiff =
              currentTime.difference(previousTime).inSeconds.toDouble();
          if (timeDiff > 0) {
            // Estimate number of steps and convert to steps per minute
            double estimatedSteps = distance / 0.762; 
            locationBpm = (estimatedSteps / timeDiff) * 60;
            print("Calculated Location BPM: $locationBpm");
          }
        }
        // Update previous location/time for next iteration
        previousLocation = currentLocation;
        previousTime = currentTime;

        double currentBpm = locationBpm;
        print("Using BPM (location-based only): $currentBpm");

        // If BPM is very low assume user isn't walking and skip song change
        if (currentBpm < 20.0) {
          print("Low movement detected (BPM: $currentBpm). Skipping song update.");
        } else {
          // Only switch songs if the cooldown has elapsed
          if (currentTime.difference(lastSwitchTime) > switchCooldown) {
            await _audioManager.playSongForBpm(currentBpm);
            lastSwitchTime = currentTime;
          }
        }

      // Sum total steps
      double totalSteps = 0;
      for (var dp in _liveData) {
        if (dp.type == HealthDataType.STEPS) {
          totalSteps += dp.value as double;
        }
      }

      // Emit live data
      _liveDataController.add({
        'steps': totalSteps,
        'bpm': currentBpm,
      });

      await Future.delayed(const Duration(seconds: 2));
    }

    await stopLiveWorkout(h, userId, selectedDuration);
  }

  /**
   * Stops a live workout session:
   * - Stops tracking and music.
   * - Aggregates collected health data.
   * - Persists session summary via CreateDataService.
   * @param {Health} h - Health API instance.
   * @param {string} userId - Unique user identifier.
   * @param {Duration} selectedDuration - Session duration.
   * @returns {Future<void>}
   */

  Future<void> stopLiveWorkout(Health h, String userId, Duration selectedDuration) async {
    _isTracking = false;
    print("Live workout tracking stopped.");

    await _audioManager.stop();

    double totalSteps = 0;
    double totalCalories = 0;
    double totalDistance = 0;
    double totalHeartRate = 0;
    DateTime now = DateTime.now();

    
    List<HealthDataPoint> data = await h.getHealthDataFromTypes(
      startTime: now.subtract(selectedDuration + const Duration(seconds: 10) + const Duration(minutes: 8)),
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

    await csd.createSessionData(
      userId,
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