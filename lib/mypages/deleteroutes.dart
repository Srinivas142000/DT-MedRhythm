import 'package:cloud_firestore/cloud_firestore.dart';

/// A class responsible for deleting session entries from Firestore.
class FirebaseDeleteStore {
  /// Firestore instance to allow dependency injection for testability.
  final FirebaseFirestore firestore;

  /// Constructor with optional dependency injection.
  /// Defaults to FirebaseFirestore.instance when no mock is provided.
  FirebaseDeleteStore({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  /// Removes the user's session document from the 'users' collection in Firestore.
  ///
  /// Parameters:
  /// - [sessionId]: The document ID to delete.
  ///
  /// This simulates removing a user session by deleting their corresponding document.
  Future<void> removeSessionFromUser(String sessionId) async {
    try {
      final usersColl = firestore.collection('users');
      await usersColl.doc(sessionId).delete();
    } catch (err) {
      // Log Firestore errors to help with debugging.
      print(err);
      rethrow;
    }
  }
}
