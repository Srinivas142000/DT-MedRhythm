import 'package:health/health.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/userappactions/audios.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'dart:async';
import 'package:medrhythms/constants/constants.dart';
import 'package:geolocator/geolocator.dart';

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

  final LocalAudioManager audioManager = LocalAudioManager(threshold: 10.0);

  // Function to set the userId
  void setUserId(String userId) {
    _userId = userId;
  }

  void setSelectedDuration(Duration selectedDuration) {
    _totalSelectedDuration = selectedDuration;
  }

  Future<void> startLiveWorkout(
    Health h,
    String userId,
    Duration selectedDuration,
  ) async {
    // Request permissions
    setUserId(userId);
    bool permissionsGranted = us.hasPermissions;
    if (permissionsGranted) {
      // Check if Google Health Connect is available
      bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
      if (authorized && permissionsGranted) {
        _isTracking = true;
        _liveData.clear();
        double initialBpm = await _computeAverageBpm(h, DateTime.now().subtract(Duration(seconds: 10)), DateTime.now());
        await audioManager.playSongForBpm(initialBpm);
        // Initialize previous location
        Position? previousLocation;

        DateTime startTime = DateTime.now();
        while (_isTracking &&
            DateTime.now().difference(startTime) < selectedDuration) {
          DateTime now = DateTime.now();
          List<HealthDataPoint> data = await h.getHealthDataFromTypes(
            startTime: now.subtract(Duration(seconds: 10)),
            endTime: now,
            types: Constants.healthDataTypes,
          );
          _liveData.addAll(data);

          double currentBpm = _calculateAverageBpm(_liveData);

          await audioManager.playSongForBpm(currentBpm);

          // Get current location
          Position currentLocation = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Calculate distance if previous location exists
          double distance = 0;
          if (previousLocation != null) {
            distance = await calculateDistance(
              previousLocation,
              currentLocation,
            );
          }

          // Convert distance to steps (approx. 1 step = 0.762 meters)
          double stepsFromDistance = distance / 0.762;

          print("Steps: $stepsFromDistance");

          // Add steps from GPS to total steps
          double totalSteps = 0;
          for (var dataPoint in _liveData) {
            if (dataPoint.type == HealthDataType.STEPS) {
              totalSteps += dataPoint.value as double;
            }
          }
          totalSteps += stepsFromDistance;

          double totalCalories = 0;
          double totalHeartRate = 0;
          for (var dataPoint in _liveData) {
            if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
              totalCalories += dataPoint.value as double;
            } else if (dataPoint.type == HealthDataType.HEART_RATE) {
              totalHeartRate += dataPoint.value as double;
            }
          }

          _liveDataController.add({
            'steps': totalSteps,
            'calories': totalCalories,
            'distance': distance,
            'heartRate': totalHeartRate,
          });

          // Update previous location
          previousLocation = currentLocation;

          await Future.delayed(
            Duration(seconds: 2),
          ); // Collect data every 2 seconds
        }
        await stopLiveWorkout(h, userId, selectedDuration);
        await audioManager.stop();
      } else {
        print("Authorization not granted for live tracking.");
      }
    } else {
      print("Permissions not granted.");
    }
  }

  /// Computes the average BPM from a list of HealthDataPoints.
  double _calculateAverageBpm(List<HealthDataPoint> dataPoints) {
    double totalBpm = 0;
    int count = 0;
    for (var point in dataPoints) {
      if (point.type == HealthDataType.HEART_RATE) {
        double bpm = point.value is double ? point.value as double : (point.value as num).toDouble();
        totalBpm += bpm;
        count++;
      }
    }
    return count > 0 ? totalBpm / count : 100.0;
  }

  /// Compute BPM over a specific time window.
  Future<double> _computeAverageBpm(Health h, DateTime start, DateTime end) async {
    List<HealthDataPoint> data = await h.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.HEART_RATE],
    );
    return _calculateAverageBpm(data);
  }


  // Function to calculate distance between two locations
  Future<double> calculateDistance(Position start, Position end) async {
    double distanceInMeters = await Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return distanceInMeters;
  }

  Future<void> stopLiveWorkout(
    Health h,
    String userId,
    Duration selectedDuration,
  ) async {
    _isTracking = false;
    print("Live workout tracking stopped.");
    double totalSteps = 0;
    // Ensure the singleton instance of UserSession is used
    UserSession us = UserSession();
    double totalCalories = 0;
    double totalDistance = 0;
    double totalHeartRate = 0;
    DateTime now = DateTime.now();
    // await Future.delayed(Duration(minutes: 2));
    List<HealthDataPoint> data = await h.getHealthDataFromTypes(
      startTime: now.subtract(
        selectedDuration + Duration(seconds: 10) + Duration(minutes: 8),
      ),
      endTime: now,
      types: Constants.healthDataTypes,
    );
    _liveData.addAll(data);
    for (var dataPoint in _liveData) {
      if (dataPoint.type == HealthDataType.STEPS) {
        totalSteps += (dataPoint.value as NumericHealthValue).numericValue;
      } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
        totalCalories += (dataPoint.value as NumericHealthValue).numericValue;
      } else if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
        totalDistance += (dataPoint.value as NumericHealthValue).numericValue;
      } else if (dataPoint.type == HealthDataType.HEART_RATE) {
        totalHeartRate += (dataPoint.value as NumericHealthValue).numericValue;
      }
    }
    print('Total Steps: $totalSteps');
    print('Total Calories Burned: $totalCalories');
    print('Total Distance: $totalDistance');
    print('Total Heart Rate: $totalHeartRate');
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
    bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
    if (authorized) {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
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
      for (var dataPoint in _liveData) {
        if (dataPoint.type == HealthDataType.STEPS) {
          totalSteps += (dataPoint.value as NumericHealthValue).numericValue;
        } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += (dataPoint.value as NumericHealthValue).numericValue;
        } else if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
          totalDistance += (dataPoint.value as NumericHealthValue).numericValue;
        } else if (dataPoint.type == HealthDataType.HEART_RATE) {
          totalHeartRate +=
              (dataPoint.value as NumericHealthValue).numericValue;
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

  Future<void> syncSession(Duration selectedDuration) async {
    UserSession user = UserSession();
    final CreateDataService csd = CreateDataService();
    Health h = Health();
    DateTime now = DateTime.now();

    if (_totalSelectedDuration != null) {
      _totalSelectedDuration = _totalSelectedDuration! + selectedDuration;
    } else {
      _totalSelectedDuration = Duration(minutes: 1);
    }

    // Check if _totalSelectedDuration and userId are not null
    if (_totalSelectedDuration == null) {
      print("Error: _totalSelectedDuration is null.");
      return;
    }

    if (user.userId == null) {
      print("Error: userId is null.");
      return;
    }

    List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
      startTime: now.subtract(
        Duration(minutes: selectedDuration.inMinutes + 10),
      ),
      endTime: now,
      types: Constants.healthDataTypes,
    );
    double totalSteps = 0;
    double totalCalories = 0;
    double totalDistance = 0;
    double totalHeartRate = 0;

    if (healthData.isNotEmpty) {
      for (var dataPoint in healthData) {
        if (dataPoint.type == HealthDataType.STEPS) {
          totalSteps += (dataPoint.value as NumericHealthValue).numericValue;
        } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += (dataPoint.value as NumericHealthValue).numericValue;
        } else if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
          totalDistance += (dataPoint.value as NumericHealthValue).numericValue;
        } else if (dataPoint.type == HealthDataType.HEART_RATE) {
          totalHeartRate +=
              (dataPoint.value as NumericHealthValue).numericValue;
        }
      }

      double totalSpeed = (totalDistance) / (60000); // Estimate speed

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

      print("📊 Daily Summary:");
      print("✅ Steps: $totalSteps");
      print("🔥 Calories: $totalCalories Kcal");
      print("📏 Distance: $totalDistance meters");
      print("🚶‍♂️ Speed: $totalSpeed Kmph");
    }
  }

  Future<void> syncSessionInBackground(Duration selectedDuration) async {
    UserSession user = UserSession();
    final CreateDataService csd = CreateDataService();
    Health h = Health();
    DateTime now = DateTime.now();

    // Ensure _totalSelectedDuration is initialized
    if (_totalSelectedDuration != null) {
      _totalSelectedDuration = _totalSelectedDuration! + selectedDuration;
    } else {
      _totalSelectedDuration = Duration(minutes: 1);
    }

    // Check if _totalSelectedDuration and userId are not null
    if (_totalSelectedDuration == null) {
      print("Error: _totalSelectedDuration is null.");
      return;
    }

    if (user.userId == null) {
      print("Error: userId is null.");
      return;
    }

    // Periodic timer to sync data every 45 minutes
    Timer.periodic(Duration(minutes: 45), (timer) async {
      DateTime now = DateTime.now();

      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: now.subtract(
          Duration(minutes: selectedDuration.inMinutes + 10),
        ),
        endTime: now,
        types: Constants.healthDataTypes,
      );

      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0;
      double totalHeartRate = 0;

      if (healthData.isNotEmpty) {
        for (var dataPoint in healthData) {
          if (dataPoint.type == HealthDataType.STEPS) {
            totalSteps += (dataPoint.value as NumericHealthValue).numericValue;
          } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
            totalCalories +=
                (dataPoint.value as NumericHealthValue).numericValue;
          } else if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
            totalDistance +=
                (dataPoint.value as NumericHealthValue).numericValue;
          } else if (dataPoint.type == HealthDataType.HEART_RATE) {
            totalHeartRate +=
                (dataPoint.value as NumericHealthValue).numericValue;
          }
        }

        double totalSpeed = (totalDistance) / (60000); // Estimate speed

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

        print("📊 Automatic Sync Summary:");
        print("✅ Steps: $totalSteps");
        print("🔥 Calories: $totalCalories Kcal");
        print("📏 Distance: $totalDistance meters");
        print("🚶‍♂️ Speed: $totalSpeed Kmph");
      } else {
        print("No health data available for sync.");
      }
    });
  }
}
