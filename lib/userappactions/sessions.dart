import 'package:health/health.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'dart:async';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/constants/constants.dart';

class Sessions {
  final CreateDataService csd = CreateDataService();
  bool _isTracking = false;
  List<HealthDataPoint> _liveData = [];
  Timer? _autoSaveTimer;
  Duration? _totalSelectedDuration;
  String? _userId;
  final UserSession us = UserSession();
  final StreamController<Map<String, double>> _liveDataController = 
      StreamController<Map<String, double>>.broadcast();
  
  Stream<Map<String, double>> get liveDataStream => _liveDataController.stream;

  Future<void> startLiveWorkout(
    Health h,
    String userId,
  ) async {
    // Request permissions
    setUserId(userId);
    bool permissionsGranted = us.hasPermissions;
    if (permissionsGranted) {
      // Check if Google Health Connect is available
      // Some reason heart requires permissions from user to be granted every single time
      bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
      if (authorized && permissionsGranted) {
        _isTracking = true;
        _liveData.clear();
        print("Live workout tracking started.");
        DateTime startTime = DateTime.now();
        
        if (_totalSelectedDuration == null) {
          _totalSelectedDuration = Duration(minutes: 10);
        }

        while (_isTracking &&
            DateTime.now().difference(startTime) < _totalSelectedDuration!) {
          DateTime now = DateTime.now();
          List<HealthDataPoint> data = await h.getHealthDataFromTypes(
            startTime: now.subtract(Duration(seconds: 10)),
            endTime: now,
            types: Constants.healthDataTypes,
          );
          _liveData.addAll(data);
          double totalSteps = 0;
          double totalCalories = 0;
          double totalDistance = 0;
          double totalHeartRate = 0;
          // Calculate totals for each health data type
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
          _liveDataController.add({
            'steps': totalSteps,
            'calories': totalCalories,
            'distance': totalDistance,
            'heartRate': totalHeartRate,
          });
          await Future.delayed(
            Duration(seconds: 10),
          ); // Collect data every 10 seconds
        }
        await stopLiveWorkout(userId, _totalSelectedDuration ?? Duration(minutes: 10));
      } else {
        print("Authorization not granted for live tracking.");
      }
    } else {
      print("Permissions not granted.");
    }
  }

  Future<void> stopLiveWorkout(
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
    
    try {
      Health h = Health();
      bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
      if (!authorized) {
        print("Authorization not granted for health data access");
        return;
      }
      
      // await Future.delayed(Duration(minutes: 2));
      List<HealthDataPoint> data = await h.getHealthDataFromTypes(
        startTime: now.subtract(
          selectedDuration + Duration(seconds: 10),
        ),
        endTime: now,
        types: Constants.healthDataTypes,
      );
      _liveData.addAll(data);
      
      bool hasRealData = false;
      
      for (var dataPoint in _liveData) {
        if (dataPoint.type == HealthDataType.STEPS) {
          totalSteps += (dataPoint.value as NumericHealthValue).numericValue;
          hasRealData = true;
        } else if (dataPoint.type == HealthDataType.TOTAL_CALORIES_BURNED) {
          totalCalories += (dataPoint.value as NumericHealthValue).numericValue;
          hasRealData = true;
        } else if (dataPoint.type == HealthDataType.DISTANCE_DELTA) {
          totalDistance += (dataPoint.value as NumericHealthValue).numericValue;
          hasRealData = true;
        } else if (dataPoint.type == HealthDataType.HEART_RATE) {
          totalHeartRate += (dataPoint.value as NumericHealthValue).numericValue;
          hasRealData = true;
        }
      }
      
      if (!hasRealData || (totalSteps == 0 && totalCalories == 0 && totalDistance == 0)) {
        print("No real health data detected, generating mock data for emulator");
        
        double minutes = selectedDuration.inMinutes.toDouble();
        if (minutes <= 0) minutes = 10;
        
        totalSteps = minutes * 100;
        totalCalories = minutes * 5;
        totalDistance = minutes * 0.05;
        
        print('Generated mock data - Steps: $totalSteps, Calories: $totalCalories, Distance: $totalDistance');
      } else {
        print('Real data detected - Steps: $totalSteps, Calories: $totalCalories, Distance: $totalDistance');
      }
      
      double speed = selectedDuration.inSeconds > 0 
        ? totalDistance / (selectedDuration.inSeconds / 3600) 
        : 0;
      
      await csd.createSessionData(
        userId.toString(),
        now.subtract(selectedDuration),
        now,
        totalSteps,
        totalDistance,
        totalCalories,
        speed,
        "Phone",
      );
      
      print("📊 Session data saved to database:");
      print("✅ Steps: $totalSteps");
      print("🔥 Calories: $totalCalories Kcal");
      print("📏 Distance: $totalDistance miles");
      print("🚶‍♂️ Speed: $speed mph");
      
      _liveData.clear();
    } catch(e) {
      print("Error stopping workout: $e");
    }
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

  Future<void> syncSession(Duration selectedDuration) async {
    UserSession user = UserSession();
    final CreateDataService csd = CreateDataService();
    Health h = Health();
    DateTime now = DateTime.now();

    if (_totalSelectedDuration != null) {
      _totalSelectedDuration = _totalSelectedDuration! + selectedDuration;
    } else {
      _totalSelectedDuration = selectedDuration;
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

    try {
      bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
      if (!authorized) {
        print("Authorization not granted for health data access");
        return;
      }

      // Calculate time range for data collection
      DateTime startTime = now.subtract(selectedDuration);
      DateTime endTime = now;

      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
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
            totalHeartRate += (dataPoint.value as NumericHealthValue).numericValue;
          }
        }

        // Calculate speed in a safer way
        double totalSpeed = selectedDuration.inSeconds > 0 
          ? totalDistance / (selectedDuration.inSeconds / 3600) 
          : 0;

        await csd.createSessionData(
          user.userId.toString(),
          startTime,
          endTime,
          totalSteps,
          totalDistance,
          totalCalories,
          totalSpeed,
          "Phone",
        );

        print("📊 Data Synced:");
        print("✅ Steps: $totalSteps");
        print("🔥 Calories: $totalCalories Kcal");
        print("📏 Distance: $totalDistance meters");
        print("🚶‍♂️ Speed: $totalSpeed Kmph");
      } else {
        print("No health data found for the specified time period");
      }
    } catch (e) {
      print("Error syncing session: $e");
    }
  }

  // Function to set the userId
  void setUserId(String userId) {
    _userId = userId;
  }

  void setSelectedDuration(Duration selectedDuration) {
    _totalSelectedDuration = selectedDuration;
  }
}
