import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/modifyroutes.dart';

/// CreateDataService
///
/// This class is responsible for handling user-related, session-related database operations
/// in Firebase Firestore. It provides a method to create a user reference
/// with a unique identifier and an empty session history.
///
/// **Purpose:**
/// - To store user data in Firestore.
/// - To generate and assign a unique userId for each user.
/// - To initialize an empty list of session IDs for tracking user sessions.
/// - To store session data in Firestore.
/// - To generate and assign a unique sessionId for each user.
/// - To add calories to the session.
/// - To add distance walked during the session.
/// - To add speed of user during the session.
/// - To add start and end time of users during the session.
class CreateDataService {
  /// Firestore Collection Reference
  ///
  /// This variable represents the Firestore collection named 'users'
  /// where all user-related data will be stored.
  ///
  /// - `FirebaseFirestore.instance.collection('users') retrieves a reference
  ///   to the 'users' collection in Firestore.
  /// - This reference allows us to add, update, and query user records.
  CollectionReference usersColl = FirebaseFirestore.instance.collection(
    'users',
  );

  final CollectionReference sessionColl =
      FirebaseFirestore.instance.collection('sessions');

  FirebaseModifyStore mu = FirebaseModifyStore();

  /// Creates a User Reference in Firestore
  ///
  /// This function adds a new user document to the `'users'` collection
  /// with the following fields:
  /// - 'imei': The device's unique IMEI number (passed as a parameter).
  /// - 'userId': A randomly generated unique identifier using the `uuid` package.
  /// - 'sessionIds': An empty list of session IDs, which can later be populated
  ///    when tracking user activity.
  ///
  /// Parameters:
  /// - imeiValue: A String representing the user's IMEI number.
  ///
  /// Returns:
  /// - A Future <void> indicating an asynchronous operation.
  /// - Uses await to ensure the Firestore operation completes before proceeding.
  Future<void> createUserReference(String imeiValue) async {
    // Construct user data as a map with required fields.
    final userData = {
      'imei': imeiValue, // Store the unique device IMEI number.
      'userId': Uuid().v4(), // Generate a unique identifier for the user.
      'sessionIds':
          <String>[], // Initialize an empty list for session tracking.
    };

    // Add the constructed user data to the Firestore 'users' collection.
    await usersColl.add(userData);
  }

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
    var sessionId = Uuid().v4();
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
