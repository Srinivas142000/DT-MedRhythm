import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/modifyroutes.dart';

/// CreateDataService handles all Firestore write operations related to users and sessions.
class CreateDataService {
  /// Firestore collection for storing user data.
  CollectionReference usersColl;

  /// Firestore collection for storing session data.
  CollectionReference sessionColl;

  /// Class responsible for modifying user session relationships.
  FirebaseModifyStore mu;

  /// Constructor with dependency injection for easier testing.
  CreateDataService({
    CollectionReference? usersColl,
    CollectionReference? sessionColl,
    FirebaseModifyStore? mu,
  }) : usersColl = usersColl ?? FirebaseFirestore.instance.collection('users'),
       sessionColl =
           sessionColl ?? FirebaseFirestore.instance.collection('sessions'),
       mu = mu ?? FirebaseModifyStore();

  /// Creates a user entry in Firestore with IMEI and UUID.
  Future<void> createUserReference(String imeiValue) async {
    final userData = {
      'imei': imeiValue,
      'userId': Uuid().v4(),
      'sessionIds': <String>[],
    };

    await usersColl.add(userData);
  }

  /// Creates a session entry and links it to the user.
  Future<void> createSessionData(
    String userId,
    DateTime startTime,
    DateTime endTime,
    double steps,
    double distance,
    double calories,
    double speed,
    String source,
  ) async {
    final sessionId = Uuid().v4();
    final sessionData = {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
      'totalSteps': steps,
      'distance': distance,
      'calories': calories,
      'source': source,
      'speed': speed,
    };

    await sessionColl.add(sessionData);
    await mu.amendSessionsToUser(sessionId.toString(), userId);
  }
}
