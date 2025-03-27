import 'package:flutter/material.dart';
import 'package:medrhythms/userappactions/sessions.dart';

class SyncButton extends StatefulWidget {
  @override
  _SyncButtonState createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool isSyncing = false;
  int selectedMinutes = 1;

  Future<void> _syncSession(Duration duration) async {
    // Simulate the sync session process
    await Future.delayed(duration);
    // You can replace this with your actual sync logic
  }

  Future<void> _handleSync() async {
    setState(() {
      isSyncing = true;
    });

    try {
      final sessions = Sessions();
      await sessions.syncSession(Duration(minutes: selectedMinutes));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sync successful!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() {
      isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Sync Duration: ${selectedMinutes ?? 1} min",
              style: TextStyle(fontSize: 15),
            ),
            Slider(
              value: selectedMinutes.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: "${selectedMinutes} min",
              onChanged: (value) {
                setState(() {
                  selectedMinutes = value.toInt();
                });
                _handleSync(); // Automatically trigger sync when duration is selected
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: isSyncing ? null : _handleSync,
          icon:
              isSyncing
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Icon(Icons.sync),
          label: Text(
            isSyncing
                ? "Syncing.."
                : (selectedMinutes == null
                    ? "Select Duration"
                    : "Sync $selectedMinutes min"),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: TextStyle(fontSize: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
