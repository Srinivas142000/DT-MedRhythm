import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';
import 'package:medrhythms/userappactions/sessions.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/helpers/datasyncmanager.dart';
import 'package:medrhythms/mypages/createroutes.dart';
import 'package:medrhythms/userappactions/audios.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/constants/constants.dart';

import 'sessions_test.mocks.dart';

@GenerateMocks([
  Health,
  UserSession,
  CreateDataService,
  LocalAudioManager,
  DataSyncManager,
  Uuid,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Sessions sessions;
  late MockHealth mockHealth;
  late MockUserSession mockUserSession;
  late MockCreateDataService mockCreateDataService;
  late MockDataSyncManager mockDataSyncManager;
  late MockLocalAudioManager mockAudioManager;
  late MockUuid mockUuid;

  setUp(() {
    mockHealth = MockHealth();
    mockUserSession = MockUserSession();
    mockCreateDataService = MockCreateDataService();
    mockDataSyncManager = MockDataSyncManager();
    mockAudioManager = MockLocalAudioManager();
    mockUuid = MockUuid();

    sessions = Sessions(
      us: mockUserSession,
      csd: mockCreateDataService,
      audioManager: mockAudioManager,
      dsm: mockDataSyncManager,
    );
  });

  test('calculateDistance returns correct value', () async {
    Position start = Position(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    Position end = Position(
      latitude: 1.0,
      longitude: 1.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    double distance = await sessions.calculateDistance(start, end);
    expect(distance, greaterThan(0));
  });

  test('setUserId stores user ID correctly', () {
    sessions.setUserId('test-user');
    expect(sessions.userId, equals('test-user'));
  });

  test('setSelectedDuration stores duration correctly', () {
    Duration d = Duration(minutes: 30);
    sessions.setSelectedDuration(d);
    expect(sessions.totalSelectedDuration, equals(d));
  });

  test('stopLiveWorkout generates mock data if all totals are zero', () async {
    sessions.isTracking = true;
    sessions.liveData.clear();

    when(
      mockHealth.getHealthDataFromTypes(
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        types: anyNamed('types'),
      ),
    ).thenAnswer((_) async => []);

    when(
      mockCreateDataService.createSessionData(
        any,
        any,
        any,
        any,
        any,
        any,
        any,
        any,
      ),
    ).thenAnswer((_) async => null);

    await sessions.stopLiveWorkout(
      mockHealth,
      'mockUser',
      Duration(minutes: 30),
    );

    expect(sessions.isTracking, isFalse);
  });

  test('collectDailyHealthData handles no authorization', () async {
    when(mockHealth.requestAuthorization(any)).thenAnswer((_) async => false);

    await sessions.collectDailyHealthData(mockHealth, mockUuid);

    verify(mockHealth.requestAuthorization(any)).called(1);
    verifyNever(
      mockCreateDataService.createSessionData(
        any,
        any,
        any,
        any,
        any,
        any,
        any,
        any,
      ),
    );
  });

  test('collectDailyHealthData stores data if authorized', () async {
    when(mockHealth.requestAuthorization(any)).thenAnswer((_) async => true);
    when(
      mockHealth.getHealthDataFromTypes(
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        types: anyNamed('types'),
      ),
    ).thenAnswer((_) async => []);

    when(mockUuid.toString()).thenReturn("uuid123");
    await sessions.collectDailyHealthData(mockHealth, mockUuid);

    verify(
      mockCreateDataService.createSessionData(
        any,
        any,
        any,
        any,
        any,
        any,
        any,
        any,
      ),
    ).called(1);
  });

  test('syncSession should not run when userId is null', () async {
    when(mockUserSession.userId).thenReturn(null);
    await sessions.syncSession(Duration(minutes: 30));
    verifyNever(
      mockCreateDataService.createSessionData(
        any,
        any,
        any,
        any,
        any,
        any,
        any,
        any,
      ),
    );
  });

  test('syncSessionInBackground schedules without crashing', () async {
    when(mockUserSession.userId).thenReturn("test-user");
    expect(
      () => sessions.syncSessionInBackground(Duration(minutes: 10)),
      returnsNormally,
    );
  });
}
