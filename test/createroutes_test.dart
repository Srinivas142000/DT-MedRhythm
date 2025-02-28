import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dt_medrhythm/mypages/modifyroutes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dt_medrhythm/mypages/createroutes.dart';
import 'createroutes_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  FirebaseModifyStore,
])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CreateDataService createDataService;
  late MockCollectionReference mockUsersColl;
  late MockCollectionReference mockSessionColl;
  late MockFirebaseModifyStore mockModifyStore;
  late MockDocumentReference mockDocRef;

  setUp(() {
    mockUsersColl = MockCollectionReference();
    mockSessionColl = MockCollectionReference();
    mockModifyStore = MockFirebaseModifyStore();
    mockDocRef = MockDocumentReference();

    createDataService = CreateDataService();
    createDataService.usersColl = mockUsersColl;
    createDataService.sessionColl = mockSessionColl;
    createDataService.mu = mockModifyStore;
  });

  test('createUserReference should add user to collection', () async {
    // Arrange
    when(mockUsersColl.add(any)).thenAnswer((_) async => mockDocRef);

    // Act
    await createDataService.createUserReference('test-imei');

    // Assert
    verify(mockUsersColl.add(any)).called(1);
  });

  test('createSessionData should add session and update user', () async {
    // Arrange
    when(mockSessionColl.add(any)).thenAnswer((_) async => mockDocRef);
    when(
      mockModifyStore.amendSessionsToUser('', ''),
    ).thenAnswer((_) async => {});

    // Act
    await createDataService.createSessionData(
      'user-id',
      DateTime.now(),
      DateTime.now(),
      100,
      200,
      300,
      4.0,
      'test',
    );

    // Assert
    verify(mockSessionColl.add(any)).called(1);
    verify(mockModifyStore.amendSessionsToUser('', '')).called(1);
  });
}
