import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';

class HomePage extends StatelessWidget{
  final Map<String, dynamic> userData;
  HomePage({required this.userData});


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${userData['userId']}!"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: Text("Logout"),
            )
          ],
        ),
      ),
    );
  }
}
