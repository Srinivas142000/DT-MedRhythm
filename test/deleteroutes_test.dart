import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/mypages/deleteroutes.dart';

/// Mock Firestore classes to simulate Firestore behavior in unit tests.
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  group('FirebaseDeleteStore Tests', () {
    late FirebaseDeleteStore deleteStore;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockDocumentRef;

    /// Setup mock objects before each test.
    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockDocumentRef = MockDocumentReference();

      // Mock Firestore interactions
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockUsersCollection.doc(any)).thenReturn(mockDocumentRef);

      // Inject mocked Firestore into the class under test
      deleteStore = FirebaseDeleteStore(firestore: mockFirestore);
    });

    /// Test that verifies the document is deleted as expected.
    test('removeSessionFromUser should delete user document', () async {
      // Stub the delete call
      when(mockDocumentRef.delete()).thenAnswer((_) async {});

      await deleteStore.removeSessionFromUser('session123');

      // Ensure delete() was called once
      verify(mockDocumentRef.delete()).called(1);
    });

    /// Test that checks whether Firestore errors are handled correctly.
    test('removeSessionFromUser should handle Firestore errors', () async {
      // Simulate a delete failure
      when(mockDocumentRef.delete()).thenThrow(Exception('Firestore error'));

      // Call the method and expect it to throw
      expect(
        () async => await deleteStore.removeSessionFromUser('session123'),
        throwsException,
      );

      // Ensure delete() was still attempted
      verify(mockDocumentRef.delete()).called(1);
    });
  });
}
