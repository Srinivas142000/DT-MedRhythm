import 'package:flutter/material.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/myuipages/records_page.dart';

class Bottombar extends StatelessWidget {
  final int currentIndex;
  
  Bottombar({this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.nordic_walking, 
              color: currentIndex == 0 ? Colors.green : Colors.black),
            onPressed: () {
              if (currentIndex != 0) {
                String? uuid = UserSession().userId;
                if (uuid != null && UserSession().userData != null) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/sessions', 
                    (Route<dynamic> route) => false,
                    arguments: {
                      'uuid': uuid,
                      'userData': UserSession().userData!,
                    }
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_month_rounded,
              color: currentIndex == 1 ? Colors.green : Colors.black),
            onPressed: () {
              if (currentIndex != 1) {
                String? uuid = UserSession().userId;
                if (uuid != null && UserSession().userData != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecordsPage(
                        uuid: uuid,
                        userData: UserSession().userData!,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.music_note_rounded,
              color: currentIndex == 2 ? Colors.green : Colors.black),
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/music',
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.settings,
              color: currentIndex == 3 ? Colors.green : Colors.black),
            onPressed: () {
              if (currentIndex != 3) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/settings',
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
