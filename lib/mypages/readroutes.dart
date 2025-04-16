import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/mypages/createroutes.dart'; // Import necessary files

class FirestoreServiceRead {
  // Reference to the 'users' collection in Firestore
  final CollectionReference usersColl = FirebaseFirestore.instance.collection(
    'users',
  );

  // Reference to the 'sessions' collection in Firestore
  final CollectionReference sessionColl = FirebaseFirestore.instance.collection(
    'sessions',
  );

  // Instance of CreateDataService to create user references
  final CreateDataService csd = CreateDataService();

  // Method to check if a user exists based on IMEI and create user reference if not
  Future<Map<String, dynamic>?> checkUserSessionRegistry(String imei) async {
    try {
      // Query the 'users' collection for documents where 'imei' matches the provided IMEI
      var querySnapshot = await usersColl.where('imei', isEqualTo: imei).get();

      if (querySnapshot.docs.isNotEmpty) {
        // If the query returns any documents, user exists
        var userDetails =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (userDetails.containsKey('userId')) {
          return userDetails; // Return the user details
        }
      } else {
        // If no user is found, create the user reference
        await csd.createUserReference(imei);
        return checkUserSessionRegistry(imei); // Return newly created details
      }
    } catch (e) {
      print("Error occurred: $e");
      return {
        "error": e.toString(),
      }; // Return a JSON object with an error message
    }
  }

  // Method to fetch session data and calculate sums and averages
  Future<Map<String, dynamic>> fetchUserSessionData(String userId) async {
    try {
      var queryForSessions =
          await sessionColl.where('userId', isEqualTo: userId).get();
      if (queryForSessions.docs.isNotEmpty) {
        double totalCalories = 0;
        double totalDistance = 0;
        int totalSteps = 0;
        double totalSpeed = 0;
        int sessionCount = queryForSessions.docs.length;

        for (var doc in queryForSessions.docs) {
          var sessionData = doc.data() as Map<String, dynamic>;
          totalCalories += sessionData['calories'] ?? 0;
          totalDistance += sessionData['distance'] ?? 0;
          totalSteps += (sessionData['totalSteps'] ?? 0) as int;
          totalSpeed += sessionData['speed'] ?? 0;
        }

        double averageSpeed = totalSpeed / sessionCount;

        return {
          "totalCalories": totalCalories,
          "totalDistance": totalDistance,
          "totalSteps": totalSteps,
          "averageSpeed": averageSpeed,
        };
      } else {
        return {"error": "No session data found for this user."};
      }
    } catch (err) {
      print("Error occurred: $err");
      return {"error": err.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchSessionDetails(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      // Fetch sessions from Firestore
      var queryForSessions =
          await sessionColl
              .where('startTime', isGreaterThanOrEqualTo: fromDate)
              .where('endTime', isLessThanOrEqualTo: toDate)
              .get();

      // Return empty map if no sessions found
      if (queryForSessions.docs.isEmpty) {
        return {"sessionDetails": {}};
      }

      // Create hourly data map with default values
      Map<String, Map<String, dynamic>> hourlyData = _initializeHourlyData();

      // Process each session and distribute data into hourly buckets
      for (var doc in queryForSessions.docs) {
        var sessionData = doc.data() as Map<String, dynamic>;

        DateTime startTime = (sessionData['startTime'] as Timestamp).toDate();
        DateTime endTime = (sessionData['endTime'] as Timestamp).toDate();

        _distributeSessionData(sessionData, startTime, endTime, hourlyData);
      }

      // Remove empty entries before returning
      // _removeEmptyBuckets(hourlyData);

      // Return processed session details with the desired map format
      DateTime currentDate = DateTime(
        fromDate.year,
        fromDate.month,
        fromDate.day,
      );

      return {currentDate.toIso8601String(): hourlyData};
    } catch (e, stackTrace) {
      print("Error fetching sessions: $e\nStackTrace: $stackTrace");
      return {"error": e.toString()};
    }
  }

  // --- Helper Method: Initialize Hourly Buckets ---
  Map<String, Map<String, dynamic>> _initializeHourlyData() {
    Map<String, Map<String, dynamic>> hourlyData = {};

    for (int i = 0; i < 24; i++) {
      String startTime = "${i.toString().padLeft(2, '0')}:00";
      String endTime = "${(i + 1).toString().padLeft(2, '0')}:00";
      String key = "$startTime - $endTime";

      hourlyData[key] = {
        "calories": 0.0,
        "speed": 0.0,
        "heartRate": 0.0,
        "distance": 0.0,
        "totalSteps": 0.0,
      };
    }

    return hourlyData;
  }

  // --- Helper Method: Distribute Session Data into Buckets ---
  void _distributeSessionData(
    Map<String, dynamic> sessionData,
    DateTime startTime,
    DateTime endTime,
    Map<String, Map<String, dynamic>> hourlyData,
  ) {
    for (int i = 0; i < 24; i++) {
      DateTime bucketStart = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
        i,
      );
      DateTime bucketEnd = bucketStart.add(Duration(hours: 1));

      if (startTime.isBefore(bucketEnd) && endTime.isAfter(bucketStart)) {
        double overlapDuration = _calculateOverlapDuration(
          startTime,
          endTime,
          bucketStart,
          bucketEnd,
        );
        double sessionDuration =
            (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
                .toDouble();

        if (sessionDuration > 0 && overlapDuration > 0) {
          double weight = overlapDuration / sessionDuration;

          String key =
              "${i.toString().padLeft(2, '0')}:00 - ${(i + 1).toString().padLeft(2, '0')}:00";

          _updateHourlyData(hourlyData[key]!, sessionData, weight);
        }
      }
    }
  }

  // --- Helper Method: Calculate Overlap Duration ---
  double _calculateOverlapDuration(
    DateTime startTime,
    DateTime endTime,
    DateTime bucketStart,
    DateTime bucketEnd,
  ) {
    double overlapStart =
        startTime.isAfter(bucketStart)
            ? startTime.millisecondsSinceEpoch.toDouble()
            : bucketStart.millisecondsSinceEpoch.toDouble();

    double overlapEnd =
        endTime.isBefore(bucketEnd)
            ? endTime.millisecondsSinceEpoch.toDouble()
            : bucketEnd.millisecondsSinceEpoch.toDouble();

    return (overlapEnd - overlapStart).clamp(0, double.infinity);
  }

  // --- Helper Method: Update Hourly Data ---
  void _updateHourlyData(
    Map<String, dynamic> bucket,
    Map<String, dynamic> sessionData,
    double weight,
  ) {
    bucket["calories"] += (sessionData['calories'] ?? 0) * weight;
    bucket["speed"] += (sessionData['speed'] ?? 0) * weight;
    bucket["heartRate"] += (sessionData['heartRate'] ?? 0) * weight;
    bucket["distance"] += (sessionData['distance'] ?? 0) * weight;
    bucket["totalSteps"] += (sessionData['totalSteps'] ?? 0) * weight;
  }

  // --- Helper Method: Remove Empty Buckets ---
  void _removeEmptyBuckets(Map<String, Map<String, dynamic>> hourlyData) {
    // Collect keys to be removed in a separate list
    List<String> emptyKeys = [];

    // Identify keys where all values are zero
    hourlyData.forEach((key, value) {
      if (value["calories"] == 0.0 &&
          value["speed"] == 0.0 &&
          value["heartRate"] == 0.0 &&
          value["distance"] == 0.0) {
        emptyKeys.add(key);
      }
    });

    // Remove keys AFTER iteration to avoid concurrent modification
    for (var key in emptyKeys) {
      hourlyData.remove(key);
    }
  }
}
