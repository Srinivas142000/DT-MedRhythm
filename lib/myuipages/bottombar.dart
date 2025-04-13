import 'package:flutter/material.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/mypages/readroutes.dart';
import 'package:medrhythms/myuipages/export_settings.dart';
import 'package:medrhythms/myuipages/records_page.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';

FirestoreServiceRead fsr = FirestoreServiceRead();
ExportSettingsPage esp = ExportSettingsPage();

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
            icon: Icon(
              Icons.nordic_walking,
              color: currentIndex == 0 ? Colors.green : Colors.black,
            ),
            onPressed: () {
              String? uuid = UserSession().userId;
              if (uuid != null && UserSession().userData != null) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SessionsPage(
                          uuid: uuid,
                          userData: UserSession().userData!,
                        ),
                  ),
                );
              }
              if (currentIndex != 0) {
                String? uuid = UserSession().userId;
                if (uuid != null && UserSession().userData != null) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/sessions',
                    (Route<dynamic> route) => false,
                    arguments: {
                      'uuid': uuid,
                      'userData': UserSession().userData!,
                    },
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: currentIndex == 1 ? Colors.green : Colors.black,
            ),
            onPressed: () {
              if (currentIndex != 1) {
                String? uuid = UserSession().userId;
                if (uuid != null && UserSession().userData != null) {
                  fetchData(uuid).then((userData) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => RecordsPage(
                              uuid: uuid,
                              userData:
                                  userData.isEmpty
                                      ? UserSession().userData!
                                      : userData,
                            ),
                      ),
                    );
                  });
                }
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.music_note_rounded,
              color: currentIndex == 2 ? Colors.green : Colors.black,
            ),
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
            icon: Icon(
              Icons.settings,
              color: currentIndex == 3 ? Colors.green : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExportSettingsPage()),
              );
              // Handle settings button press
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

Future<Map<String, dynamic>> fetchData(
  String? uuid, {
  String dataType = "week",
}) async {
  try {
    if (uuid != null) {
      DateTime currentTime = DateTime.now();
      List<Map<String, dynamic>> weeklyData = [];
      int dayCount = 0;
      if (dataType == "week") {
        dayCount = 7;
      } else {
        dayCount = 1;
      }
      for (int i = 0; i < dayCount; i++) {
        if (dayCount == 1) {
          i = 0;
        }
        DateTime day = currentTime.subtract(Duration(days: i));
        DateTime startOfDay = DateTime(day.year, day.month, day.day, 0, 0);
        DateTime endOfDay = DateTime(day.year, day.month, day.day, 23, 59);

        Map<String, dynamic> dailyData = await fsr.fetchSessionDetails(
          startOfDay,
          endOfDay,
        );
        print("User Data for ${day.toLocal()}: $dailyData");
        weeklyData.add(dailyData);
      }
      print("User Data for past $dayCount days: $weeklyData");
      return {"weeklyData": weeklyData};
    } else {
      print("UUID is null, cannot fetch data.");
      return {};
    }
  } catch (e) {
    print("Error fetching data: $e");
  }
  return {};
}
