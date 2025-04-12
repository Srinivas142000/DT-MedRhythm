import "package:health/health.dart";
import 'package:flutter/material.dart';

class Constants {
  // Health data types
  static const List<HealthDataType> healthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_DELTA,
  ];
}

class ChartColors {
  static const Color steps = Colors.green;
  static const Color calories = Colors.purple;
  static const Color distance = Colors.amber;
  static const Color speed = Colors.orange;
}

class ChartTypes {
  static const List<String> all = ["Steps", "Calories", "Distance", "AvgSpeed"];

  static const List<bool> showAll = [true, true, true, true];
  static const List<bool> stepsAndDistance = [true, false, true, false];
  static const List<bool> caloriesAndSpeed = [false, true, false, true];
}

class WeekDays {
  static const List<String> labels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
}
