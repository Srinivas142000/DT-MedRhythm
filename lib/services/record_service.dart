import 'package:cloud_firestore/cloud_firestore.dart';

class RecordService {
  final CollectionReference sessionColl = FirebaseFirestore.instance.collection(
    'sessions',
  );

  Future<Map<String, dynamic>> getWorkoutRecord(
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
              .get();

      if (snapshot.docs.isEmpty) {
        return {}; // no data found
      }

      // calculate total steps, calories, distance, speed, and session count
      double totalSteps = 0;
      double totalCalories = 0;
      double totalDistance = 0;
      double totalSpeed = 0;
      int sessionCount = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalSteps += (data['totalSteps'] ?? 0) as double;
        totalCalories += (data['calories'] ?? 0) as double;
        totalDistance += (data['distance'] ?? 0) as double;
        totalSpeed += (data['speed'] ?? 0) as double;
        sessionCount++;
      }

      // calculate average speed
      double avgSpeed = sessionCount > 0 ? totalSpeed / sessionCount : 0;

      // return the calculated data
      return {
        "userId": userId,
        "startDate": startDate.toString(),
        "endDate": endDate.toString(),
        "totalSteps": totalSteps,
        "totalCalories": totalCalories,
        "totalDistance": totalDistance,
        "averageSpeed": avgSpeed,
      };
    } catch (e) {
      print("Error getting workout record: $e");
      return {
        "error": e.toString(),
        "userId": userId,
        "startDate": startDate.toString(),
        "endDate": endDate.toString(),
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
