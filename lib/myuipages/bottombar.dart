import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';
import 'package:medrhythms/myuipages/records_page.dart';
import 'package:medrhythms/helpers/usersession.dart';

class Bottombar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey,
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
              print("Calendar icon pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordsPage(
                    uuid: "test-uuid", // Hardcoded for testing
                    userData: {}, // Empty map for testing
                  ),
                ),
              );
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
