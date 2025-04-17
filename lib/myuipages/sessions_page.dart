import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';
import 'package:medrhythms/myuipages/sync_button.dart';
import 'package:medrhythms/userappactions/sessions.dart';

Health h = Health();

/**
 * A StatefulWidget that represents the page where users can start a walking session.
 * It allows the user to select a duration and start the session, 
 * and will navigate to the NextPage upon session start.
 */
class SessionsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData;

  const SessionsPage({Key? key, required this.uuid, required this.userData})
      : super(key: key);

  @override
  _SessionsPageState createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  Duration selectedDuration = Duration.zero;
  Bottombar bb = Bottombar();
  Sessions s = Sessions();

  /**
   * Shows a modal bottom sheet to select the session duration.
   * The user can select the duration and start the session once selected.
   */
  Future<void> _selectTime(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: selectedDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    setState(() {
                      selectedDuration = newDuration;
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startSession();
                },
                child: const Text(
                  "Start Session",
                  style: TextStyle(color: Colors.blue, fontSize: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /**
   * Starts the walking session with the selected duration.
   * Navigates to the next page immediately after starting the session.
   */
  void _startSession() async {
    final userId = UserSession().userId;
    if (userId != null) {
      s.startLiveWorkout(h, userId, selectedDuration);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NextPage(duration: selectedDuration, uuid: widget.uuid),
        ),
      );
    } else {
      print("User ID is null");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Walking Sessions",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: const Color.fromARGB(255, 170, 164, 164),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Start walking session?", style: TextStyle(fontSize: 25)),
                const SizedBox(height: 200),
                Container(
                  width: 300,
                  height: 40,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => _selectTime(context),
                    child: const Text("Yes"),
                  ),
                ),
                const SizedBox(height: 20),
                SyncButton(),
              ],
            ),
          ),
          if (selectedDuration.inMinutes > 0)
            Text(
              "Selected duration: ${selectedDuration.inMinutes} minutes",
              style: const TextStyle(fontSize: 16),
            ),
          const Spacer(),
          bb,
        ],
      ),
    );
  }
}
/**
 * A StatefulWidget that represents the next page during the walking session.
 * It handles the countdown timer for the session, and allows the user to pause, resume or cancel the session.
 */
class NextPage extends StatefulWidget {
  final Duration duration;
  final String uuid;

  const NextPage({Key? key, required this.duration, required this.uuid})
      : super(key: key);

  @override
  _NextPageState createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  late Duration remainingTime;
  Timer? timer;
  bool isPaused = false;
  Bottombar bb = Bottombar();
  Sessions s = Sessions();

  @override
  void initState() {
    super.initState();
    remainingTime = widget.duration;
    _startTimer(s, remainingTime);
  }

  void _startTimer(Sessions s, Duration selectedDuration) {
  /**
   * Starts a countdown timer for the session.
   * Decreases the remaining time by one second until the session ends.
   */

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && remainingTime.inSeconds > 0) {
        setState(() {
          remainingTime -= const Duration(seconds: 1);
        });
      } else if (remainingTime.inSeconds == 0) {
        timer.cancel();
        _endSession(s, selectedDuration);
      }
    });
  }

 /**
 * Toggles the paused state of the session.
 *
 * When paused:
 *  - Cancels the session timer
 *  - Pauses audio playback
 * When resumed:
 *  - Resumes audio playback
 *  - Restarts the session timer
 *
 * @returns {Future<void>} Completes when pause or resume actions are done.
 * @private
 */
Future<void> _togglePause() async {
  setState(() {
    isPaused = !isPaused;
  });
  if (isPaused) {
    timer?.cancel();
    await s.audioManager.pause();
    print("Session paused and music paused.");
  } else {
    await s.audioManager.resume();
    _startTimer(s, remainingTime);
    print("Session resumed and music resumed.");
  }
}

  void _cancelSession(Duration selectedDuration) {
    timer?.cancel();
    _endSession(s, selectedDuration);
  }

  /**
   * Ends the current session and saves the session data.
   */
  void _endSession(Sessions s, Duration selectedDuration) async {
    await s.stopLiveWorkout(h, UserSession().userId!, selectedDuration);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionsPage(
            uuid: widget.uuid,
            userData: UserSession().userData ?? {},
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double progress = widget.duration.inSeconds > 0
        ? (widget.duration.inSeconds - remainingTime.inSeconds) /
            widget.duration.inSeconds
        : 0;
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(80),
            margin: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            child: Column(
              children: [
                Container(
                  color: Colors.black,
                  width: 380,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      const Text(
                        "Walking",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Image(
                        image: AssetImage('images/walking.gif'),
                        width: MediaQuery.of(context).size.width,
                        height: 100,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  minHeight: 8,
                ),
                Container(
                  width: double.infinity,
                  color: Colors.grey,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _togglePause,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: Text(isPaused ? "Resume" : "Pause"),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _cancelSession(remainingTime),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bb,
    );
  }
}