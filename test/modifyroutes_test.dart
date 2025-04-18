import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dt_medrhythm/mypages/modifyroutes.dart';

import 'modifyroutes_test.mocks.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late FirebaseModifyStore modifyStore;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    modifyStore = FirebaseModifyStore();

    when(mockFirestore.collection('users')).thenReturn(
      mockCollection.parameters as CollectionReference<Map<String, dynamic>>,
    );
    when(mockCollection.doc(any)).thenReturn(mockDocument);
  });

  test('amendSessionsToUser should update Firestore', () async {
    when(mockDocument.update(any)).thenAnswer((_) async {});

    await modifyStore.amendSessionsToUser("session123", "user456");

    verify(
      mockDocument.update({
        "sessionIds": FieldValue.arrayUnion(["session123"]),
      }),
    ).called(1);
  });

  test('amendSessionsToUser should handle Firestore errors', () async {
    when(mockDocument.update(any)).thenThrow(Exception('Firestore error'));

    expect(
      () async =>
          await modifyStore.amendSessionsToUser("session123", "user456"),
      throwsException,
    );
  });
}
