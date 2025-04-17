import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:medrhythms/helpers/usersession.dart';

/// A service class for reading user and session data from Firestore.
class FirestoreServiceRead {
  final FirebaseFirestore firestore;
  final CreateDataService csd;

  /// Constructor allows dependency injection of Firestore and CreateDataService.
  /// If not provided, defaults to production instances.
  FirestoreServiceRead({
    FirebaseFirestore? firestore,
    CreateDataService? createService,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       csd = createService ?? CreateDataService();

  /// Checks if a user exists in Firestore based on IMEI.
  /// If not, creates a new user document.
  Future<Map<String, dynamic>?> checkUserSessionRegistry(String imei) async {
    try {
      // Reference to the 'users' collection in Firestore
      var usersColl = firestore.collection('users');
      // Query Firestore for a user document with the given IMEI
      var querySnapshot = await usersColl.where('imei', isEqualTo: imei).get();

      if (querySnapshot.docs.isNotEmpty) {
        // If a user document exists, return its data
        var userDetails =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (userDetails.containsKey('userId')) {
          return userDetails;
        }
      } else {
        // If no user document exists, create one and retry
        await csd.createUserReference(imei);
        return checkUserSessionRegistry(imei);
      }
    } catch (e) {
      // Handle errors and return an error map
      print("Error occurred: $e");
      return {"error": e.toString()};
    }
  }

  /// Fetches session data for a user and returns aggregated results.
  Future<Map<String, dynamic>> fetchUserSessionData(
    String userId, {
    DateTime? startTime,
    DateTime? endTime,
    String exportOption = "All",
  }) async {
    try {
      // Reference to the 'sessions' collection in Firestore
      var sessionColl = firestore.collection('sessions');
      QuerySnapshot queryForSessions;

      // Query sessions based on the export option and date range
      if (exportOption == "All") {
        queryForSessions =
            await sessionColl.where('userId', isEqualTo: userId).get();
      } else {
        queryForSessions =
            await sessionColl
                .where('userId', isEqualTo: userId)
                .where(
                  'startTime',
                  isGreaterThanOrEqualTo: startTime ?? DateTime(2000, 1, 1),
                )
                .where(
                  'endTime',
                  isLessThanOrEqualTo: endTime ?? DateTime.now(),
                )
                .get();
      }

      if (queryForSessions.docs.isNotEmpty) {
        // Initialize variables for aggregating session data
        double totalCalories = 0;
        double totalDistance = 0;
        int totalSteps = 0;
        double totalSpeed = 0;
        int sessionCount = queryForSessions.docs.length;
        List<Map<String, dynamic>> sessionDetails = [];

        // Iterate through session documents and aggregate data
        for (var doc in queryForSessions.docs) {
          var sessionData = doc.data() as Map<String, dynamic>;
          totalCalories += sessionData['calories']?.toDouble() ?? 0.0;
          totalDistance += sessionData['distance']?.toDouble() ?? 0.0;
          totalSteps += (sessionData['totalSteps'] as num?)?.toInt() ?? 0;
          totalSpeed += sessionData['speed']?.toDouble() ?? 0.0;
          sessionDetails.add(sessionData);
        }

        // Calculate average speed
        double averageSpeed = totalSpeed / sessionCount;

        // Fetch user document to retrieve IMEI
        var userDoc =
            await firestore
                .collection('users')
                .where('userId', isEqualTo: userId)
                .get();
        var imei = (userDoc.docs.first.data() as Map<String, dynamic>)['imei'];

        // Return aggregated session data
        return {
          "IMEI": imei ?? "Unknown IMEI",
          "uuid": UserSession().userId,
          "totalCalories": totalCalories,
          "totalDistance": totalDistance,
          "totalSteps": totalSteps,
          "averageSpeed": averageSpeed,
          "sessionDetails": sessionDetails,
        };
      } else {
        // Return an error if no session data is found
        return {"error": "No session data found for this user."};
      }
    } catch (err) {
      // Handle errors and return an error map
      print("Error occurred: $err");
      return {"error": err.toString()};
    }
  }

  /// Fetches sessions in a date range and buckets them into hourly intervals.
  Future<Map<String, dynamic>> fetchSessionDetails(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      // Reference to the 'sessions' collection in Firestore
      var sessionColl = firestore.collection('sessions');
      // Query sessions within the specified date range
      var querySnapshot =
          await sessionColl
              .where('userId', isEqualTo: UserSession().userId)
              .where('startTime', isGreaterThanOrEqualTo: fromDate)
              .where('endTime', isLessThanOrEqualTo: toDate)
              .get();

      if (querySnapshot.docs.isEmpty) return {"sessionDetails": {}};

      // Initialize hourly data buckets
      Map<String, Map<String, dynamic>> hourlyData = _initializeHourlyData();

      // Distribute session data into hourly buckets
      for (var doc in querySnapshot.docs) {
        var sessionData = doc.data() as Map<String, dynamic>;
        DateTime startTime = (sessionData['startTime'] as Timestamp).toDate();
        DateTime endTime = (sessionData['endTime'] as Timestamp).toDate();
        _distributeSessionData(sessionData, startTime, endTime, hourlyData);
      }

      // Return the hourly session data
      return {
        DateTime(fromDate.year, fromDate.month, fromDate.day).toIso8601String():
            hourlyData,
      };
    } catch (e, stack) {
      // Handle errors and return an error map
      print("Error fetching sessions: $e\nStackTrace: $stack");
      return {"error": e.toString()};
    }
  }

  /// Initializes a map for hourly data buckets with default values.
  Map<String, Map<String, dynamic>> _initializeHourlyData() {
    return Map.fromIterable(
      List.generate(24, (i) => i),
      key:
          (i) =>
              '${i.toString().padLeft(2, '0')}:00 - ${(i + 1).toString().padLeft(2, '0')}:00',
      value:
          (_) => {
            "calories": 0.0,
            "speed": 0.0,
            "heartRate": 0.0,
            "distance": 0.0,
          },
    );
  }

  /// Distributes session data into hourly buckets based on overlap duration.
  void _distributeSessionData(
    Map<String, dynamic> sessionData,
    DateTime startTime,
    DateTime endTime,
    Map<String, Map<String, dynamic>> hourlyData,
  ) {
    for (int i = 0; i < 24; i++) {
      // Define the start and end of the current hour bucket
      DateTime bucketStart = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
        i,
      ); // Start of hour
      DateTime bucketEnd = bucketStart.add(Duration(hours: 1)); // End of hour

      // Check if the session overlaps with the current hour bucket
      if (startTime.isBefore(bucketEnd) && endTime.isAfter(bucketStart)) {
        // Calculate the overlap duration between the session and the bucket
        double overlap = _calculateOverlapDuration(
          startTime,
          endTime,
          bucketStart,
          bucketEnd,
        );
        double duration =
            (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
                .toDouble();

        if (duration > 0 && overlap > 0) {
          // Calculate the weight of the session data for the current bucket
          double weight = overlap / duration;
          String key =
              "${i.toString().padLeft(2, '0')}:00 - ${(i + 1).toString().padLeft(2, '0')}:00";
          // Update the hourly data bucket with weighted session data
          _updateHourlyData(hourlyData[key]!, sessionData, weight);
        }
      }
    }
  }

  /// Calculates the overlap duration between two time intervals.
  double _calculateOverlapDuration(
    DateTime s,
    DateTime e,
    DateTime bs,
    DateTime be,
  ) {
    double overlapStart =
        s.isAfter(bs)
            ? s.millisecondsSinceEpoch.toDouble()
            : bs.millisecondsSinceEpoch.toDouble();
    double overlapEnd =
        e.isBefore(be)
            ? e.millisecondsSinceEpoch.toDouble()
            : be.millisecondsSinceEpoch.toDouble();
    return (overlapEnd - overlapStart).clamp(0, double.infinity);
  }

  /// Updates an hourly data bucket with weighted session data.
  void _updateHourlyData(
    Map<String, dynamic> bucket,
    Map<String, dynamic> sessionData,
    double weight,
  ) {
    bucket["calories"] += (sessionData['calories'] ?? 0) * weight;
    bucket["speed"] += (sessionData['speed'] ?? 0) * weight;
    bucket["heartRate"] += (sessionData['heartRate'] ?? 0) * weight;
    bucket["distance"] += (sessionData['distance'] ?? 0) * weight;
  }
}
