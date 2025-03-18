import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medrhythms/myuipages/loginpage.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:medrhythms/constants/constants.dart';

Health health = Health();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Request permissions before launching the app
  bool permissionsGranted = await _requestHealthPermissions();
  // Save permission status in UserSession
  UserSession session = UserSession();
  session.savePermissions(permissionsGranted);
  runApp(MyApp(permissionsGranted: permissionsGranted));
}

/// Main App with Permission Check
class MyApp extends StatelessWidget {
  final bool permissionsGranted;
  const MyApp({Key? key, required this.permissionsGranted}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MedRhythms',
        home: LoginPage());
  }
}

/// Requests necessary permissions for Health & System Sensors
Future<bool> _requestHealthPermissions() async {
  // System Permissions
  Map<Permission, PermissionStatus> statuses = await [
    Permission.activityRecognition,
    Permission.sensors,
    Permission.location,
  ].request();
  bool systemPermissionsGranted =
      statuses.values.every((status) => status.isGranted);
  try {
    bool healthConnectExists = await health.isHealthConnectAvailable();
    if (!healthConnectExists) {
      print("Health Connect is not available on this device.");
      await health.installHealthConnect();
    }
  } catch (e) {
    // Handle any exceptions that may occur
    print("Error checking Health Connect availability: $e");
  }
  final permissions = Constants.healthDataTypes
      .map((e) => HealthDataAccess.READ_WRITE)
      .toList();
  bool healthPermissionsGranted = await health.requestAuthorization(
      Constants.healthDataTypes,
      permissions: permissions);
  return systemPermissionsGranted && healthPermissionsGranted;
}
