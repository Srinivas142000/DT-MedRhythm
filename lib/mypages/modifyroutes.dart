import 'package:cloud_firestore/cloud_firestore.dart';

/// A class responsible for modifying user session data in Firestore.
class FirebaseModifyStore {
  /// Firestore instance to interact with the Firestore database.
  /// This is passed as a parameter to support dependency injection in unit tests.
  final FirebaseFirestore firestore;

  /// Constructor with optional [firestore] parameter.
  /// If no instance is passed, it defaults to [FirebaseFirestore.instance].
  FirebaseModifyStore({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  /// Adds a session ID to a user's Firestore document.
  ///
  /// Parameters:
  /// - [sessionId]: The session ID to add to the user's session list.
  /// - [userId]: The ID of the user whose document is being updated.
  ///
  /// This uses `arrayUnion` to ensure the sessionId is only added if it's not already present.
  Future<void> amendSessionsToUser(String sessionId, String userId) async {
    try {
      final usersColl = firestore.collection('users');
      await usersColl.doc(userId).update({
        "sessionIds": FieldValue.arrayUnion([sessionId]),
      });
    } catch (err) {
      // Catches and prints any error that occurs during Firestore update.
      // This is helpful during debugging and development.
      print(err);
      rethrow;
    }
  }
}
