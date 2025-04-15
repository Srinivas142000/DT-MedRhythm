import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:path_provider/path_provider.dart';
import "package:medrhythms/mypages/readroutes.dart";
import 'package:open_file/open_file.dart'; // Adjust the path as necessary
import 'package:permission_handler/permission_handler.dart';

FirestoreServiceRead fsr = FirestoreServiceRead();

/**
 * Recursively converts Firestore Timestamps in the data to ISO 8601 string format.
 * 
 * @param data [Map<String, dynamic>] The data map that may contain Firestore Timestamps.
 * @returns [Map<String, dynamic>] The data map with Timestamps converted to ISO 8601 string format.
 */
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

/**
 * Exports the user session data as a JSON file. The data can be for a specific time range or all available data.
 * The data is fetched from Firestore, converted into JSON format, and saved both locally and in the user's Downloads folder.
 * 
 * @param startDate [DateTime?] The start date for the session data (optional).
 * @param endDate [DateTime?] The end date for the session data (optional).
 * @param exportType [String] The type of export ('All' for all data or a specific period).
 * 
 * @returns [Future<void>] A future that completes when the export process is finished.
 */
Future<void> exportUserSessionDataAsJson({
  DateTime? startDate,
  DateTime? endDate,
  required String exportType,
}) async {
  try {
    var sessionData;
    // Fetch session data based on the export type (All or specific date range)
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
      );
    }

    // Convert Firestore timestamps to JSON compatible format
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

    // Write the JSON data to a local file
    final file = File(filePath);
    await file.writeAsString(jsonData);

    // Request storage permission to move the file to Downloads
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final newPath = '${downloadsDir.path}/$fileName';

      final newFile = await file.copy(newPath);

      // Attempt to open the file
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
