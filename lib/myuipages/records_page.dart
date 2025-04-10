import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/services/record_service.dart';
import 'package:medrhythms/constants/constants.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class RecordsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData;

  const RecordsPage({super.key, required this.uuid, required this.userData});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  Bottombar bb = Bottombar(currentIndex: 1);

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool showCalendar = false;

  DateTime selectedDate = DateTime.now();

  int selectedDay = DateTime.now().weekday - 1;

  List<Map<String, dynamic>?> weekData = List.filled(7, null);

  bool isLoading = true;

  List<bool> activeCharts = ChartTypes.showAll;
  
  final CollectionReference sessionColl = FirebaseFirestore.instance.collection('sessions');

  final RecordService _recordService = RecordService();

  @override
  void initState() {
    super.initState();
    try {
      _fetchWeekData();
      _setupLiveSessionListener();
    } catch (e) {
      print('Error during initialization: $e');
    }
  }
  
  void _setupLiveSessionListener() {
    sessionColl
        .where('userId', isEqualTo: widget.uuid)
        .snapshots()
        .listen((snapshot) {
      _fetchWeekData();
    });
  }

  Future<void> _fetchWeekData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      final int currentWeekday = now.weekday;

      final mondayDate = now.subtract(Duration(days: currentWeekday - 1));
      
      weekData = List.filled(7, null);
      
      for (int i = 0; i < 7; i++) {
        final date = mondayDate.add(Duration(days: i));
        print('Fetching data for: $date, UserID: ${widget.uuid}');
        weekData[i] = await _recordService.getWorkoutRecord(widget.uuid, date);
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
      _selectedDay = selectedDate;
      _focusedDay = selectedDate;
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

  void _toggleCalendarView() {
    setState(() {
      showCalendar = !showCalendar;
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
                          icon: Icon(Icons.calendar_month),
                          onPressed: _toggleCalendarView,
                        ),
                      ],
                    ),
                  ),

                  if (showCalendar)
                    _buildCalendar()
                  else
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

  Widget _buildCalendar() {
    return Container(
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
      margin: EdgeInsets.all(8.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            selectedDate = selectedDay;

            if (selectedDay.weekday >= 1 && selectedDay.weekday <= 7) {
              this.selectedDay = selectedDay.weekday - 1;
            }

            // In a real implementation, will fetch data for the selected day here
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: ChartColors.steps,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: ChartColors.steps.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: ChartColors.steps),
            borderRadius: BorderRadius.circular(20),
          ),
          formatButtonTextStyle: TextStyle(color: ChartColors.steps),
        ),
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

    double maxValue;
    String unit;
    bool useIntegers = false;

    switch (metricType.toLowerCase()) {
      case "steps":
        maxValue = 10000;
        unit = "steps";
        useIntegers = true;
        break;
      case "calories":
        maxValue = 1000;
        unit = "kcal";
        break;
      case "distance":
        maxValue = 10.0;
        unit = "mi";
        break;
      case "avgspeed":
      case "average speed":
        maxValue = 10.0;
        unit = "mph";
        break;
      default:
        maxValue = 125;
        unit = "";
    }

    double interval;
    if (maxValue <= 10) {
      interval = 2.0;
    } else if (maxValue <= 100) {
      interval = 20.0;
    } else if (maxValue <= 1000) {
      interval = 200.0;
    } else {
      interval = 2000.0;
    }

    for (int hour = 0; hour < 24; hour++) {
      // we will use actual data from backend later
      // For now, we'll simulate with a scaled sine wave
      double baseValue = maxValue * 0.3;
      double amplitude = maxValue * 0.2;
      double phase = hour / 24.0 * 2 * math.pi;

      double value = baseValue + amplitude * (0.5 + 0.5 * math.sin(phase));

      // If we need integers (like for steps), round the value
      if (useIntegers) {
        value = value.roundToDouble();
      }

      spots.add(FlSpot(hour.toDouble(), value));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: 1,
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1);
        },
        horizontalInterval: interval,
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
            interval: 2,
            getTitlesWidget: (value, meta) {
              final int hour = value.toInt();
              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  "${hour}:00",
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: interval,
            getTitlesWidget: (value, meta) {
              String formattedValue =
                  useIntegers
                      ? value.toInt().toString()
                      : value.toStringAsFixed(1);
              return Text(
                formattedValue,
                style: TextStyle(fontSize: 9, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: maxValue,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final int hour = touchedSpot.x.toInt();
              final int nextHour = (hour + 1) % 24;

              String formattedValue =
                  useIntegers
                      ? touchedSpot.y.toInt().toString()
                      : touchedSpot.y.toStringAsFixed(1);

              return LineTooltipItem(
                '${hour}:00 - ${nextHour}:00\n$formattedValue $unit',
                TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
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
            show: true,
            checkToShowDot: (spot, barData) {
              return false;
            },
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
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

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
