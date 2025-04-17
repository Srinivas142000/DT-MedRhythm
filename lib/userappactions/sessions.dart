import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';
import 'package:medrhythms/constants/constants.dart';
import 'package:medrhythms/helpers/datasyncmanager.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:medrhythms/userappactions/audios.dart';
import 'package:uuid/uuid.dart';

class Sessions {
  bool isTracking = false;
  List<HealthDataPoint> liveData = [];
  final StreamController<Map<String, double>> liveDataController =
      StreamController<Map<String, double>>.broadcast();

  final UserSession us;
  final CreateDataService csd;
  final LocalAudioManager _audioManager;
  final DataSyncManager dsm;

  Sessions({
    required this.us,
    required this.csd,
    required LocalAudioManager audioManager,
    required this.dsm,
  }) : _audioManager = audioManager;

  Stream<Map<String, double>> get liveDataStream => liveDataController.stream;

  String? userId;
  Duration? totalSelectedDuration;
  Timer? _autoSaveTimer;

  void setUserId(String userId) => this.userId = userId;

  void setSelectedDuration(Duration selectedDuration) =>
      totalSelectedDuration = selectedDuration;

  Future<double> calculateDistance(Position start, Position end) async =>
      Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

  Future<void> startLiveWorkout(
    Health h,
    String userId,
    Duration selectedDuration,
  ) async {
    setUserId(userId);
    setSelectedDuration(selectedDuration);

    if (!us.hasPermissions) {
      print("Permissions not granted.");
      return;
    }

    bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
    if (!authorized) {
      print("Authorization not granted for live tracking.");
      return;
    }

    isTracking = true;
    liveData.clear();
    print("Live workout tracking started.");

    Position? previousLocation;
    DateTime? previousTime;
    DateTime startTime = DateTime.now();

    while (isTracking &&
        DateTime.now().difference(startTime) < selectedDuration) {
      DateTime currentTime = DateTime.now();
      List<HealthDataPoint> data = await h.getHealthDataFromTypes(
        startTime: currentTime.subtract(const Duration(seconds: 10)),
        endTime: currentTime,
        types: Constants.healthDataTypes,
      );
      liveData.addAll(data);

      Position currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double locationBpm = 0.0;
      if (previousLocation != null && previousTime != null) {
        double distance = await calculateDistance(
          previousLocation,
          currentLocation,
        );
        double timeDiff =
            currentTime.difference(previousTime).inSeconds.toDouble();
        if (timeDiff > 0) {
          double estimatedSteps = distance / 0.762;
          locationBpm = (estimatedSteps / timeDiff) * 60;
          print("Location BPM: \$locationBpm");
        }
      }
      previousLocation = currentLocation;
      previousTime = currentTime;

      double totalBpm = 0;
      int count = 0;
      for (var dp in data) {
        if (dp.type == HealthDataType.HEART_RATE) {
          totalBpm += (dp.value as num).toDouble();
          count++;
        }
      }
      double heartRateBpm = count > 0 ? totalBpm / count : 110.0;
      print("Heart Rate BPM: \$heartRateBpm");

      double currentBpm = (locationBpm > 0) ? locationBpm : heartRateBpm;
      print("Using BPM: \$currentBpm");

      await _audioManager.playSongForBpm(currentBpm);

      double totalSteps = 0;
      for (var dp in liveData) {
        if (dp.type == HealthDataType.STEPS) {
          totalSteps += (dp.value as num).toDouble();
        }
      }

      liveDataController.add({'steps': totalSteps, 'bpm': currentBpm});

      await Future.delayed(const Duration(seconds: 2));
    }

    await stopLiveWorkout(h, userId, selectedDuration);
  }

  Future<void> stopLiveWorkout(
    Health h,
    String userId,
    Duration selectedDuration,
  ) async {
    try {
      isTracking = false;
      print("Live workout tracking stopped.");

      await _audioManager.stop();

      DateTime now = DateTime.now();
      List<HealthDataPoint> data = await h.getHealthDataFromTypes(
        startTime: now.subtract(selectedDuration + const Duration(minutes: 8)),
        endTime: now,
        types: Constants.healthDataTypes,
      );
      liveData.addAll(data);

      double totalSteps = 0, totalCalories = 0, totalDistance = 0;
      for (var dp in liveData) {
        if (dp.value is! NumericHealthValue) continue;
        final value = (dp.value as NumericHealthValue).numericValue;
        switch (dp.type) {
          case HealthDataType.STEPS:
            totalSteps += value;
            break;
          case HealthDataType.TOTAL_CALORIES_BURNED:
            totalCalories += value;
            break;
          case HealthDataType.DISTANCE_DELTA:
            totalDistance += value;
            break;
          default:
            break;
        }
      }

      if (totalSteps == 0 && totalCalories == 0 && totalDistance == 0) {
        double minutes = selectedDuration.inMinutes.toDouble();
        totalSteps = minutes * 100;
        totalCalories = minutes * 5;
        totalDistance = minutes * 0.05;
        print("Generated mock data.");
      }

      double speed = totalDistance / (selectedDuration.inSeconds / 3600);

      await csd.createSessionData(
        userId,
        now.subtract(selectedDuration),
        now,
        totalSteps,
        totalDistance,
        totalCalories,
        speed,
        "Phone",
      );
      liveData.clear();
    } catch (e) {
      print("Error stopping workout: \$e");
    }
  }

  Future<void> collectDailyHealthData(Health h, Uuid userId) async {
    bool authorized = await h.requestAuthorization(Constants.healthDataTypes);
    if (!authorized) {
      print("Authorization not granted for daily tracking.");
      return;
    }

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
      startTime: startOfDay,
      endTime: endOfDay,
      types: Constants.healthDataTypes,
    );

    double totalSteps = 0,
        totalCalories = 0,
        totalDistance = 0,
        totalHeartRate = 0;
    for (var dp in healthData) {
      if (dp.value is! NumericHealthValue) continue;
      final value = (dp.value as NumericHealthValue).numericValue;
      switch (dp.type) {
        case HealthDataType.STEPS:
          totalSteps += value;
          break;
        case HealthDataType.TOTAL_CALORIES_BURNED:
          totalCalories += value;
          break;
        case HealthDataType.DISTANCE_DELTA:
          totalDistance += value;
          break;
        case HealthDataType.HEART_RATE:
          totalHeartRate += value;
          break;
        default:
          break;
      }
    }

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
  }

  Future<void> syncSession(Duration selectedDuration) async {
    Health h = Health();
    DateTime now = DateTime.now();

    totalSelectedDuration =
        totalSelectedDuration != null
            ? totalSelectedDuration! + selectedDuration
            : const Duration(minutes: 1);

    if (us.userId == null) {
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

    double totalSteps = 0, totalCalories = 0, totalDistance = 0;
    for (var dp in healthData) {
      if (dp.value is! NumericHealthValue) continue;
      final value = (dp.value as NumericHealthValue).numericValue;
      switch (dp.type) {
        case HealthDataType.STEPS:
          totalSteps += value;
          break;
        case HealthDataType.TOTAL_CALORIES_BURNED:
          totalCalories += value;
          break;
        case HealthDataType.DISTANCE_DELTA:
          totalDistance += value;
          break;
        default:
          break;
      }
    }
    double totalSpeed = totalDistance / 60000;

    await csd.createSessionData(
      us.userId.toString(),
      now.subtract(totalSelectedDuration! + selectedDuration),
      now.subtract(selectedDuration),
      totalSteps,
      totalDistance,
      totalCalories,
      totalSpeed,
      "Phone",
    );
  }

  Future<void> syncSessionInBackground(Duration selectedDuration) async {
    Health h = Health();

    totalSelectedDuration =
        totalSelectedDuration != null
            ? totalSelectedDuration! + selectedDuration
            : const Duration(minutes: 1);

    if (us.userId == null) {
      print("Error: userId is null.");
      return;
    }

    Timer.periodic(const Duration(minutes: 45), (timer) async {
      DateTime now = DateTime.now();
      List<HealthDataPoint> healthData = await h.getHealthDataFromTypes(
        startTime: now.subtract(
          Duration(minutes: selectedDuration.inMinutes + 10),
        ),
        endTime: now,
        types: Constants.healthDataTypes,
      );

      double totalSteps = 0, totalCalories = 0, totalDistance = 0;
      for (var dp in healthData) {
        if (dp.value is! NumericHealthValue) continue;
        final value = (dp.value as NumericHealthValue).numericValue;
        switch (dp.type) {
          case HealthDataType.STEPS:
            totalSteps += value;
            break;
          case HealthDataType.TOTAL_CALORIES_BURNED:
            totalCalories += value;
            break;
          case HealthDataType.DISTANCE_DELTA:
            totalDistance += value;
            break;
          default:
            break;
        }
      }
      double totalSpeed = totalDistance / 60000;

      await csd.createSessionData(
        us.userId.toString(),
        now.subtract(totalSelectedDuration! + selectedDuration),
        now.subtract(selectedDuration),
        totalSteps,
        totalDistance,
        totalCalories,
        totalSpeed,
        "Phone",
      );
    });
  }
}
