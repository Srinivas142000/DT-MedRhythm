//Imports for all the necessary packages
import 'package:flutter/material.dart'; //For UI
import 'package:medrhythms/myuipages/loginpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';

//Main function and entry
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

//stateless widget that represents the main application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedRhythms',
      home: LoginPage(),
    );
  }
}
