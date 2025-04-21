import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';

/**
 * 
 * This is no longer being used, but it is a placeholder for the home page of the app.
 * A stateless widget representing the home page of the app.
 * It displays a welcome message with the user's ID and provides a logout button.
 */
class HomePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  /**
   * Creates a HomePage widget.
   * 
   * @param userData [Map<String, dynamic>] A map containing user data, such as the user ID.
   */
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
            // Displays a welcome message with the user's ID
            Text("Welcome, ${userData['userId']}!"),
            SizedBox(height: 20),
            // Logout button to navigate back to the previous screen
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
