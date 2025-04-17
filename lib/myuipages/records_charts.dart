import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import 'package:medrhythms/constants/constants.dart';

/// Chart data processing utility class for converting and displaying various health metrics
class RecordsChartUtils {
  /// Converts hourly data to chart coordinate points
  /// @param field - Type of metric to process, such as "steps", "calories", etc.
  /// @param dayData - Daily activity data, can be null
  static List<FlSpot> convertHourlyDataToSpots(
    String field,
    Map<String, dynamic>? dayData,
  ) {
    if (dayData == null)
      return List.generate(24, (hour) => FlSpot(hour.toDouble(), 0));

    final hourlyData = dayData['hourlyData'];

    if (field.toLowerCase() == "avgspeed") {
      double speed = dayData['averageSpeed'] ?? 0.0;
      List<FlSpot> spots = [];

      for (int hour = 0; hour < 24; hour++) {
        spots.add(FlSpot(hour.toDouble(), speed));
      }

      return spots;
    } else {
      final totalValue =
          dayData[field.toLowerCase() == "steps"
              ? 'totalSteps'
              : field.toLowerCase() == "calories"
              ? 'totalCalories'
              : 'totalDistance'] ??
          0.0;

      if (hourlyData != null && hourlyData is Map<dynamic, dynamic>) {
        List<FlSpot> spots = [];
        double cumulativeValue = 0;

        for (int hour = 0; hour < 24; hour++) {
          // Build the Firestore bucket key for this hour range.
          String hourKey =
              "${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00";

          if (hourlyData.containsKey(hourKey)) {
            final hourValue = hourlyData[hourKey];
            if (hourValue is Map<dynamic, dynamic>) {
              String dataField = field.toLowerCase();
              if (dataField == "steps") dataField = "totalSteps";

              if (hourValue.containsKey(dataField)) {
                double value = (hourValue[dataField] ?? 0.0).toDouble();
                cumulativeValue += value;
                spots.add(FlSpot(hour.toDouble(), cumulativeValue));
                continue;
              }
            }
          }

          if (spots.isNotEmpty) {
            spots.add(FlSpot(hour.toDouble(), cumulativeValue));
          } else {
            spots.add(FlSpot(hour.toDouble(), 0));
          }
        }

        return spots;
      } else if (totalValue > 0) {
        List<FlSpot> spots = [];
        double hourlyValue = totalValue / 24;
        double cumulativeValue = 0;

        for (int hour = 0; hour < 24; hour++) {
          cumulativeValue += hourlyValue;
          spots.add(FlSpot(hour.toDouble(), cumulativeValue));
        }

        return spots;
      } else {
        List<FlSpot> spots = [];
        for (int hour = 0; hour < 24; hour++) {
          spots.add(FlSpot(hour.toDouble(), 0));
        }
        return spots;
      }
    }
  }

  /// For non‑speed metrics, choose a “nice” axis step based on magnitude:
  /// small (<50) → coarse (10), medium (<200) → medium (50), etc.
  static double getYAxisInterval(double maxValue, String title) {
    if (title.toLowerCase() == "avgspeed") {
      // For speed, show only hours with non‑zero speed or distance; otherwise leave zero.

      return 10.0;
    }

    if (title.toLowerCase() == "distance") {
      if (maxValue <= 10) return 1;
      if (maxValue <= 50) return 5;
      if (maxValue <= 100) return 10;
      if (maxValue <= 500) return 50;
      if (maxValue <= 1000) return 100;
      return 200;
    }

    if (maxValue <= 10) return 2;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 25;
    if (maxValue <= 200) return 50;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    return 5000;
  }

  // Beautify labels:
  // ≥1000 → “1.2K”; ≥100 → integer; ≥10 → one decimal; else two decimals.

  static String formatYAxisLabel(double value, String title) {
    if (title.toLowerCase() == "avgspeed") {
      return value.toStringAsFixed(1);
    }

    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else if (value >= 100) {
      return value.toInt().toString();
    } else if (value >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  /// Gets chart display data, showing values only for hours with activity
  /// @param title - Chart type, such as "Steps", "Calories", etc.
  /// @param dayData - Daily activity data, can be null
  static List<Map<String, dynamic>> getChartData(
    String title,
    Map<String, dynamic>? dayData,
  ) {
    if (dayData == null) {
      return List.generate(
        24,
        (hour) => {'hour': '${hour.toString().padLeft(2, '0')}h', 'value': 0.0},
      );
    }

    final hourlyData = dayData['hourlyData'];
    List<Map<String, dynamic>> chartData = [];

    for (int hour = 0; hour < 24; hour++) {
      chartData.add({
        'hour': '${hour.toString().padLeft(2, '0')}h',
        'value': 0.0,
      });
    }

    if (hourlyData != null && hourlyData is Map<dynamic, dynamic>) {
      if (title.toLowerCase() == "avgspeed") {
        for (int hour = 0; hour < 24; hour++) {
          String hourKey =
              "${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00";

          if (hourlyData.containsKey(hourKey)) {
            final hourValue = hourlyData[hourKey];
            if (hourValue is Map<dynamic, dynamic>) {
              double steps = (hourValue['totalSteps'] ?? 0.0).toDouble();
              double distance = (hourValue['distance'] ?? 0.0).toDouble();

              if (steps > 0 || distance > 0) {
                if (hourValue.containsKey('speed')) {
                  double speed = (hourValue['speed'] ?? 0.0).toDouble();
                  if (speed > 0) {
                    chartData[hour]['value'] = speed;
                  } else if (distance > 0) {
                    chartData[hour]['value'] = dayData['averageSpeed'] ?? 0.0;
                  }
                } else if (distance > 0) {
                  chartData[hour]['value'] = dayData['averageSpeed'] ?? 0.0;
                }
              }
            }
          }
        }
      } else {
        String dataField = title.toLowerCase();
        if (dataField == "steps") dataField = "totalSteps";

        for (int hour = 0; hour < 24; hour++) {
          String hourKey =
              "${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00";

          if (hourlyData.containsKey(hourKey)) {
            final hourValue = hourlyData[hourKey];
            if (hourValue is Map<dynamic, dynamic>) {
              double steps = (hourValue['totalSteps'] ?? 0.0).toDouble();
              double distance = (hourValue['distance'] ?? 0.0).toDouble();

              if (steps > 0 || distance > 0) {
                if (hourValue.containsKey(dataField)) {
                  double value = (hourValue[dataField] ?? 0.0).toDouble();
                  if (value > 0) {
                    chartData[hour]['value'] = value;
                  }
                }
              }
            }
          }
        }
      }
    }

    return chartData;
  }
}

/// Health metrics chart widget for displaying steps, calories, distance and average speed
class MetricChart extends StatelessWidget {
  final String title;
  final Map<String, dynamic>? selectedDayData;
  final Map<String, Map<String, dynamic>> weekData;

  const MetricChart({
    Key? key,
    required this.title,
    required this.selectedDayData,
    required this.weekData,
  }) : super(key: key);

  /// Builds the chart UI, handles unit display and color styling
  /// Automatically selects colors and unit suffix based on metric type
  @override
  Widget build(BuildContext context) {
    double maxValue = title.toLowerCase() == "avgspeed" ? 30.0 : 10;

    double currentValue = 0.0;
    String unitSuffix = "";

    if (selectedDayData != null) {
      currentValue =
          selectedDayData![title.toLowerCase() == "steps"
              ? 'totalSteps'
              : title.toLowerCase() == "calories"
              ? 'totalCalories'
              : title.toLowerCase() == "avgspeed"
              ? 'averageSpeed'
              : 'totalDistance'] ??
          0.0;

      if (title.toLowerCase() == "avgspeed") {
        unitSuffix = " mph";
      } else if (title.toLowerCase() == "distance") {
        unitSuffix = " m";
      } else if (title.toLowerCase() == "calories") {
        unitSuffix = " kcal";
      } else if (title.toLowerCase() == "steps") {
        unitSuffix = " steps";
      }
    }

    Color titleColor = Colors.black;
    if (title.toLowerCase() == "calories") {
      titleColor = Colors.orange;
    } else if (title.toLowerCase() == "distance") {
      titleColor = Colors.blue;
    } else if (title.toLowerCase() == "avgspeed") {
      titleColor = Colors.green;
    } else if (title.toLowerCase() == "steps") {
      titleColor = Colors.purple;
    }

    if (weekData.isNotEmpty) {
      for (var entry in weekData.entries) {
        final day = entry.value;
        final Map<dynamic, dynamic>? hourlyData =
            day['hourlyData'] as Map<dynamic, dynamic>?;

        if (day.containsKey(
          title.toLowerCase() == "steps"
              ? 'totalSteps'
              : title.toLowerCase() == "calories"
              ? 'totalCalories'
              : title.toLowerCase() == "avgspeed"
              ? 'averageSpeed'
              : 'totalDistance',
        )) {
          double value =
              day[title.toLowerCase() == "steps"
                      ? 'totalSteps'
                      : title.toLowerCase() == "calories"
                      ? 'totalCalories'
                      : title.toLowerCase() == "avgspeed"
                      ? 'averageSpeed'
                      : 'totalDistance']
                  as double;
          if (title.toLowerCase() == "avgspeed") {
            maxValue = math.max(value * 1.2, 7.5);
          } else if (value > maxValue) {
            maxValue = value;
          }
        }

        if (hourlyData != null) {
          for (var hour in hourlyData.keys) {
            var hourData = hourlyData[hour];
            if (hourData is Map<dynamic, dynamic>) {
              String field = title.toLowerCase();
              if (field == "steps") field = "totalSteps";
              if (field == "avgspeed") field = "speed";

              if (hourData.containsKey(field)) {
                double? value = (hourData[field] ?? 0.0) as double?;
                if (value != null && value > maxValue) {
                  maxValue = value;
                }
              }
            }
          }
        }
      }
    }

    Color chartColor;
    Color gradientColor;
    if (title.toLowerCase() == "calories") {
      chartColor = Colors.orange;
      gradientColor = Colors.orange.withOpacity(0.3);
    } else if (title.toLowerCase() == "distance") {
      chartColor = Colors.blue;
      gradientColor = Colors.blue.withOpacity(0.3);
    } else if (title.toLowerCase() == "avgspeed") {
      chartColor = Colors.green;
      gradientColor = Colors.green.withOpacity(0.3);
    } else {
      chartColor = Colors.purple;
      gradientColor = Colors.purple.withOpacity(0.3);
    }

    List<Map<String, dynamic>> chartData = RecordsChartUtils.getChartData(
      title,
      selectedDayData,
    );

    bool hasData = currentValue > 0;

    double actualMaxValue = 0;
    for (var data in chartData) {
      if (data['value'] > actualMaxValue) {
        actualMaxValue = data['value'];
      }
    }

    if (actualMaxValue > maxValue) {
      maxValue = actualMaxValue;
    }

    final yAxisMax = title.toLowerCase() == "avgspeed" ? 30.0 : maxValue * 1.2;
    final interval = RecordsChartUtils.getYAxisInterval(maxValue, title);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Text(
                  title + " ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${currentValue.toStringAsFixed(2)}$unitSuffix",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          SfCartesianChart(
            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(color: Colors.grey[700], fontSize: 10),
              minimum: 0,
              maximum: 23,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              interval: 3,
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: yAxisMax,
              interval: interval,
              labelFormat: '{value}',
              labelStyle: TextStyle(color: Colors.grey[700], fontSize: 10),
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                return ChartAxisLabel(
                  RecordsChartUtils.formatYAxisLabel(
                    details.value.toDouble(),
                    title,
                  ),
                  details.textStyle,
                );
              },
            ),
            margin: EdgeInsets.only(left: 5, right: 5),
            plotAreaBorderWidth: 0,
            enableAxisAnimation: true,
            series: <CartesianSeries>[
              if (hasData)
                SplineAreaSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['hour'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['value'],
                  color: gradientColor,
                  borderColor: chartColor,
                  borderWidth: 1,
                  markerSettings: MarkerSettings(isVisible: false),
                  splineType: SplineType.natural,
                )
              else
                LineSeries<Map<String, dynamic>, String>(
                  dataSource: List.generate(
                    24,
                    (index) => {
                      'hour': '${index.toString().padLeft(2, '0')}h',
                      'value': 0.0,
                    },
                  ),
                  xValueMapper: (Map<String, dynamic> data, _) => data['hour'],
                  yValueMapper: (Map<String, dynamic> data, _) => 0,
                  color: chartColor,
                  width: 1,
                  markerSettings: MarkerSettings(isVisible: false),
                  emptyPointSettings: EmptyPointSettings(
                    mode: EmptyPointMode.zero,
                  ),
                ),
            ],
            // Build a custom tooltip showing “HH:00” and “value + unit” in a styled box.

            tooltipBehavior: TooltipBehavior(
              enable: true,
              duration: 2500,
              builder: (
                dynamic data,
                dynamic point,
                dynamic series,
                int pointIndex,
                int seriesIndex,
              ) {
                final hourValue = int.parse(
                  data['hour'].toString().replaceAll('h', ''),
                );
                final value = data['value'];

                final formattedTime = "${hourValue}:00";

                String formattedValue =
                    value is int ? value.toString() : value.toStringAsFixed(1);

                return Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$formattedValue$unitSuffix',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: chartColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
