import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medrhythms/myuipages/loginpage.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request permissions before launching the app
  bool permissionsGranted = await _requestPermissions();

  // Save permission status in UserSession (no async needed in widget tree)
  UserSession session = UserSession();
  session.savePermissions(permissionsGranted);

  runApp(MyApp());
}

/// Requests necessary permissions
Future<bool> _requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.activityRecognition,
    Permission.sensors,
    Permission.location,
  ].request();

  return statuses.values.every((status) => status.isGranted);
}

/// Main App
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedRhythms',
      home: LoginPage(),
    );
  }
}
