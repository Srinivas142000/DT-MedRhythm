import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/services/record_service.dart'; // Import the RecordService
import 'dart:math' as math;// Add math mixin to provide sin function

class RecordsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData;

  const RecordsPage({super.key, required this.uuid, required this.userData});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  // Bottom navigation bar instance
  Bottombar bb = Bottombar();
  
  // Currently selected date
  DateTime selectedDate = DateTime.now();
  
  // Currently selected day of the week
  int selectedDay = DateTime.now().weekday - 1; // 0 = Monday, 6 = Sunday
  
  // Day of week labels
  final List<String> weekDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  
  // Initialize RecordService
  final RecordService _recordService = RecordService();
  
  // Store weekly workout data
  List<Map<String, dynamic>?> weekData = List.filled(7, null);
  
  // Loading state
  bool isLoading = true;
  
  // Chart colors
  final Color stepsColor = Colors.green;
  final Color caloriesColor = Colors.purple;
  final Color distanceColor = Colors.amber;
  final Color speedColor = Colors.orange;
  
  // Four chart types for display
  List<String> chartTypes = ["Steps", "Calories", "Distance", "AvgSpeed"];
  
  // Currently active chart combination (default shows all four)
  List<bool> activeCharts = [true, true, true, true];

  @override
  void initState() {
    super.initState();
    // Get this week's data
    _fetchWeekData();
  }
  
  // Fetch this week's data
  Future<void> _fetchWeekData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get the start date of this week (Monday)
      final now = DateTime.now();
      final int currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
      
      // Calculate this Monday's date
      final mondayDate = now.subtract(Duration(days: currentWeekday - 1));
      
      // Get data for the week
      for (int i = 0; i < 7; i++) {
        final date = mondayDate.add(Duration(days: i));
        print('Fetching data for: $date, UserID: ${widget.uuid}');
        weekData[i] = await _recordService.getWorkoutRecord(widget.uuid, date);
        print('Data for $date: ${weekData[i]}');
      }
      
      // Select today
      selectedDay = currentWeekday - 1;
    } catch (e) {
      print('Error retrieving workout records: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Select a different date
  void _selectDay(int index) {
    setState(() {
      selectedDay = index;
      
      // Calculate the selected date
      final now = DateTime.now();
      final int currentWeekday = now.weekday;
      final mondayDate = now.subtract(Duration(days: currentWeekday - 1));
      selectedDate = mondayDate.add(Duration(days: index));
    });
  }
  
  // Toggle chart combination
  void _toggleChartCombination(int option) {
    // Two combinations: Steps and Distance / Calories and AvgSpeed
    setState(() {
      if (option == 0) { // Steps and Distance
        activeCharts = [true, false, true, false];
      } else { // Calories and AvgSpeed
        activeCharts = [false, true, false, true];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Records",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () {
                          // Can add more options here
                        },
                      ),
                    ],
                  ),
                ),
                
                // Date selection bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      return _buildDaySelector(index);
                    }),
                  ),
                ),
                
                // Metric charts
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Steps chart (if activated)
                        if (activeCharts[0])
                          _buildMetricChart(
                            "Steps",
                            (weekData[selectedDay]?['totalSteps'] ?? 0).toString(),
                            "steps",
                            stepsColor,
                          ),
                        
                        // Calories chart (if activated)
                        if (activeCharts[1])
                          _buildMetricChart(
                            "Calories",
                            (weekData[selectedDay]?['totalCalories'] ?? 0).toStringAsFixed(2),
                            "kcal",
                            caloriesColor,
                          ),
                        
                        // Distance chart (if activated)
                        if (activeCharts[2])
                          _buildMetricChart(
                            "Distance",
                            (weekData[selectedDay]?['totalDistance'] ?? 0).toStringAsFixed(2),
                            "mi",
                            distanceColor,
                          ),
                        
                        // AvgSpeed chart (if activated)
                        if (activeCharts[3])
                          _buildMetricChart(
                            "AvgSpeed",
                            (weekData[selectedDay]?['averageSpeed'] ?? 0).toStringAsFixed(2),
                            "mph",
                            speedColor,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom chart combination toggle buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // "Steps and Distance" button
                      OutlinedButton(
                        onPressed: () => _toggleChartCombination(0),
                        child: Text("Steps and\nDistance", textAlign: TextAlign.center),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(color: Colors.green),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      
                      // "Calories and AvgSpeed" button
                      OutlinedButton(
                        onPressed: () => _toggleChartCombination(1),
                        child: Text("Calories and\nAvgSpeed", textAlign: TextAlign.center),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(color: Colors.green),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom navigation bar
                bb,
              ],
            ),
    );
  }
  
  // Build day selector button
  Widget _buildDaySelector(int index) {
    bool isSelected = selectedDay == index;
    
    return GestureDetector(
      onTap: () => _selectDay(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          weekDays[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  // Build metric chart
  Widget _buildMetricChart(String title, String value, String unit, Color color) {
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
            // Metric title and value
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Line chart
            Container(
              height: 200,
              padding: EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 12),
              child: LineChart(
                _createLineChartData(title, color),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Create line chart data
  LineChartData _createLineChartData(String metricType, Color color) {
    // Generate chart data points (24 hours, one point per hour)
    List<FlSpot> spots = [];
    
    // Simulate data for different times of the day (in a real app, this should be fetched from the backend)
    for (int hour = 0; hour < 24; hour++) {
      // Create a random pattern based on sine wave to make the chart look more natural
      double baseValue = 50;
      double amplitude = 30;
      double phase = hour / 24.0 * 2 * 3.14159; // Convert to radians
      
      double value = baseValue + amplitude * (0.5 + 0.5 * math.sin(phase));
      
      // Add point
      spots.add(FlSpot(hour.toDouble(), value));
    }
    
    // Set different maximum values for different metrics
    double maxY = 125;
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
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
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
        handleBuiltInTouches: true,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.5),
              color,
            ],
          ),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            // Only show dot markers at specific points
            checkToShowDot: (spot, barData) {
              return spot.x == 12; // Show marker at 12 noon
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
