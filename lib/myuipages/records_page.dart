import 'package:flutter/material.dart';
import 'package:geekyants_flutter_gauges/geekyants_flutter_gauges.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';

// Main widget for the Records page that tracks user activities
class RecordsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData;

  const RecordsPage({super.key, required this.uuid, required this.userData});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> with SingleTickerProviderStateMixin {
  // Bottom navigation bar instance - keeping original implementation
  Bottombar bb = Bottombar();
  
  // Tab controller to handle tab switching
  late TabController _tabController;
  
  // Currently selected time period index
  int _selectedTimeIndex = 0;
  final List<String> _timePeriods = ["Current Week", "Last Week", "Last Month"];
  
  // Progress values for all time periods
  final List<double> _progressValues = [0.64, 0.40, 0.90];
  
  // Sample data - in a real app, this would come from an API or database
  final List<List<double>> _currentWeekData = [
    [20, 45, 30, 60, 40, 75, 50],  // Activity 1
    [15, 35, 25, 55, 30, 70, 40],  // Activity 2
  ];
  
  final List<List<double>> _lastWeekData = [
    [25, 40, 35, 50, 45, 65, 55],  // Activity 1
    [20, 30, 25, 45, 35, 60, 50],  // Activity 2
  ];
  
  final List<List<double>> _lastMonthData = [
    [30, 50, 40, 70, 60, 80, 65],  // Activity 1
    [25, 45, 35, 65, 55, 75, 60],  // Activity 2
  ];
  
  // Data currently being displayed
  late List<List<double>> _currentDisplayData;

  @override
  void initState() {
    super.initState();
    // Initialize the tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _currentDisplayData = _currentWeekData; // Start with current week data
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed
    _tabController.dispose();
    super.dispose();
  }

  // Handle tab changes
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTimeIndex = _tabController.index;
        // Update displayed data based on selected tab
        switch (_selectedTimeIndex) {
          case 0:
            _currentDisplayData = _currentWeekData;
            break;
          case 1:
            _currentDisplayData = _lastWeekData;
            break;
          case 2:
            _currentDisplayData = _lastMonthData;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Choose colors based on currently selected time period
    final List<Color> progressColors = [
      Colors.green.shade400,
      Colors.red.shade400,
      Colors.purple.shade400,
    ];

    return Scaffold(
      // Restored original app bar
      appBar: MedRhythmsAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              "Records",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),

          // Tab bar for time period selection
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: progressColors[_selectedTimeIndex],
            tabs: _timePeriods.map((period) => Tab(text: period)).toList(),
          ),

          const SizedBox(height: 20),

          // Circular progress indicators section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRadialGauge(
                _progressValues[0],
                "${(_progressValues[0] * 100).toInt()}%",
                progressColors[0],
                title: "Activity 1",
              ),
              _buildRadialGauge(
                _progressValues[1],
                "${(_progressValues[1] * 100).toInt()}%",
                progressColors[1],
                title: "Activity 2",
              ),
              _buildRadialGauge(
                _progressValues[2],
                "${(_progressValues[2] * 100).toInt()}%",
                progressColors[2],
                title: "Overall",
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart area - using TabBarView to show different time period data
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBarChartView(_currentWeekData),
                _buildBarChartView(_lastWeekData),
                _buildBarChartView(_lastMonthData),
              ],
            ),
          ),

          // Restored original bottom navigation bar
          bb,
        ],
      ),
    );
  }

  // Create an enhanced radial gauge (circular progress) widget
  Widget _buildRadialGauge(double value, String label, Color color, {String? title}) {
    return Column(
      children: [
        // Optional title above the gauge
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        Container(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular gauge from the geekyants package
              RadialGauge(
                track: RadialTrack(
                  start: 0,
                  end: 100,
                  thickness: 10,
                  color: Colors.grey.shade200,
                  hideTrack: false,
                  startAngle: 0,
                  endAngle: 360,
                  trackStyle: TrackStyle(
                    showPrimaryRulers: false,
                    showSecondaryRulers: false,
                    showLabel: false,
                  ),
                ),
                valueBar: [
                  // Main progress bar
                  RadialValueBar(
                    value: value * 100,
                    color: color,
                    valueBarThickness: 10,
                    radialOffset: 0,
                  ),
                ],
              ),
              // Center text and icon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  // Optional: Add small icon
                  Icon(
                    _getIconForProgress(value),
                    size: 16,
                    color: color.withOpacity(0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build bar chart view for a specific time period
  Widget _buildBarChartView(List<List<double>> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart legend
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Row(
                children: [
                  _buildLegendItem(Colors.grey.shade400, "Activity 1"),
                  const SizedBox(width: 20),
                  _buildLegendItem(Colors.red.shade200, "Activity 2"),
                ],
              ),
            ),
            // Bar chart
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) => _buildBarGroup(index, data)),
              ),
            ),
            const SizedBox(height: 8),
            // Day labels (Monday to Sunday)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                7,
                (index) => SizedBox(
                  width: 30,
                  child: Text(
                    _getDayLabel(index),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create a legend item with color box and label
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // Build a group of two bars for the chart
  Widget _buildBarGroup(int index, List<List<double>> data) {
    // Check if data index is valid
    if (data.isEmpty || data[0].length <= index || data[1].length <= index) {
      return const SizedBox.shrink();
    }

    // Calculate bar heights
    final double maxHeight = 180;
    final double firstBarHeight = maxHeight * (data[0][index] / 100);
    final double secondBarHeight = maxHeight * (data[1][index] / 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // First activity bar
          Container(
            width: 12,
            height: firstBarHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Second activity bar
          Container(
            width: 12,
            height: secondBarHeight,
            decoration: BoxDecoration(
              color: Colors.red.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get day label for the week
  String _getDayLabel(int index) {
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[index];
  }

  // Choose icon based on progress value
  IconData _getIconForProgress(double value) {
    if (value >= 0.7) return Icons.trending_up;      // Good progress
    if (value >= 0.4) return Icons.trending_flat;    // Average progress
    return Icons.trending_down;                      // Low progress
  }
}
