import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDeleteStore {
  // Reference to the 'users' collection in Firestore
  // This collection stores user documents, each identified by a unique user ID
  final CollectionReference usersColl =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference sessionColl =
      FirebaseFirestore.instance.collection('sessions');

  // Method to Delete a session ID to a user's document in Firestore
  // Parameters:
  // - sessionId: The ID of the session to be added to the user's document
  Future<void> removeSessionFromUser(String sessionId) async {
    try {
      // Delete the user's document by removing the session from DB
      // Remove the DB entry for the session
      await usersColl.doc(sessionId).delete();
    } catch (err) {
      // Print any errors that occur during the update
      // This helps in debugging issues related to Firestore operations
      print(err);
    }
  }
}
