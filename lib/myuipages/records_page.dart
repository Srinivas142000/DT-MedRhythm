import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/constants/constants.dart';
import 'package:medrhythms/mypages/readroutes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medrhythms/myuipages/records_charts.dart';
import 'dart:math' as math;

class RecordsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData; // Define the missing field
  const RecordsPage({super.key, required this.uuid, required this.userData});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final FirestoreServiceRead fsr = FirestoreServiceRead();
  Bottombar bb = Bottombar(currentIndex: 1);

  DateTime selectedDate = DateTime.now();
  String selectedDateKey = '';
  Map<String, Map<String, dynamic>> weekData = {};
  bool isLoading = true;
  List<bool> activeCharts = ChartTypes.showAll;

  List<double> activityPattern = List.filled(24, 0.02);

  bool useCumulativeMode = true;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool showCalendar = false;

  @override
  void initState() {
    super.initState();

    UserSession().userId = widget.uuid;
    _setSelectedDateToToday();
    // Initialize user session and load weekly data on startup.

    _fetchFormattedWeekData();
  }

  void _setSelectedDateToToday() {
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    selectedDateKey = _dateToKey(selectedDate);
    _selectedDay = selectedDate;
    _focusedDay = selectedDate;
  }

  String _dateToKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  /// Get the data of the currently selected date for chart display
  /// Return null if the data does not exist
  Map<String, dynamic>? getSelectedDayData() {
    return weekData[selectedDateKey];
  }

  /// Process session data and calculate daily steps, calories, distance and average speed totals
  /// @param result - a map containing hourly data indexed by date
  Future<void> _processSessionData(Map<String, dynamic> result) async {
    if (result.isEmpty) return;

    // Process raw hourly data: compute totals and average speed per day.

    for (var dateKey in result.keys) {
      Map<String, dynamic>? hourlyMap =
          result[dateKey] as Map<String, dynamic>?;

      if (hourlyMap != null) {
        double totalSteps = 0, totalCalories = 0, totalDistance = 0;
        double totalSpeed = 0;
        int hourCount = 0;
        int activeHours = 0;

        for (var entry in hourlyMap.entries) {
          var bucket = entry.value;
          if (bucket is Map<String, dynamic>) {
            totalCalories += (bucket['calories'] ?? 0.0);
            double distance = bucket['distance'] ?? 0.0;
            if (distance > 1000) {
              distance = distance / 1000;
            }
            totalDistance += distance;
            totalSteps += (bucket['totalSteps'] ?? 0.0);

            if (bucket.containsKey('speed')) {
              double speed = bucket['speed'] ?? 0.0;
              if (speed > 0) {
                totalSpeed += speed;
                activeHours++;
              }
            }

            hourCount++;
          }
        }

        double avgSpeed = 0.0;
        if (activeHours > 0) {
          avgSpeed = totalSpeed / activeHours;
        } else if (hourCount > 0 && totalDistance > 0) {
          avgSpeed = totalDistance / hourCount;
        }

        DateTime date;
        try {
          date = DateTime.parse(dateKey);
        } catch (e) {
          print("Error parsing date: $dateKey, error: $e");
          continue;
        }

        weekData[dateKey] = {
          'totalSteps': totalSteps,
          'totalCalories': totalCalories,
          'totalDistance': totalDistance,
          'averageSpeed': avgSpeed,
          'hourlyData': hourlyMap,
          'date': date,
        };

        print(
          "Processed data for ${date.toIso8601String()}: totalSteps=${totalSteps}, totalCalories=${totalCalories}, totalDistance=${totalDistance}, averageSpeed=${avgSpeed}",
        );
      }
    }
  }

  Future<void> _fetchFormattedWeekData() async {
    setState(() => isLoading = true);

    try {
      final Map<String, dynamic> result = await fetchData(widget.uuid);
      if (result.containsKey('weeklyData')) {
        List<dynamic> weeklyData = result['weeklyData'];

        final now = DateTime.now();
        final int currentWeekday = now.weekday;
        // Align week start to Monday of the current week.

        final mondayDate = now.subtract(Duration(days: currentWeekday - 1));

        for (int i = 0; i < math.min(7, weeklyData.length); i++) {
          final date = mondayDate.add(Duration(days: i));
          final Map<String, dynamic> dailyData = weeklyData[i];

          String dateKey = _dateToKey(date);
          await _processSessionData({dateKey: dailyData[dateKey]});
        }

        selectedDateKey = _dateToKey(selectedDate);

        if (weekData[selectedDateKey] == null) {
          _setSelectedDateToToday();
        }
      }
    } catch (e) {
      print('Error retrieving formatted session data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Get the activity data for the specified date and update the status
  /// If the data already exists, update the selected date directly, otherwise get it from Firestore
  Future<void> fetchSpecificDateData(DateTime date) async {
    setState(() => isLoading = true);

    // Load data for this date: use cached weekData if available, else fetch from backend.
    try {
      final String dateKey = _dateToKey(date);

      if (weekData.containsKey(dateKey)) {
        setState(() {
          selectedDate = date;
          selectedDateKey = dateKey;
          _selectedDay = date;
          _focusedDay = date;
        });
        return;
      }

      final result = await fsr.fetchSessionDetails(
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      await _processSessionData(result);

      setState(() {
        selectedDate = date;
        selectedDateKey = dateKey;
        _selectedDay = date;
        _focusedDay = date;
      });

      print("Fetched data for specific date: $dateKey");
    } catch (e) {
      print('Error fetching data for specific date: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Switch the chart combination display mode
  /// @param option - 0: Display steps and distance, 1: Display calories and average speed
  void _toggleChartCombination(int option) {
    setState(() {
      activeCharts =
          option == 0
              ? ChartTypes.stepsAndDistance
              : ChartTypes.caloriesAndSpeed;
    });
  }

  void _selectDay(String dateKey) {
    if (weekData.containsKey(dateKey)) {
      setState(() {
        selectedDateKey = dateKey;
        selectedDate = weekData[dateKey]!['date'] as DateTime;
        _selectedDay = selectedDate;
        _focusedDay = selectedDate;
      });
    } else {
      final date = DateTime.parse(dateKey);
      fetchSpecificDateData(date);
    }
  }

  void _toggleCalendarView() {
    setState(() {
      showCalendar = !showCalendar;
      print("Toggle calendar view: $showCalendar");
    });
  }

  void _toggleChartMode() {
    setState(() {
      useCumulativeMode = !useCumulativeMode;
    });
  }

  Widget _buildCalendar() {
    // Build the in‑app calendar view for selecting dates.
    return Container(
      margin: EdgeInsets.all(8.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) async {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          final dateKey = _dateToKey(selectedDay);

          if (weekData.containsKey(dateKey)) {
            setState(() {
              selectedDate = selectedDay;
              selectedDateKey = dateKey;
            });
            return;
          }

          final result = await fsr.fetchSessionDetails(
            DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
            DateTime(
              selectedDay.year,
              selectedDay.month,
              selectedDay.day,
              23,
              59,
              59,
            ),
          );

          print("Fetched data from calendar selection: $result");

          await _processSessionData(result);

          setState(() {
            selectedDate = selectedDay;
            selectedDateKey = dateKey;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
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
        headerStyle: HeaderStyle(titleCentered: true),
      ),
    );
  }

  Widget _buildDaySelector() {
    // Build the day selector for selecting dates.
    final now = DateTime.now();
    final int currentWeekday = now.weekday;
    final mondayDate = now.subtract(Duration(days: currentWeekday - 1));

    List<String> dateKeys = List.generate(7, (index) {
      final date = mondayDate.add(Duration(days: index));
      return _dateToKey(date);
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dateKey = dateKeys[index];
        final date = mondayDate.add(Duration(days: index));
        bool isSelected = selectedDateKey == dateKey;

        return GestureDetector(
          onTap: () => _selectDay(dateKey),
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
      }),
    );
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
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.calendar_month),
                              onPressed: () {
                                print("Calendar icon clicked");
                                _toggleCalendarView();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showCalendar) _buildCalendar() else _buildDaySelector(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (activeCharts[0])
                            MetricChart(
                              title: "Steps",
                              selectedDayData: getSelectedDayData(),
                              weekData: weekData,
                            ),
                          if (activeCharts[1])
                            MetricChart(
                              title: "Calories",
                              selectedDayData: getSelectedDayData(),
                              weekData: weekData,
                            ),
                          if (activeCharts[2])
                            MetricChart(
                              title: "Distance",
                              selectedDayData: getSelectedDayData(),
                              weekData: weekData,
                            ),
                          if (activeCharts[3])
                            MetricChart(
                              title: "AvgSpeed",
                              selectedDayData: getSelectedDayData(),
                              weekData: weekData,
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
}
