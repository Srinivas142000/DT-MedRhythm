import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:medrhythms/mypages/createroutes.dart';

class DataSyncManager {
  final String _cacheFileName = "session_cache.json";
  final CreateDataService csd = CreateDataService();

  /// 1. STORE
  ///
  /// Saves session data to local file in uploadable format.
  Future<void> store({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required double steps,
    required double distance,
    required double calories,
    required double speed,
    required String source,
  }) async {
    final sessionData = {
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalSteps': steps,
      'distance': distance,
      'calories': calories,
      'speed': speed,
      'source': source,
    };

    final file = await _getCacheFile();
    await file.writeAsString(jsonEncode(sessionData));
    print("Session data stored locally.");
  }

  /// 2. UPLOAD
  ///
  /// Reads session from file and uploads to Firestore.
  Future<void> upload() async {
    final file = await _getCacheFile();
    if (!await file.exists()) {
      print("No session file found to upload.");
      return;
    }

    try {
      final content = await file.readAsString();
      final Map<String, dynamic> session = jsonDecode(content);

      await csd.createSessionData(
        session['userId'],
        DateTime.parse(session['startTime']),
        DateTime.parse(session['endTime']),
        session['totalSteps']?.toDouble() ?? 0.0,
        session['distance']?.toDouble() ?? 0.0,
        session['calories']?.toDouble() ?? 0.0,
        session['speed']?.toDouble() ?? 0.0,
        session['source'],
      );
      print("Session uploaded successfully.");
      removeStore();
    } catch (e) {
      print("Error during session upload: $e");
    }
  }

  /// 3. REMOVE STORE
  ///
  /// Deletes the cached session file.
  Future<void> removeStore() async {
    final file = await _getCacheFile();
    if (await file.exists()) {
      await file.delete();
      print("Cached session file deleted.");
    } else {
      print("No cached file found to delete.");
    }
  }

  /// Utility: Get local file reference
  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_cacheFileName');
  }
}
