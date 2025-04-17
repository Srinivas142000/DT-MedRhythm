import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:medrhythms/mypages/readroutes.dart';

// Mock classes
class MockFirestoreInstance extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockCreateDataService extends Mock implements CreateDataService {}

void main() {
  late FirestoreServiceRead firestoreService;
  late MockFirestoreInstance mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockCollectionReference mockSessionsCollection;
  late MockCreateDataService mockCreateDataService;

  setUp(() {
    // Initialize mocks
    mockFirestore = MockFirestoreInstance();
    mockUsersCollection = MockCollectionReference();
    mockSessionsCollection = MockCollectionReference();
    mockCreateDataService = MockCreateDataService();

    // Mock Firestore collections
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(
      mockFirestore.collection('sessions'),
    ).thenReturn(mockSessionsCollection);

    // Inject mocks into the FirestoreServiceRead instance
    firestoreService = FirestoreServiceRead(
      firestore: mockFirestore,
      createService: mockCreateDataService,
    );
  });

  group('FirestoreServiceRead tests', () {
    test(
      'checkUserSessionRegistry should return user details if user exists',
      () async {
        final mockDoc = MockQueryDocumentSnapshot();
        final mockQuerySnapshot = MockQuerySnapshot();

        // Setup user document to return
        when(
          mockUsersCollection.where('imei', isEqualTo: '123456'),
        ).thenReturn(mockUsersCollection);
        when(
          mockUsersCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
        when(
          mockDoc.data(),
        ).thenReturn({'imei': '123456', 'userId': 'user123'});

        final result = await firestoreService.checkUserSessionRegistry(
          '123456',
        );

        expect(result, isNotNull);
        expect(result!['userId'], 'user123');
      },
    );

    test(
      'checkUserSessionRegistry should create user if user does not exist',
      () async {
        final mockQuerySnapshot = MockQuerySnapshot();

        // Simulate no user found
        when(
          mockUsersCollection.where('imei', isEqualTo: '123456'),
        ).thenReturn(mockUsersCollection);
        when(
          mockUsersCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Expect user creation to be called
        when(
          mockCreateDataService.createUserReference('123456'),
        ).thenAnswer((_) async => null);

        // Call the method
        final result = await firestoreService.checkUserSessionRegistry(
          '123456',
        );

        verify(mockCreateDataService.createUserReference('123456')).called(1);
        expect(result, isNotNull);
      },
    );

    test(
      'fetchUserSessionData should return session data if sessions exist',
      () async {
        final mockSessionDoc = MockQueryDocumentSnapshot();
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockUserQuerySnapshot = MockQuerySnapshot();
        final mockUserDoc = MockQueryDocumentSnapshot();

        // Mock session documents
        when(
          mockSessionsCollection.where('userId', isEqualTo: 'user123'),
        ).thenReturn(mockSessionsCollection);
        when(
          mockSessionsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockSessionDoc]);
        when(mockSessionDoc.data()).thenReturn({
          'calories': 100,
          'distance': 5.0,
          'totalSteps': 1000,
          'speed': 3.5,
        });

        // Mock user document with IMEI
        when(
          mockUsersCollection.where('userId', isEqualTo: 'user123'),
        ).thenReturn(mockUsersCollection);
        when(
          mockUsersCollection.get(),
        ).thenAnswer((_) async => mockUserQuerySnapshot);
        when(mockUserQuerySnapshot.docs).thenReturn([mockUserDoc]);
        when(mockUserDoc.data()).thenReturn({'imei': '111222'});

        final result = await firestoreService.fetchUserSessionData('user123');

        expect(result, isNotNull);
        expect(result['totalCalories'], 100);
        expect(result['totalDistance'], 5.0);
        expect(result['totalSteps'], 1000);
        expect(result['averageSpeed'], 3.5);
        expect(result['IMEI'], '111222');
      },
    );

    test(
      'fetchUserSessionData should return error message if no sessions',
      () async {
        final mockQuerySnapshot = MockQuerySnapshot();

        // Simulate no sessions found
        when(
          mockSessionsCollection.where('userId', isEqualTo: 'user123'),
        ).thenReturn(mockSessionsCollection);
        when(
          mockSessionsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final result = await firestoreService.fetchUserSessionData('user123');

        expect(result, isNotNull);
        expect(result['error'], 'No session data found for this user.');
      },
    );
  });
}
