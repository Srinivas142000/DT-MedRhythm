import "package:health/health.dart";
import 'package:flutter/material.dart';

/// A class containing constants used throughout the application.
class Constants {
  /// A list of health data types used for tracking health metrics.
  static const List<HealthDataType> healthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_DELTA,
  ];
}

/// A class defining color constants for different chart types.
class ChartColors {
  /// Color for steps data in charts.
  static const Color steps = Colors.green;

  /// Color for calories data in charts.
  static const Color calories = Colors.purple;

  /// Color for distance data in charts.
  static const Color distance = Colors.amber;

  /// Color for speed data in charts.
  static const Color speed = Colors.orange;
}

/// A class defining chart types and their visibility configurations.
class ChartTypes {
  /// Names of charts
  static const List<String> all = ["Steps", "Calories", "Distance", "AvgSpeed"];

  /// Show which charts to be available
  static const List<bool> showAll = [true, true, true, true];

  /// A list of booleans indicating visibility of steps and distance charts.
  static const List<bool> stepsAndDistance = [true, false, true, false];

  /// A list of booleans indicating visibility of calories and speed charts.
  static const List<bool> caloriesAndSpeed = [false, true, false, true];
}

/// A class defining constants for week day labels.
class WeekDays {
  // labels for the days of the week.
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
