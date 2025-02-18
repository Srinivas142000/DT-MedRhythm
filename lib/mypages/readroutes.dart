import 'package:cloud_firestore/cloud_firestore.dart';
import 'createroutes.dart'; // Import necessary files

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
      var queryForSessions =
          await sessionColl
              .where('startTime', isGreaterThanOrEqualTo: fromDate)
              .where('endTime', isLessThanOrEqualTo: toDate)
              .get();

      if (queryForSessions.docs.isNotEmpty) {
        List<Map<String, dynamic>> sessionDetails = [];

        for (var doc in queryForSessions.docs) {
          var sessionData = doc.data() as Map<String, dynamic>;
          sessionDetails.add(sessionData);
        }

        return {"sessionDetails": sessionDetails};
      } else {
        return {"error": "No session data found for the specified date range."};
      }
    } catch (err) {
      print("Error occurred: $err");
      return {"error": err.toString()};
    }
  }
}
