import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dt_medrhythm/mypages/deleteroutes.dart';

// Mock Firestore classes
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

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockDocumentRef = MockDocumentReference();

      // Mock Firestore instance
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockUsersCollection.doc(any)).thenReturn(mockDocumentRef);
      deleteStore = FirebaseDeleteStore();
    });

    test('removeSessionFromUser should delete user document', () async {
      // Stub delete method
      when(mockDocumentRef.delete()).thenAnswer((_) async {});

      await deleteStore.removeSessionFromUser('session123');

      // Verify that delete was called
      verify(mockDocumentRef.delete()).called(1);
    });

    test('removeSessionFromUser should handle Firestore errors', () async {
      when(mockDocumentRef.delete()).thenThrow(Exception('Firestore error'));

      await deleteStore.removeSessionFromUser('session123');

      // Verify delete was attempted
      verify(mockDocumentRef.delete()).called(1);
    });
  });
}
