import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:medrhythms/mypages/modifyroutes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'createroutes_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  FirebaseModifyStore,
])
void main() {
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

    // Inject mocks via constructor
    createDataService = CreateDataService(
      usersColl: mockUsersColl,
      sessionColl: mockSessionColl,
      mu: mockModifyStore,
    );
  });

  test('createUserReference should add user to collection', () async {
    // Arrange
    when(mockUsersColl.add(any)).thenAnswer((_) async => mockDocRef);

    // Act
    await createDataService.createUserReference('test-imei');

    // Assert
    verify(mockUsersColl.add(argThat(isA<Map<String, dynamic>>()))).called(1);
  });

  test('createSessionData should add session and update user', () async {
    // Arrange
    when(mockSessionColl.add(any)).thenAnswer((_) async => mockDocRef);
    when(
      mockModifyStore.amendSessionsToUser(any, any),
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
    verify(mockSessionColl.add(argThat(isA<Map<String, dynamic>>()))).called(1);
    verify(mockModifyStore.amendSessionsToUser(any, 'user-id')).called(1);
  });
}
