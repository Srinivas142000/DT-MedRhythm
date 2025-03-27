import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';
// import 'package:medrhythms/services/record_service.dart';
import 'package:medrhythms/constants/constants.dart';
import 'dart:math' as math;

class RecordsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData;

  const RecordsPage({super.key, required this.uuid, required this.userData});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  Bottombar bb = Bottombar();

  DateTime selectedDate = DateTime.now();

  // 0 = Monday, 6 = Sunday
  int selectedDay = DateTime.now().weekday - 1;

  // final RecordService _recordService = RecordService();

  List<Map<String, dynamic>?> weekData = List.filled(7, null);

  bool isLoading = true;

  List<bool> activeCharts = ChartTypes.showAll;

  @override
  void initState() {
    super.initState();
    _fetchWeekData();
  }

  Future<void> _fetchWeekData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      final int currentWeekday = now.weekday;

      final mondayDate = now.subtract(Duration(days: currentWeekday - 1));
      // Date - Workouts that happened that day?
      for (int i = 0; i < 7; i++) {
        final date = mondayDate.add(Duration(days: i));
        print('Fetching data for: $date, UserID: ${widget.uuid}');
        // weekData[i] = await _recordService.getWorkoutRecord(widget.uuid, date);
        print('Data for $date: ${weekData[i]}');
      }

      selectedDay = currentWeekday - 1;
    } catch (e) {
      print('Error retrieving workout records: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _selectDay(int index) {
    setState(() {
      selectedDay = index;

      final now = DateTime.now();
      final int currentWeekday = now.weekday;
      final mondayDate = now.subtract(Duration(days: currentWeekday - 1));
      selectedDate = mondayDate.add(Duration(days: index));
    });
  }

  void _toggleChartCombination(int option) {
    setState(() {
      if (option == 0) {
        activeCharts = ChartTypes.stepsAndDistance;
      } else {
        activeCharts = ChartTypes.caloriesAndSpeed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Records",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        return _buildDaySelector(index);
                      }),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (activeCharts[0])
                            _buildMetricChart(
                              ChartTypes.all[0],
                              (weekData[selectedDay]?['totalSteps'] ?? 0)
                                  .toString(),
                              "steps",
                              ChartColors.steps,
                            ),

                          if (activeCharts[1])
                            _buildMetricChart(
                              ChartTypes.all[1],
                              (weekData[selectedDay]?['totalCalories'] ?? 0)
                                  .toStringAsFixed(2),
                              "kcal",
                              ChartColors.calories,
                            ),

                          if (activeCharts[2])
                            _buildMetricChart(
                              ChartTypes.all[2],
                              (weekData[selectedDay]?['totalDistance'] ?? 0)
                                  .toStringAsFixed(2),
                              "mi",
                              ChartColors.distance,
                            ),

                          if (activeCharts[3])
                            _buildMetricChart(
                              ChartTypes.all[3],
                              (weekData[selectedDay]?['averageSpeed'] ?? 0)
                                  .toStringAsFixed(2),
                              "mph",
                              ChartColors.speed,
                            ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => _toggleChartCombination(0),
                          child: Text(
                            "Steps and\nDistance",
                            textAlign: TextAlign.center,
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),

                        OutlinedButton(
                          onPressed: () => _toggleChartCombination(1),
                          child: Text(
                            "Calories and\nAvgSpeed",
                            textAlign: TextAlign.center,
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  bb,
                ],
              ),
    );
  }

  Widget _buildDaySelector(int index) {
    bool isSelected = selectedDay == index;

    return GestureDetector(
      onTap: () => _selectDay(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? ChartColors.steps : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          WeekDays.labels[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChart(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    "$title ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    " $unit",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Container(
              height: 200,
              padding: EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 12),
              child: LineChart(_createLineChartData(title, color)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _createLineChartData(String metricType, Color color) {
    List<FlSpot> spots = [];

    for (int hour = 0; hour < 24; hour++) {
      double baseValue = 50;
      double amplitude = 30;
      double phase = hour / 24.0 * 2 * 3.14159; // Convert to radians

      double value = baseValue + amplitude * (0.5 + 0.5 * math.sin(phase));

      spots.add(FlSpot(hour.toDouble(), value));
    }

    double maxY = 125;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 6, // Display every 6 hours
            getTitlesWidget: (value, meta) {
              if (value % 6 == 0) {
                String time = "${value.toInt()}:00";
                return Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 25,
            getTitlesWidget: (value, meta) {
              if (value % 25 == 0) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white.withOpacity(0.8),
        ),
        touchCallback:
            (FlTouchEvent event, LineTouchResponse? touchResponse) {},
        handleBuiltInTouches: true,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            checkToShowDot: (spot, barData) {
              return spot.x == 12; // Show marker at 12 noon
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
