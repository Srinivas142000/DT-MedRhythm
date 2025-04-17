import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/sessions_page.dart';
import 'package:medrhythms/myuipages/records_page.dart';
import 'package:medrhythms/myuipages/music_player_page.dart'; // Make sure this import is correct.
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/mypages/readroutes.dart';

FirestoreServiceRead fsr = FirestoreServiceRead();

/**
 * A BottomAppBar widget that provides navigation to different pages (Sessions, Records, Music Player, Settings).
 * It displays icons that allow the user to navigate between different pages in the app.
 */
class Bottombar extends StatelessWidget {

  final int currentIndex;

  /**
   * Creates a Bottombar widget.
   * 
   * @param currentIndex [int] The index of the currently selected page (default is 0 for Sessions page).
   */
  Bottombar({this.currentIndex = 0});


  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sessions Page Icon
          IconButton(
            icon: Icon(Icons.nordic_walking),
            onPressed: () {
              String? uuid = UserSession().userId;
              if (uuid != null && UserSession().userData != null) {
                Navigator.pop(context);
                Navigator.pushReplacement(
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
            },
          ),
          // Records Page Icon
          IconButton(
            icon: Icon(Icons.calendar_month_rounded),
            onPressed: () {
              String? uuid = UserSession().userId;
              print("Calendar icon pressed");
              fetchData(uuid).then((userData) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            RecordsPage(uuid: uuid!, userData: userData),
                  ),
                );
              });
            },
          ),
          // Music Player Page Icon
          IconButton(
            icon: Icon(Icons.music_note_rounded),
            onPressed: () {
              print("Music button pressed");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MusicPlayerPage()),
              );
            },
          ),
          // Settings Page Icon
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Add your navigation to Settings here.
              print("Settings button pressed");
            },
          ),
        ],
      ),
    );
  }
}

/**
 * Fetches user data (either weekly or daily) based on the provided UUID.
 * Fetches session data for the last 7 days (default) or for the current day.
 * 
 * @param uuid [String?] The user ID to fetch data for.
 * @param dataType [String] The type of data to fetch. Accepts "week" or "day" (default is "week").
 * 
 * @returns [Future<Map<String, dynamic>>] A Future containing the fetched user data.
 */
Future<Map<String, dynamic>> fetchData(
  String? uuid, {
  String dataType = "week",
}) async {
  try {
    if (uuid != null) {
      DateTime currentTime = DateTime.now();
      List<Map<String, dynamic>> weeklyData = [];
      int dayCount = dataType == "week" ? 7 : 1;
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
  return {}; // Fallback return.
}
