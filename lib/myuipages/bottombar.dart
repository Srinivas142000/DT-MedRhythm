import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';
import 'package:medrhythms/helpers/usersession.dart'; // Import UserSession

class Bottombar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey, // Background color
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.nordic_walking),
            onPressed: () {
              String? uuid = UserSession().userId;
              if (uuid != null && UserSession().userData != null) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SessionsPage(
                      uuid: uuid,
                      userData: UserSession().userData!,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_month_rounded),
            onPressed: () {
              // Handle calendar button press
            },
          ),
          IconButton(
            icon: Icon(Icons.music_note_rounded),
            onPressed: () {
              // Handle music button press
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Handle settings button press
            },
          ),
        ],
      ),
    );
  }
}
