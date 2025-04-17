import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/mypages/modifyroutes.dart';

import 'modifyroutes_test.mocks.dart';

/// Generate mocks for the required Firestore classes.
/// These mocks will allow us to simulate Firestore behavior in tests.
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
void main() {
  // Declare mock instances for Firestore components.
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocument;
  late FirebaseModifyStore modifyStore;

  /// Setup runs before each test to initialize the mocks.
  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocument = MockDocumentReference<Map<String, dynamic>>();

    // Define how the mocked Firestore should respond to method calls.
    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);

    // Pass the mocked Firestore to the store class to avoid real Firebase initialization.
    modifyStore = FirebaseModifyStore(firestore: mockFirestore);
  });

  /// Test that checks whether the session ID is correctly added to the user's document.
  test('amendSessionsToUser should update Firestore', () async {
    // Simulate a successful Firestore update.
    when(mockDocument.update(any)).thenAnswer((_) async {});

    // Call the method being tested.
    await modifyStore.amendSessionsToUser("session123", "user456");

    // Verify that the document's update method was called with the expected data.
    verify(
      mockDocument.update({
        "sessionIds": FieldValue.arrayUnion(["session123"]),
      }),
    ).called(1);
  });

  /// Test that ensures the method throws an exception when Firestore update fails.
  test('amendSessionsToUser should handle Firestore errors', () async {
    // Simulate an exception during Firestore update.
    when(mockDocument.update(any)).thenThrow(Exception('Firestore error'));

    // The method should throw an exception when update fails.
    expect(
      () async =>
          await modifyStore.amendSessionsToUser("session123", "user456"),
      throwsException,
    );
  });
}
