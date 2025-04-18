import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dt_medrhythm/mypages/createroutes.dart';
import 'package:dt_medrhythm/mypages/readroutes.dart';

// Mock classes
class MockFirestoreInstance extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

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

    firestoreService = FirestoreServiceRead();

    // Mock the Firestore instance to return mock collections
    when(mockFirestore.collection('users')).thenReturn(
      mockUsersCollection.parameters
          as CollectionReference<Map<String, dynamic>>,
    );

    when(mockFirestore.collection('sessions')).thenReturn(
      mockSessionsCollection.parameters
          as CollectionReference<Map<String, dynamic>>,
    );

    firestoreService = FirestoreServiceRead();
  });

  group('FirestoreServiceRead tests', () {
    test(
      'checkUserSessionRegistry should return user details if user exists',
      () async {
        // Mock the query for user document
        var mockDoc = MockQueryDocumentSnapshot();
        when(
          mockUsersCollection.where('imei', isEqualTo: '123456').get(),
        ).thenAnswer((_) async {
          var querySnapshot = MockQuerySnapshot();
          when(querySnapshot.docs).thenReturn([mockDoc]);
          return querySnapshot;
        });

        // Mock the document data
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
        // Mock query when no user found
        when(
          mockUsersCollection.where('imei', isEqualTo: '123456').get(),
        ).thenAnswer((_) async {
          var querySnapshot = MockQuerySnapshot();
          when(querySnapshot.docs).thenReturn([]);
          return querySnapshot;
        });

        // Mock the call to create a new user reference
        when(
          mockCreateDataService.createUserReference('123456'),
        ).thenAnswer((_) async => null);

        // Call the method
        final result = await firestoreService.checkUserSessionRegistry(
          '123456',
        );

        // Make sure the user is created and then fetched again
        verify(mockCreateDataService.createUserReference('123456')).called(1);
        expect(result, isNotNull);
      },
    );

    test(
      'fetchUserSessionData should return session data if sessions exist',
      () async {
        // Mock session query
        var mockSessionDoc = MockQueryDocumentSnapshot();
        when(
          mockSessionsCollection.where('userId', isEqualTo: 'user123').get(),
        ).thenAnswer((_) async {
          var querySnapshot = MockQuerySnapshot();
          when(querySnapshot.docs).thenReturn([mockSessionDoc]);
          return querySnapshot;
        });
        // Mock session data
        when(mockSessionDoc.data()).thenReturn({
          'calories': 100,
          'distance': 5.0,
          'totalSteps': 1000,
          'speed': 3.5,
        });

        final result = await firestoreService.fetchUserSessionData('user123');

        expect(result, isNotNull);
        expect(result['totalCalories'], 100);
        expect(result['totalDistance'], 5.0);
        expect(result['totalSteps'], 1000);
        expect(result['averageSpeed'], 3.5);
      },
    );

    test(
      'fetchUserSessionData should return error message if no sessions',
      () async {
        // Mock query for no sessions
        when(
          mockSessionsCollection.where('userId', isEqualTo: 'user123').get(),
        ).thenAnswer((_) async {
          var querySnapshot = MockQuerySnapshot();
          when(querySnapshot.docs).thenReturn([]);
          return querySnapshot;
        });

        final result = await firestoreService.fetchUserSessionData('user123');

        expect(result, isNotNull);
        expect(result['error'], 'No session data found for this user.');
      },
    );
  });
}
