import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/constants/constants.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:math';

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

  final CollectionReference sessionColl = FirebaseFirestore.instance.collection(
    'sessions',
  );
  final CollectionReference imeiColl = FirebaseFirestore.instance.collection(
    'imeis',
  );

  final UserSession userSession = UserSession();

  // final List<String> availableUserIds = [
  //   "f504bb88-4a1e-4f08-b52b-c5c82b8bd6d7",
  //   "b08b47d1-2d48-4e24-8efb-7750c211b387",
  //   "b5316d59-f6e8-4e1e-8550-8276d1c49c9f",
  //   "5b43683b-389a-4703-8d18-596181b5703e",
  //   "2cb65468-dd00-4cad-848e-a5a557f70893",
  //   "50233af8-2afe-41a9-9ac6-30dbd66ddbbb",
  //   "967ca63b-08a9-4fd1-9977-55ed02ccb29c",
  //   "5750926c-4388-4f55-b9de-f61ed7973a22",
  //   "4d877156-1aee-484f-9354-72a268a2629b",
  //   "dd206dc4-6d38-49c0-a877-d1c0cfc9f09d",
  // ];

  @override
  void initState() {
    super.initState();
    try {
      userSession.userId = widget.uuid;

      // Add comprehensive debugging
      print('============ INITIALIZATION DEBUG ============');
      print('Widget UUID: ${widget.uuid}');
      print('User data: ${widget.userData}');

      _showMyData(widget.userData);
      // Test direct Firebase connection
      _testFirebaseConnection();

      // _findUserByIMEI();
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  Future<void> _showMyData(Map<String, dynamic> userData) async {
    try {
      print('Displaying user data in graphs:');
      userData.forEach((key, value) {
        print('$key: $value');
      });

      // Example: Update weekData with userData for graph display
      if (userData.containsKey('weeklyMetrics')) {
        List<dynamic> weeklyMetrics = userData['weeklyMetrics'];
        for (int i = 0; i < weeklyMetrics.length && i < 7; i++) {
          weekData[i] = weeklyMetrics[i] as Map<String, dynamic>?;
        }
        setState(() {
          selectedDay = DateTime.now().weekday - 1;
        });
      }
    } catch (e) {
      print('Error displaying user data in graphs: $e');
    }
  }

  Future<void> _testFirebaseConnection() async {
    try {
      print('Testing direct Firebase connection...');

      // Test direct access to collections
      final imeiSnapshot = await imeiColl.limit(1).get();
      print('Can access imeis collection: ${imeiSnapshot.docs.isNotEmpty}');

      final sessionsSnapshot = await sessionColl.limit(5).get();
      print(
        'Can access sessions collection: ${sessionsSnapshot.docs.isNotEmpty}',
      );
      if (sessionsSnapshot.docs.isNotEmpty) {
        print('Sample session document:');
        final sampleDoc =
            sessionsSnapshot.docs.first.data() as Map<String, dynamic>;
        sampleDoc.forEach((key, value) {
          print('  $key: $value');
        });
      }

      // Test with hardcoded values known to work from your screenshots
      print('Attempting direct query for known IMEI: 123456789123456');
      final specificImei = await imeiColl.doc('123456789123456').get();
      print('IMEI document exists: ${specificImei.exists}');

      if (specificImei.exists) {
        final imeiData = specificImei.data() as Map<String, dynamic>?;
        final userId = imeiData?['userId'];
        print('User ID from IMEI: $userId');

        if (userId != null) {
          // Query sessions with this user ID
          final sessionsQuery =
              await sessionColl
                  .where('userId', isEqualTo: userId)
                  .limit(10)
                  .get();

          print(
            'Found ${sessionsQuery.docs.length} sessions for user ID: $userId',
          );

          // Print session dates
          if (sessionsQuery.docs.isNotEmpty) {
            print('Session dates:');
            for (var doc in sessionsQuery.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('startTime')) {
                final startTime =
                    data['startTime'] is Timestamp
                        ? (data['startTime'] as Timestamp).toDate()
                        : DateTime.parse(data['startTime'].toString());
                print('  Session date: $startTime');
              }
            }
          }

          // Try to get data for a specific date
          final specificDate = DateTime(2025, 3, 28);
          print('Querying data for specific date: $specificDate');

          final startOfDay = DateTime(
            specificDate.year,
            specificDate.month,
            specificDate.day,
            0,
            0,
            0,
          );
          final endOfDay = DateTime(
            specificDate.year,
            specificDate.month,
            specificDate.day,
            23,
            59,
            59,
          );

          final dayQuery =
              await sessionColl
                  .where('userId', isEqualTo: userId)
                  .where('startTime', isGreaterThanOrEqualTo: startOfDay)
                  .where('endTime', isLessThanOrEqualTo: endOfDay)
                  .get();

          print(
            'Found ${dayQuery.docs.length} sessions for date: $specificDate',
          );

          // Test variation: try different date format or range
          final alternateStartDay = DateTime(
            specificDate.year,
            specificDate.month,
            specificDate.day,
          );
          final alternateEndDay = DateTime(
            specificDate.year,
            specificDate.month,
            specificDate.day + 1,
          );

          final alternateQuery =
              await sessionColl
                  .where('userId', isEqualTo: userId)
                  .where('startTime', isGreaterThanOrEqualTo: alternateStartDay)
                  .where('endTime', isLessThan: alternateEndDay)
                  .get();

          print(
            'Alternative query found ${alternateQuery.docs.length} sessions',
          );

          // Try without date filtering
          final noDateQuery =
              await sessionColl.where('userId', isEqualTo: userId).get();

          print(
            'Query without date filters found ${noDateQuery.docs.length} sessions',
          );

          if (noDateQuery.docs.isNotEmpty) {
            // Analyze the date formats in the database
            final sampleSession =
                noDateQuery.docs.first.data() as Map<String, dynamic>;
            print('Sample session:');
            sampleSession.forEach((key, value) {
              print('  $key: ${value} (type: ${value.runtimeType})');
            });

            if (sampleSession.containsKey('startTime')) {
              final startTime = sampleSession['startTime'];
              print('Start time type: ${startTime.runtimeType}');
              if (startTime is Timestamp) {
                print('Start time as DateTime: ${startTime.toDate()}');
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      print('Firebase connection test error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Future<void> _findUserByIMEI() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     // Get IMEI from user data
  //     String? imei = widget.userData['imei'] as String?;
  //     print('Searching for user ID with IMEI: $imei');

  //     if (imei != null && imei.isNotEmpty) {
  //       // Query Firestore to get the user ID associated with the IMEI
  //       String? userId = await _findUserIdByIMEI(imei);

  //       if (userId != null && userId.isNotEmpty) {
  //         print('Found matching userId for IMEI $imei: $userId');
  //         userSession.userId = userId;

  //         // Find latest session date for this user instead of hardcoded dates
  //         DateTime? latestSessionDate = await _findLatestSessionDate(userId);

  //         if (latestSessionDate != null) {
  //           print(
  //             'Found latest session date for userId $userId: $latestSessionDate',
  //           );
  //           // Get data for the week containing the latest session
  //           await _fetchSpecificDateData(userId, latestSessionDate);
  //         } else {
  //           print(
  //             'No sessions found for userId $userId, fetching current week data',
  //           );
  //           // If no session data found, get current week data
  //           await _fetchWeekDataWithUserId(userId);
  //         }

  //         // Set up realtime listener for this specific user
  //         _setupSessionListenerForUser(userId);
  //         return;
  //       } else {
  //         print('No userId found for IMEI: $imei in any collection');
  //       }
  //     } else {
  //       print(
  //         'No IMEI provided in user data, falling back to uuid: ${widget.uuid}',
  //       );
  //     }

  // If no user ID was found by IMEI, try with available user IDs
  //   await _fetchWeekData();
  //   _setupLiveSessionListener();
  // } catch (e) {
  //   print('Error finding user by IMEI: $e');
  //   // Fallback to original method if error occurs
  //   await _fetchWeekData();
  //   _setupLiveSessionListener();
  // } finally {
  //   setState(() {
  //     isLoading = false;
  //   });
  //   }
  // }

  // Find user ID by IMEI
  Future<String?> _findUserIdByIMEI(String imei) async {
    try {
      // First try to find in imeis collection
      final imeiDoc = await imeiColl.doc(imei).get();
      if (imeiDoc.exists) {
        final imeiData = imeiDoc.data() as Map<String, dynamic>?;
        String? userId = imeiData?['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          print('Found userId in imei collection: $userId for IMEI: $imei');
          return userId;
        }
      }

      // If not found in imeis collection, try users collection
      print(
        'No document found in imeis collection for IMEI: $imei, trying users collection',
      );
      final usersQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('imei', isEqualTo: imei)
              .limit(1)
              .get();

      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data();
        String? userId = userData['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          print('Found userId in users collection: $userId for IMEI: $imei');
          return userId;
        }
      }

      return null;
    } catch (e) {
      print('Error finding userId by IMEI: $e');
      return null;
    }
  }

  // Find the latest session date for a user
  Future<DateTime?> _findLatestSessionDate(String userId) async {
    try {
      // Query sessions ordered by end time, descending, to get the most recent
      final querySnapshot =
          await sessionColl
              .where('userId', isEqualTo: userId)
              .orderBy('endTime', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        var sessionData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (sessionData.containsKey('endTime')) {
          try {
            if (sessionData['endTime'] is Timestamp) {
              return (sessionData['endTime'] as Timestamp).toDate();
            } else {
              return DateTime.parse(sessionData['endTime'].toString());
            }
          } catch (e) {
            print('Error parsing session date: $e');
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error finding latest session date: $e');
      return null;
    }
  }

  void _setupSessionListenerForUser(String userId) {
    print('Setting up listener for specific userId: $userId');

    sessionColl.where('userId', isEqualTo: userId).snapshots().listen((
      snapshot,
    ) {
      print(
        'Received snapshot with ${snapshot.docs.length} documents for userId: $userId',
      );
      if (snapshot.docs.isNotEmpty) {
        _fetchWeekDataWithUserId(userId);
      }
    });
  }

  // void _setupLiveSessionListener() {
  //   print('Setting up listener for all available userIds');

  //   for (var userId in availableUserIds) {
  //     sessionColl.where('userId', isEqualTo: userId).snapshots().listen((
  //       snapshot,
  //     ) {
  //       print(
  //         'Received snapshot with ${snapshot.docs.length} documents for userId: $userId',
  //       );
  //       if (snapshot.docs.isNotEmpty) {
  //         _fetchWeekDataWithUserId(userId);
  //       }
  //     });
  //   }
  // }

  Future<void> _fetchWeekDataWithUserId(String userId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      final int currentWeekday = now.weekday;

      final mondayDate = now.subtract(Duration(days: currentWeekday - 1));

      weekData = List.filled(7, null);

      print('Fetching data for userId: $userId');
      print('Fetching data for the week starting: $mondayDate');

      for (int i = 0; i < 7; i++) {
        final date = mondayDate.add(Duration(days: i));

        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day + 1);

        print('Querying day $i: $date with userId: $userId');

        final querySnapshot =
            await sessionColl
                .where('userId', isEqualTo: userId)
                .where('startTime', isGreaterThanOrEqualTo: startOfDay)
                .where('endTime', isLessThanOrEqualTo: endOfDay)
                .get();

        print(
          'Query results for day $i: ${querySnapshot.docs.length} documents',
        );

        if (querySnapshot.docs.isNotEmpty) {
          double totalSteps = 0;
          double totalCalories = 0;
          double totalDistance = 0;
          double totalDurationInHours = 0;
          int sessionCount = 0;

          for (var doc in querySnapshot.docs) {
            var sessionData = doc.data() as Map<String, dynamic>;
            print('Found session data: ${sessionData}');

            if (sessionData.containsKey('totalSteps')) {
              var steps = sessionData['totalSteps'];
              totalSteps += (steps is int) ? steps.toDouble() : (steps ?? 0);
            } else {
              print('Warning: Session data missing totalSteps field');
            }

            if (sessionData.containsKey('calories')) {
              var calories = sessionData['calories'];
              totalCalories +=
                  (calories is int) ? calories.toDouble() : (calories ?? 0);
            } else {
              print('Warning: Session data missing calories field');
            }

            if (sessionData.containsKey('distance')) {
              var distance = sessionData['distance'];
              totalDistance +=
                  (distance is int) ? distance.toDouble() : (distance ?? 0);
            } else {
              print('Warning: Session data missing distance field');
            }

            if (sessionData.containsKey('startTime') &&
                sessionData.containsKey('endTime')) {
              try {
                DateTime startTime;
                DateTime endTime;

                if (sessionData['startTime'] is Timestamp) {
                  startTime = (sessionData['startTime'] as Timestamp).toDate();
                } else {
                  startTime = DateTime.parse(
                    sessionData['startTime'].toString(),
                  );
                }

                if (sessionData['endTime'] is Timestamp) {
                  endTime = (sessionData['endTime'] as Timestamp).toDate();
                } else {
                  endTime = DateTime.parse(sessionData['endTime'].toString());
                }

                Duration duration = endTime.difference(startTime);
                double durationInHours = duration.inSeconds / 3600;
                totalDurationInHours += durationInHours;

                print(
                  'Session duration: ${durationInHours.toStringAsFixed(2)} hours',
                );
              } catch (e) {
                print('Error calculating session duration: $e');
              }
            }

            sessionCount++;
          }

          double averageSpeed = 0;
          if (totalDistance > 0 && totalDurationInHours > 0) {
            averageSpeed = totalDistance / totalDurationInHours;
            print(
              'Calculated average speed: ${averageSpeed.toStringAsFixed(2)} mph (distance: $totalDistance mi, duration: ${totalDurationInHours.toStringAsFixed(2)} hours)',
            );
          } else {
            print(
              'Could not calculate average speed: distance=$totalDistance, duration=$totalDurationInHours',
            );
          }

          weekData[i] = {
            'totalSteps': totalSteps,
            'totalCalories': totalCalories,
            'totalDistance': totalDistance,
            'averageSpeed': averageSpeed,
            'date': date,
          };
        } else {
          weekData[i] = {
            'totalSteps': 0.0,
            'totalCalories': 0.0,
            'totalDistance': 0.0,
            'averageSpeed': 0.0,
            'date': date,
          };
        }

        print('Final data for $date: ${weekData[i]}');
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

  // Future<void> _fetchWeekData() async {
  //   print(
  //     'Attempting to fetch week data with available user IDs: $availableUserIds',
  //   );
  //   for (var userId in availableUserIds) {
  //     print('Trying userId: $userId');
  //     await _fetchWeekDataWithUserId(userId);

  //     bool hasData = weekData.any(
  //       (day) =>
  //           (day?['totalSteps'] ?? 0) > 0 ||
  //           (day?['totalCalories'] ?? 0) > 0 ||
  //           (day?['totalDistance'] ?? 0) > 0,
  //     );

  //     if (hasData) {
  //       print('Found data with userId: $userId');
  //       userSession.userId = userId;
  //       break;
  //     } else {
  //       print('No data found for userId: $userId');
  //     }
  //   }

  //   print('Final week data for display:');
  //   for (int i = 0; i < weekData.length; i++) {
  //     print('Day $i: ${weekData[i]}');
  //   }
  // }

  Future<void> _fetchSpecificDateData(
    String userId,
    DateTime specificDate,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      print(
        'Fetching specific date data for userId: $userId, date: $specificDate',
      );

      // Reset week data
      weekData = List.filled(7, null);

      // Calculate day of week (0-6)
      final dayIndex = specificDate.weekday - 1;

      // Get Monday of the week containing specificDate
      final mondayDate = specificDate.subtract(
        Duration(days: specificDate.weekday - 1),
      );

      print(
        'Week starts on: $mondayDate (specific date is day $dayIndex of week)',
      );

      // Fill data for all days in the week
      for (int i = 0; i < 7; i++) {
        final date = mondayDate.add(Duration(days: i));
        // Use more flexible date range
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day + 1);

        // Special handling for target date
        if (i == dayIndex) {
          print('Querying specific day: $date with userId: $userId');

          // Try simplified query first - debug only startTime filter
          print('DEBUG: Testing query with only userId filter');
          final simpleQuery =
              await sessionColl.where('userId', isEqualTo: userId).get();
          print('Simple query found ${simpleQuery.docs.length} documents');

          // Try specific query
          print('DEBUG: Testing query with userId + date filters');
          final querySnapshot =
              await sessionColl
                  .where('userId', isEqualTo: userId)
                  .where('startTime', isGreaterThanOrEqualTo: startOfDay)
                  .where('endTime', isLessThanOrEqualTo: endOfDay)
                  .get();

          print(
            'Query results for specific day: ${querySnapshot.docs.length} documents',
          );

          if (querySnapshot.docs.isNotEmpty) {
            // Process data (same as original method)
            double totalSteps = 0;
            double totalCalories = 0;
            double totalDistance = 0;
            double totalDurationInHours = 0;

            for (var doc in querySnapshot.docs) {
              var sessionData = doc.data() as Map<String, dynamic>;
              print('Found session data: ${sessionData}');

              if (sessionData.containsKey('totalSteps')) {
                var steps = sessionData['totalSteps'];
                totalSteps += (steps is int) ? steps.toDouble() : (steps ?? 0);
              }

              if (sessionData.containsKey('calories')) {
                var calories = sessionData['calories'];
                totalCalories +=
                    (calories is int) ? calories.toDouble() : (calories ?? 0);
              }

              if (sessionData.containsKey('distance')) {
                var distance = sessionData['distance'];
                totalDistance +=
                    (distance is int) ? distance.toDouble() : (distance ?? 0);
              }

              if (sessionData.containsKey('startTime') &&
                  sessionData.containsKey('endTime')) {
                try {
                  DateTime startTime;
                  DateTime endTime;

                  if (sessionData['startTime'] is Timestamp) {
                    startTime =
                        (sessionData['startTime'] as Timestamp).toDate();
                  } else {
                    startTime = DateTime.parse(
                      sessionData['startTime'].toString(),
                    );
                  }

                  if (sessionData['endTime'] is Timestamp) {
                    endTime = (sessionData['endTime'] as Timestamp).toDate();
                  } else {
                    endTime = DateTime.parse(sessionData['endTime'].toString());
                  }

                  Duration duration = endTime.difference(startTime);
                  double durationInHours = duration.inSeconds / 3600;
                  totalDurationInHours += durationInHours;
                } catch (e) {
                  print('Error calculating session duration: $e');
                }
              }
            }

            double averageSpeed = 0;
            if (totalDistance > 0 && totalDurationInHours > 0) {
              averageSpeed = totalDistance / totalDurationInHours;
            }

            // Save data for the day
            weekData[i] = {
              'totalSteps': totalSteps,
              'totalCalories': totalCalories,
              'totalDistance': totalDistance,
              'averageSpeed': averageSpeed,
              'date': date,
            };

            print('Data for date $date: ${weekData[i]}');
          } else {
            // If no data found, try fallback to simpler query results
            print(
              'No data found with date filters, trying to use data from simple query',
            );

            if (simpleQuery.docs.isNotEmpty) {
              double totalSteps = 0;
              double totalCalories = 0;
              double totalDistance = 0;

              for (var doc in simpleQuery.docs) {
                var sessionData = doc.data() as Map<String, dynamic>;
                if (sessionData.containsKey('totalSteps')) {
                  totalSteps +=
                      (sessionData['totalSteps'] is int)
                          ? (sessionData['totalSteps'] as int).toDouble()
                          : (sessionData['totalSteps'] ?? 0);
                }

                if (sessionData.containsKey('calories')) {
                  totalCalories +=
                      (sessionData['calories'] is int)
                          ? (sessionData['calories'] as int).toDouble()
                          : (sessionData['calories'] ?? 0);
                }

                if (sessionData.containsKey('distance')) {
                  totalDistance +=
                      (sessionData['distance'] is int)
                          ? (sessionData['distance'] as int).toDouble()
                          : (sessionData['distance'] ?? 0);
                }
              }

              // If we found any data, use it for testing purposes
              if (totalSteps > 0 || totalCalories > 0 || totalDistance > 0) {
                print('Using data from simple query as fallback');
                weekData[i] = {
                  'totalSteps': totalSteps,
                  'totalCalories': totalCalories,
                  'totalDistance': totalDistance,
                  'averageSpeed': 0.0,
                  'date': date,
                };
              } else {
                // If no data for the day, create empty record
                weekData[i] = {
                  'totalSteps': 0.0,
                  'totalCalories': 0.0,
                  'totalDistance': 0.0,
                  'averageSpeed': 0.0,
                  'date': date,
                };
              }
            } else {
              // If no data for the day, create empty record
              weekData[i] = {
                'totalSteps': 0.0,
                'totalCalories': 0.0,
                'totalDistance': 0.0,
                'averageSpeed': 0.0,
                'date': date,
              };
            }
          }
        } else {
          // Processing for non-specific dates (simplified)
          final querySnapshot =
              await sessionColl
                  .where('userId', isEqualTo: userId)
                  .where('startTime', isGreaterThanOrEqualTo: startOfDay)
                  .where('endTime', isLessThanOrEqualTo: endOfDay)
                  .get();

          if (querySnapshot.docs.isNotEmpty) {
            double totalSteps = 0;
            double totalCalories = 0;
            double totalDistance = 0;
            double totalDurationInHours = 0;

            for (var doc in querySnapshot.docs) {
              var sessionData = doc.data() as Map<String, dynamic>;

              if (sessionData.containsKey('totalSteps')) {
                var steps = sessionData['totalSteps'];
                totalSteps += (steps is int) ? steps.toDouble() : (steps ?? 0);
              }

              if (sessionData.containsKey('calories')) {
                var calories = sessionData['calories'];
                totalCalories +=
                    (calories is int) ? calories.toDouble() : (calories ?? 0);
              }

              if (sessionData.containsKey('distance')) {
                var distance = sessionData['distance'];
                totalDistance +=
                    (distance is int) ? distance.toDouble() : (distance ?? 0);
              }

              if (sessionData.containsKey('startTime') &&
                  sessionData.containsKey('endTime')) {
                try {
                  DateTime startTime;
                  DateTime endTime;

                  if (sessionData['startTime'] is Timestamp) {
                    startTime =
                        (sessionData['startTime'] as Timestamp).toDate();
                  } else {
                    startTime = DateTime.parse(
                      sessionData['startTime'].toString(),
                    );
                  }

                  if (sessionData['endTime'] is Timestamp) {
                    endTime = (sessionData['endTime'] as Timestamp).toDate();
                  } else {
                    endTime = DateTime.parse(sessionData['endTime'].toString());
                  }

                  Duration duration = endTime.difference(startTime);
                  double durationInHours = duration.inSeconds / 3600;
                  totalDurationInHours += durationInHours;
                } catch (e) {
                  print('Error calculating session duration: $e');
                }
              }
            }

            double averageSpeed = 0;
            if (totalDistance > 0 && totalDurationInHours > 0) {
              averageSpeed = totalDistance / totalDurationInHours;
            }

            weekData[i] = {
              'totalSteps': totalSteps,
              'totalCalories': totalCalories,
              'totalDistance': totalDistance,
              'averageSpeed': averageSpeed,
              'date': date,
            };
          } else {
            weekData[i] = {
              'totalSteps': 0.0,
              'totalCalories': 0.0,
              'totalDistance': 0.0,
              'averageSpeed': 0.0,
              'date': date,
            };
          }
        }

        print('Final data for $date: ${weekData[i]}');
      }

      // Set selected date to specific date
      _selectedDay = specificDate;
      _focusedDay = specificDate;
      selectedDate = specificDate;
      selectedDay = dayIndex;

      // Force rebuild to ensure UI updates
      setState(() {});
    } catch (e, stackTrace) {
      print('Error retrieving specific date records: $e');
      print('Stack trace: $stackTrace');
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
                        Row(
                          children: [
                            // Refresh button
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  String? userId = userSession.userId;

                                  if (userId != null && userId.isNotEmpty) {
                                    // Find latest session date
                                    DateTime? latestDate =
                                        await _findLatestSessionDate(userId);

                                    if (latestDate != null) {
                                      await _fetchSpecificDateData(
                                        userId,
                                        latestDate,
                                      );
                                    } else {
                                      await _fetchWeekDataWithUserId(userId);
                                    }
                                  } else if (widget.uuid.isNotEmpty) {
                                    await _fetchWeekDataWithUserId(widget.uuid);
                                  } else {
                                    // If no user ID available, try to find again
                                    // await _findUserByIMEI();
                                  }
                                } catch (e) {
                                  print('Error refreshing data: $e');
                                } finally {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_month),
                              onPressed: _toggleCalendarView,
                            ),
                          ],
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
    Map<String, dynamic>? dayData = weekData[selectedDay];

    if (dayData == null) {
      return LineChartData();
    }

    List<FlSpot> spots = [];
    double maxValue = 0;
    String unit;
    bool useIntegers = false;

    switch (metricType.toLowerCase()) {
      case "steps":
        maxValue =
            dayData['totalSteps'] != 0 ? (dayData['totalSteps'] * 1.2) : 10000;
        unit = "steps";
        useIntegers = true;
        break;
      case "calories":
        maxValue =
            dayData['totalCalories'] != 0
                ? (dayData['totalCalories'] * 1.2)
                : 1000;
        unit = "kcal";
        break;
      case "distance":
        maxValue =
            dayData['totalDistance'] != 0
                ? (dayData['totalDistance'] * 1.2)
                : 10.0;
        unit = "mi";
        break;
      case "avgspeed":
      case "average speed":
        unit = "mph";

        double speed = dayData['averageSpeed'] ?? 0;

        maxValue = 800.0;

        double baseSpeed = speed;

        print(
          'AvgSpeed value: $speed mph (displayed with fixed maxY: $maxValue)',
        );

        List<FlSpot> spots = [];
        Random random = Random(speed.toInt() + 42);

        for (int hour = 0; hour < 24; hour++) {
          double hourValue = baseSpeed;

          double variancePercent = 0.1;
          double variance = math.max(0.5, baseSpeed * variancePercent);

          double timeOfDayFactor = 1.0;

          if (hour >= 6 && hour <= 9) {
            timeOfDayFactor = 1.15;
          } else if (hour >= 12 && hour <= 14) {
            timeOfDayFactor = 0.9;
          } else if (hour >= 17 && hour <= 20) {
            timeOfDayFactor = 1.2;
          } else if (hour >= 22 || hour <= 5) {
            timeOfDayFactor = 0.8;
          }

          hourValue =
              hourValue * timeOfDayFactor +
              (random.nextDouble() - 0.5) * variance;

          hourValue = math.max(0, hourValue);

          spots.add(FlSpot(hour.toDouble(), hourValue));
        }

        double interval = 100.0;

        return _buildChartData(spots, color, interval, maxValue, false, unit);
      default:
        maxValue = 125;
        unit = "";
    }

    double interval;
    if (maxValue <= 10) {
      interval = 2.0;
    } else if (maxValue <= 50) {
      interval = 10.0;
    } else if (maxValue <= 100) {
      interval = 20.0;
    } else if (maxValue <= 500) {
      interval = 100.0;
    } else if (maxValue <= 1000) {
      interval = 200.0;
    } else if (maxValue <= 5000) {
      interval = 1000.0;
    } else if (maxValue <= 10000) {
      interval = 2000.0;
    } else {
      interval = 5000.0;
    }

    int tickCount = (maxValue / interval).ceil();
    if (tickCount < 3) {
      interval = maxValue / 5;
    } else if (tickCount > 10) {
      interval = maxValue / 8;
    }

    double totalValue = 0;
    switch (metricType.toLowerCase()) {
      case "steps":
        totalValue = dayData['totalSteps'] ?? 0;
        break;
      case "calories":
        totalValue = dayData['totalCalories'] ?? 0;
        break;
      case "distance":
        totalValue = dayData['totalDistance'] ?? 0;
        break;
    }

    if (totalValue > 0) {
      List<double> activityPattern = List.filled(24, 0.02);

      activityPattern[7] = 0.1;
      activityPattern[8] = 0.12;

      activityPattern[12] = 0.08;

      activityPattern[17] = 0.15;
      activityPattern[18] = 0.12;

      double sum = activityPattern.reduce((a, b) => a + b);
      for (int i = 0; i < activityPattern.length; i++) {
        activityPattern[i] = activityPattern[i] / sum;
      }

      double cumulativeValue = 0;
      for (int hour = 0; hour < 24; hour++) {
        double hourValue = totalValue * activityPattern[hour];
        cumulativeValue += hourValue;
        spots.add(FlSpot(hour.toDouble(), cumulativeValue));
      }
    } else {
      for (int hour = 0; hour < 24; hour++) {
        spots.add(FlSpot(hour.toDouble(), 0));
      }
    }

    return _buildChartData(spots, color, interval, maxValue, useIntegers, unit);
  }

  LineChartData _buildChartData(
    List<FlSpot> spots,
    Color color,
    double interval,
    double maxValue,
    bool useIntegers,
    String unit,
  ) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
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
            interval: 6,
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
            reservedSize: 40,
            interval: interval,
            getTitlesWidget: (value, meta) {
              String formattedValue;
              if (value >= 1000 && useIntegers) {
                formattedValue = "${(value / 1000).toStringAsFixed(1)}k";
              } else if (useIntegers) {
                formattedValue = value.toInt().toString();
              } else {
                if (value < 10) {
                  formattedValue = value.toStringAsFixed(1);
                } else {
                  formattedValue = value.toStringAsFixed(0);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  formattedValue,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 24,
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
          dotData: FlDotData(show: false),
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

  Future<void> _debugSpecificIMEI(String imei) async {
    print('Debug test for IMEI: $imei');

    // Direct query to check if IMEI exists in collections
    final imeiDoc = await imeiColl.doc(imei).get();
    print('IMEI document exists in imeis collection: ${imeiDoc.exists}');

    // Query sessions collection directly with a broader date range
    final usersQuery =
        await FirebaseFirestore.instance
            .collection('users')
            .where('imei', isEqualTo: imei)
            .get();

    print(
      'Found ${usersQuery.docs.length} documents in users collection for this IMEI',
    );

    if (usersQuery.docs.isNotEmpty) {
      final userData = usersQuery.docs.first.data() as Map<String, dynamic>;
      final userId = userData['userId'];
      print('User ID from query: $userId');

      // Query all sessions for this user ID
      final sessionsQuery =
          await sessionColl.where('userId', isEqualTo: userId).get();

      print('Found ${sessionsQuery.docs.length} sessions for this user ID');

      // Print the dates of a few sessions
      int count = 0;
      for (var doc in sessionsQuery.docs) {
        if (count < 5) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('startTime')) {
            final startTime =
                data['startTime'] is Timestamp
                    ? (data['startTime'] as Timestamp).toDate()
                    : DateTime.parse(data['startTime'].toString());
            print('Session date: $startTime');
          }
          count++;
        }
      }
    }
  }
}
