import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:path_provider/path_provider.dart';
import "package:medrhythms/mypages/readroutes.dart";
import 'package:open_file/open_file.dart'; // Adjust the path as necessary
import 'package:permission_handler/permission_handler.dart';

FirestoreServiceRead fsr = FirestoreServiceRead();

Map<String, dynamic> _convertTimestampsToJsonCompatible(
  Map<String, dynamic> data,
) {
  data.forEach((key, value) {
    if (value is Timestamp) {
      data[key] =
          value.toDate().toIso8601String(); // Convert to ISO 8601 string
    } else if (value is Map) {
      data[key] = _convertTimestampsToJsonCompatible(
        value as Map<String, dynamic>,
      );
    } else if (value is List) {
      data[key] =
          value
              .map(
                (item) =>
                    item is Map
                        ? _convertTimestampsToJsonCompatible(
                          item as Map<String, dynamic>,
                        )
                        : item,
              )
              .toList();
    }
  });
  return data;
}

Future<void> exportUserSessionDataAsJson({
  DateTime? startDate,
  DateTime? endDate,
  required String exportType,
}) async {
  try {
    var sessionData;
    if (exportType == "All") {
      sessionData = await fsr.fetchUserSessionData(
        UserSession().userId!,
        exportOption: exportType,
      );
    } else {
      sessionData = await fsr.fetchUserSessionData(
        UserSession().userId!,
        startTime: startDate,
        endTime: endDate,
        exportOption: exportType,
      ); // Adjust the method call to include start and end times
    }
    // Fetch user session data

    // Convert the data to JSON
    // if (sessionData.containsKey("error") || sessionData["weeklyData"] == null) {
    //   print(
    //     "Error fetching session data: ${sessionData["error"] ?? "Unknown error"}",
    //   );
    //   throw Exception("No Data of User Found!!!");
    // }

    sessionData = _convertTimestampsToJsonCompatible(sessionData);

    final jsonData = jsonEncode(sessionData);

    // Get the directory to store the file
    final directory = await getApplicationDocumentsDirectory();
    var filePath;
    var fileName = "user_session_data.json";
    if (exportType == "All") {
      filePath = '${directory.path}/user_session_data_all.json';
    } else {
      fileName =
          'user_session_data_${startDate?.toIso8601String() ?? 'unknown_start'}_${endDate?.toIso8601String() ?? 'unknown_end'}.json';
      filePath = '${directory.path}/$fileName';
    }

    // Write the JSON data to a file
    final file = File(filePath);
    await file.writeAsString(jsonData);
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final newPath = '${downloadsDir.path}/$fileName';

      final newFile = await file.copy(newPath);

      final result = await OpenFile.open(newFile.path);
      if (result.type != ResultType.done) {
        print('Failed to open file: ${result.message}');
      }
    } else {
      print("Storage permission not granted.");
    }

    print('JSON export successful: $filePath');
  } catch (e) {
    print('Error exporting JSON: $e');
  }
}
