import 'package:cloud_firestore/cloud_firestore.dart';

class RecordService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getWorkoutRecord(
      String userId, DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // query the database for all sessions on the given date
    var querySnapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThanOrEqualTo: endOfDay)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // no data found
    }

    // calculate total steps, calories, distance, speed, and session count
    double totalSteps = 0;
    double totalCalories = 0;
    double totalDistance = 0;
    double totalSpeed = 0;
    int sessionCount = 0;

    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      totalSteps += (data['steps'] ?? 0) as double;
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
      "date": date.toIso8601String(),
      "totalSteps": totalSteps,
      "totalCalories": totalCalories,
      "totalDistance": totalDistance,
      "averageSpeed": avgSpeed,
    };
  }
}
