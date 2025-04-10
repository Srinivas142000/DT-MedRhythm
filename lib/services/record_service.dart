import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class RecordService {
  final CollectionReference sessionColl = FirebaseFirestore.instance.collection(
    'sessions',
  );

  Future<Map<String, dynamic>> getWorkoutRecord(
    String userId,
    DateTime startDate,
  ) async {
    try {
      DateTime startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );

      DateTime endDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        23,
        59,
        59,
      );

      print("Fetching data for date: $startDate, userId: $userId");
      
      QuerySnapshot snapshot =
          await sessionColl
              .where('userId', isEqualTo: userId)
              .where('startTime', isGreaterThanOrEqualTo: startDateTime)
              .where('endTime', isLessThanOrEqualTo: endDateTime)
              .get();

      print("Found ${snapshot.docs.length} records for this day");

      if (snapshot.docs.isEmpty) {
        bool isEmulator = true;
        
        if (isEmulator) {
          print("No data found, returning mock data for emulator");
          
          int weekday = startDate.weekday;
          double baseSteps = 5000 + (weekday * 500);
          double baseCalories = 120 + (weekday * 20);
          double baseDistance = 2.0 + (weekday * 0.3);
          
          List<double> hourlyData = List.generate(24, (hour) {
            if (hour >= 22 || hour <= 6) {
              return 0.0;
            } else if (hour >= 8 && hour <= 18) {
              return baseSteps / 10 * (1 + (math.sin(hour / 3) * 0.5));
            } else {
              return baseSteps / 20;
            }
          });
          
          return {
            "userId": userId,
            "date": startDate.toString(),
            "totalSteps": baseSteps,
            "totalCalories": baseCalories, 
            "totalDistance": baseDistance,
            "averageSpeed": baseDistance / 2.5,
            "hourlyData": hourlyData,
          };
        }
        
        return {
          "userId": userId,
          "date": startDate.toString(),
          "totalSteps": 0.0,
          "totalCalories": 0.0,
          "totalDistance": 0.0,
          "averageSpeed": 0.0,
          "hourlyData": List.generate(24, (_) => 0.0),
        };
      }

      double totalSteps = 0.0;
      double totalCalories = 0.0;
      double totalDistance = 0.0;
      double totalSpeed = 0.0;
      int sessionCount = 0;

      List<double> hourlyData = List.generate(24, (_) => 0.0);

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print("Processing data: $data");

        totalSteps += ((data['totalSteps'] ?? 0) as num).toDouble();
        totalCalories += ((data['calories'] ?? 0) as num).toDouble();
        totalDistance += ((data['distance'] ?? 0) as num).toDouble();
        totalSpeed += ((data['speed'] ?? 0) as num).toDouble();
        sessionCount++;

        DateTime startTime = (data['startTime'] as Timestamp).toDate();

        hourlyData[startTime.hour] +=
            ((data['totalSteps'] ?? 0) as num).toDouble();
      }

      double avgSpeed = sessionCount > 0.0 ? totalSpeed / sessionCount : 0.0;

      return {
        "userId": userId,
        "date": startDate.toString(),
        "totalSteps": totalSteps,
        "totalCalories": totalCalories,
        "totalDistance": totalDistance,
        "averageSpeed": avgSpeed,
        "hourlyData": hourlyData,
      };
    } catch (e) {
      print("Error getting workout record: $e");
      return {
        "userId": userId,
        "date": startDate.toString(),
        "error": e.toString(),
        "totalSteps": 0.0,
        "totalCalories": 0.0,
        "totalDistance": 0.0,
        "averageSpeed": 0.0,
        "hourlyData": List.generate(24, (_) => 0.0),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutSessions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot =
          await sessionColl
              .where('userId', isEqualTo: userId)
              .where('startTime', isGreaterThanOrEqualTo: startDate)
              .where('startTime', isLessThanOrEqualTo: endDate)
              .orderBy('startTime', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['startTime'] is Timestamp) {
          data['startTime'] = (data['startTime'] as Timestamp).toDate();
        }
        if (data['endTime'] is Timestamp) {
          data['endTime'] = (data['endTime'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      print("Error getting workout sessions: $e");
      return [];
    }
  }
}
