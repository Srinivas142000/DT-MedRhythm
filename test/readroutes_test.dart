import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:medrhythms/mypages/readroutes.dart';

// Mock classes
class MockFirestoreInstance extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockCreateDataService extends Mock implements CreateDataService {}

void main() {
  late FirestoreServiceRead firestoreService;
  late MockFirestoreInstance mockFirestore;
  late MockCreateDataService mockCreateDataService;

  setUp(() {
    mockFirestore = MockFirestoreInstance();
    mockCreateDataService = MockCreateDataService();

    firestoreService = FirestoreServiceRead(
      firestore: mockFirestore,
      createService: mockCreateDataService,
    );
  });

  group('FirestoreServiceRead tests', () {
    test('checkUserSessionRegistry returns user if exists', () async {
      final mockUsersCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockSnapshot = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();

      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(
        mockUsersCollection.where('imei', isEqualTo: '123456'),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn({'imei': '123456', 'userId': 'abc'});

      final result = await firestoreService.checkUserSessionRegistry('123456');
      expect(result, isNotNull);
      expect(result!['userId'], 'abc');
    });

    test('checkUserSessionRegistry creates user if not exists', () async {
      final mockUsersCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockSnapshot = MockQuerySnapshot();

      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(
        mockUsersCollection.where('imei', isEqualTo: 'newimei'),
      ).thenReturn(mockQuery);

      // First call returns empty (simulate no user exists)
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      // After creating user, next call will return a doc
      final mockSnapshotAfterCreate = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();
      when(
        mockCreateDataService.createUserReference('newimei'),
      ).thenAnswer((_) async => null);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshotAfterCreate);
      when(mockSnapshotAfterCreate.docs).thenReturn([mockDoc]);
      when(
        mockDoc.data(),
      ).thenReturn({'imei': 'newimei', 'userId': 'createdUser123'});

      final result = await firestoreService.checkUserSessionRegistry('newimei');

      expect(result, isNotNull);
      expect(result!['userId'], 'createdUser123');
      verify(mockCreateDataService.createUserReference('newimei')).called(1);
    });

    test('fetchUserSessionData returns correct aggregates', () async {
      final mockSessionCollection = MockCollectionReference();
      final mockUserCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockUserQuery = MockQuery();
      final mockSessionSnapshot = MockQuerySnapshot();
      final mockUserSnapshot = MockQuerySnapshot();
      final mockSessionDoc = MockQueryDocumentSnapshot();
      final mockUserDoc = MockQueryDocumentSnapshot();

      when(
        mockFirestore.collection('sessions'),
      ).thenReturn(mockSessionCollection);
      when(mockFirestore.collection('users')).thenReturn(mockUserCollection);
      when(
        mockSessionCollection.where('userId', isEqualTo: 'user123'),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSessionSnapshot);
      when(mockSessionSnapshot.docs).thenReturn([mockSessionDoc]);
      when(mockSessionDoc.data()).thenReturn({
        'calories': 100,
        'distance': 2.5,
        'totalSteps': 500,
        'speed': 1.2,
      });

      when(
        mockUserCollection.where('userId', isEqualTo: 'user123'),
      ).thenReturn(mockUserQuery);
      when(mockUserQuery.get()).thenAnswer((_) async => mockUserSnapshot);
      when(mockUserSnapshot.docs).thenReturn([mockUserDoc]);
      when(mockUserDoc.data()).thenReturn({'imei': 'user123imei'});

      final result = await firestoreService.fetchUserSessionData('user123');

      expect(result['totalCalories'], 100);
      expect(result['totalDistance'], 2.5);
      expect(result['totalSteps'], 500);
      expect(result['averageSpeed'], 1.2);
      expect(result['IMEI'], 'user123imei');
    });

    test('fetchUserSessionData returns error if no session', () async {
      final mockSessionCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockSnapshot = MockQuerySnapshot();

      when(
        mockFirestore.collection('sessions'),
      ).thenReturn(mockSessionCollection);
      when(
        mockSessionCollection.where('userId', isEqualTo: 'ghost'),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final result = await firestoreService.fetchUserSessionData('ghost');

      expect(result['error'], 'No session data found for this user.');
    });
  });
}
