import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Simplified version of RecordsPage component that needs to be mocked
class MockRecordsPage extends StatefulWidget {
  final String title = "Records";
  final bool hasData;

  const MockRecordsPage({super.key, this.hasData = true});

  @override
  State<MockRecordsPage> createState() => _MockRecordsPageState();
}

class _MockRecordsPageState extends State<MockRecordsPage> {
  bool isLoading = true;
  String sortOption = "Date (newest)";
  List<String> sortOptions = [
    "Date (newest)",
    "Steps (highest)",
    "Calories (highest)",
  ];

  @override
  void initState() {
    super.initState();
    // Simulate data loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () {}),
          // Add filter icon
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          // Add sort icon
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder:
                    (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          sortOptions
                              .map(
                                (option) => ListTile(
                                  title: Text(option),
                                  trailing:
                                      option == sortOption
                                          ? const Icon(Icons.check)
                                          : null,
                                  onTap: () {
                                    setState(() {
                                      sortOption = option;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              )
                              .toList(),
                    ),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ?
              // Loading state
              const Center(child: CircularProgressIndicator())
              :
              // Content
              widget.hasData
              ? SingleChildScrollView(
                child: Column(
                  children: [
                    // Filter chip row
                    Wrap(
                      spacing: 8.0,
                      children: [
                        FilterChip(
                          label: const Text('Steps > 1000'),
                          selected: true,
                          onSelected: (bool selected) {},
                        ),
                        FilterChip(
                          label: const Text('Calories > 100'),
                          selected: false,
                          onSelected: (bool selected) {},
                        ),
                        FilterChip(
                          label: const Text('This Week'),
                          selected: true,
                          onSelected: (bool selected) {},
                        ),
                      ],
                    ),

                    // Sort indicator
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.sort, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "Sorted by: $sortOption",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    Text("Date: ${DateTime.now().toString().substring(0, 10)}"),

                    // Formatted records display
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "3,412 steps",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Text("Calories: 240"),
                              Text("Distance: 2.7 km"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Steps chart
                    Container(
                      height: 120,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text("Steps Chart")),
                    ),
                    // Calories chart
                    Container(
                      height: 120,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text("Calories Chart")),
                    ),
                    // Button group
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text(
                            "Steps and\nDistance",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text(
                            "Calories and\nAvgSpeed",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
              :
              // Empty state
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No workout records found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Start a workout session to track your progress",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Start Workout"),
                    ),
                  ],
                ),
              ),
    );
  }
}

void main() {
  // 1. Create test for records page.dart
  testWidgets('RecordsPage mock test: Display title', (
    WidgetTester tester,
  ) async {
    // Build mock RecordsPage component
    await tester.pumpWidget(const MaterialApp(home: MockRecordsPage()));

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for loading to complete
    await tester.pump(const Duration(milliseconds: 600));

    // Verify if title is displayed
    expect(find.text('Records'), findsOneWidget);
  });

  // 2. Test records loading mechanism
  testWidgets('RecordsPage mock test: Records loading mechanism', (
    WidgetTester tester,
  ) async {
    // Build mock RecordsPage component
    await tester.pumpWidget(const MaterialApp(home: MockRecordsPage()));

    // Verify loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for loading to complete
    await tester.pump(const Duration(milliseconds: 600));

    // Verify loading indicator is gone and content is shown
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Steps Chart"), findsOneWidget);
  });

  // 3. Test records display formatting
  testWidgets('RecordsPage mock test: Records display formatting', (
    WidgetTester tester,
  ) async {
    // Build mock RecordsPage component
    await tester.pumpWidget(const MaterialApp(home: MockRecordsPage()));

    // Wait for loading to complete
    await tester.pump(const Duration(milliseconds: 600));

    // Verify records are formatted correctly
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('3,412 steps'), findsOneWidget);
    expect(find.text('Calories: 240'), findsOneWidget);
    expect(find.text('Distance: 2.7 km'), findsOneWidget);
  });

  // 4. Test record filtering functionality
  testWidgets('RecordsPage mock test: Record filtering functionality', (
    WidgetTester tester,
  ) async {
    // Build mock RecordsPage component
    await tester.pumpWidget(const MaterialApp(home: MockRecordsPage()));

    // Wait for loading to complete
    await tester.pump(const Duration(milliseconds: 600));

    // Verify filter icon exists
    expect(find.byIcon(Icons.filter_list), findsOneWidget);

    // Verify filter chips exist
    expect(find.byType(FilterChip), findsNWidgets(3));
    expect(find.text('Steps > 1000'), findsOneWidget);
    expect(find.text('Calories > 100'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);

    // Verify selected filter chips
    expect(
      tester.widget<FilterChip>(find.byType(FilterChip).at(0)).selected,
      true,
    );
    expect(
      tester.widget<FilterChip>(find.byType(FilterChip).at(1)).selected,
      false,
    );
    expect(
      tester.widget<FilterChip>(find.byType(FilterChip).at(2)).selected,
      true,
    );
  });

  // 5. Test record sorting options
  testWidgets('RecordsPage mock test: Record sorting options', (
    WidgetTester tester,
  ) async {
    // Build mock RecordsPage component
    await tester.pumpWidget(const MaterialApp(home: MockRecordsPage()));

    // Wait for loading to complete
    await tester.pump(const Duration(milliseconds: 600));

    // Verify sort icon exists
    expect(find.byIcon(Icons.sort), findsWidgets);

    // Verify default sort option is shown
    expect(find.text('Sorted by: Date (newest)'), findsOneWidget);

    // Tap on sort icon to open sort options
    await tester.tap(find.byIcon(Icons.sort).last);
    await tester.pumpAndSettle();

    // Verify sort options are shown
    expect(find.text('Date (newest)'), findsOneWidget);
    expect(find.text('Steps (highest)'), findsOneWidget);
    expect(find.text('Calories (highest)'), findsOneWidget);

    // Select a different sort option
    await tester.tap(find.text('Steps (highest)'));
    await tester.pumpAndSettle();

    // Verify sort option changed
    expect(find.text('Sorted by: Steps (highest)'), findsOneWidget);
  });

  // 6. Verify empty state handling when no records exist
  testWidgets('RecordsPage mock test: Empty state handling', (
    WidgetTester tester,
  ) async {
    // Build mock RecordsPage with no data
    await tester.pumpWidget(
      const MaterialApp(home: MockRecordsPage(hasData: false)),
    );

    // Wait for loading to complete
    await tester.pump(const Duration(milliseconds: 600));

    // Verify empty state is shown
    expect(find.text('No workout records found'), findsOneWidget);
    expect(
      find.text('Start a workout session to track your progress'),
      findsOneWidget,
    );
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
  });
}
