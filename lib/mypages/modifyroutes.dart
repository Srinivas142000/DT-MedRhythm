import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseModifyStore {
  // Reference to the 'users' collection in Firestore
  // This collection stores user documents, each identified by a unique user ID
  final CollectionReference usersColl =
      FirebaseFirestore.instance.collection('users');

  // Method to add a session ID to a user's document in Firestore
  // Parameters:
  // - sessionId: The ID of the session to be added to the user's document
  // - userId: The ID of the user whose document will be updated
  Future<void> amendSessionsToUser(String sessionId, String userId) async {
    try {
      // Update the user's document by adding the session ID to the 'sessionIds' array
      // FieldValue.arrayUnion ensures that the session ID is added only if it doesn't already exist in the array
      await usersColl.doc(userId).update({
        "sessionIds": FieldValue.arrayUnion([sessionId])
      });
    } catch (err) {
      // Print any errors that occur during the update
      // This helps in debugging issues related to Firestore operations
      print(err);
    }
  }
}
