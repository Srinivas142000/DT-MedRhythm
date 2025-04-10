//Imports for all the necessary packages
import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/loginpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';
import 'package:medrhythms/myuipages/records_page.dart';
import 'package:medrhythms/myuipages/bottombar.dart';

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
      routes: {
        '/sessions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SessionsPage(
            uuid: args['uuid'],
            userData: args['userData'],
          );
        },
        '/records': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RecordsPage(
            uuid: args['uuid'],
            userData: args['userData'],
          );
        },
        '/music': (context) => Scaffold(
          appBar: AppBar(title: Text('Music')),
          body: Center(child: Text('Music Page - Coming Soon')),
          bottomNavigationBar: Bottombar(currentIndex: 2),
        ),
        '/settings': (context) => Scaffold(
          appBar: AppBar(title: Text('Settings')),
          body: Center(child: Text('Settings Page - Coming Soon')),
          bottomNavigationBar: Bottombar(currentIndex: 3),
        ),
      },
    );
  }
}
