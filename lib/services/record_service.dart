import 'package:cloud_firestore/cloud_firestore.dart';

class RecordService {
  final CollectionReference sessionColl = FirebaseFirestore.instance.collection(
    'sessions',
  );

  Future<Map<String, dynamic>> getWorkoutRecord(
    String userId,
    DateTime startDate,
  ) async {
    try {
      // Set startDate to the start time of the day
      DateTime startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );

      // Set endDate to the end of the day
      DateTime endDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        23,
        59,
        59,
      );

      userId = "ae76c641-1c07-421e-9934-9f38f72a94e7";

      /**print(
        "####################################Getting Data for $userId on $startDate ############################",
      );**/

      QuerySnapshot snapshot =
          await sessionColl
              .where('userId', isEqualTo: userId)
              //.where('startTime', isGreaterThanOrEqualTo: startDateTime)
              //.where('endTime', isLessThanOrEqualTo: endDateTime)
              .get();

      print("###############################Snapshot: ${snapshot.docs.length}");

      if (snapshot.docs.isEmpty) {
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

      // Calculate population statistics
      double totalSteps = 0.0;
      double totalCalories = 0.0;
      double totalDistance = 0.0;
      double totalSpeed = 0.0;
      int sessionCount = 0;

      // Initialize hourly data array
      List<double> hourlyData = List.generate(24, (_) => 0.0);

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        totalSteps += ((data['totalSteps'] ?? 0) as num).toDouble();
        totalCalories += ((data['calories'] ?? 0) as num).toDouble();
        totalDistance += ((data['distance'] ?? 0) as num).toDouble();
        totalSpeed += ((data['speed'] ?? 0) as num).toDouble();
        sessionCount++;

        DateTime startTime = (data['startTime'] as Timestamp).toDate();

        // Accumulate hourly data for steps
        hourlyData[startTime.hour] +=
            ((data['totalSteps'] ?? 0) as num).toDouble();
      }

      // Calculate average speed
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
