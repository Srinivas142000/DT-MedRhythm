import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/helpers/usersession.dart';

class SessionsPage extends StatefulWidget {
  final String uuid;
  final Map<String, dynamic> userData;

  const SessionsPage({super.key, required this.uuid, required this.userData});

  @override
  _SessionsPageState createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  Duration selectedDuration = Duration.zero;
  Bottombar bb = Bottombar();

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

  void _startSession() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NextPage(duration: selectedDuration, uuid: widget.uuid),
      ),
    );
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
                const Text("Start walking session?",
                    style: TextStyle(fontSize: 25)),
                const SizedBox(height: 200),
                Container(
                  width: 300,
                  height: 40,
                  color: Colors.white,
                  alignment: Alignment.topCenter,
                  child: TextButton(
                      onPressed: () => _selectTime(context),
                      child: const Text("Yes")),
                )
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

// Next Page - Timer Handling
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

  @override
  void initState() {
    super.initState();
    remainingTime = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && remainingTime.inSeconds > 0) {
        setState(() {
          remainingTime -= const Duration(seconds: 1);
        });
      } else if (remainingTime.inSeconds == 0) {
        timer.cancel();
        _endSession();
      }
    });
  }

  void _endSession() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionsPage(
            uuid: widget.uuid,
            userData: UserSession().userData!,
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

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });

    if (isPaused) {
      timer?.cancel();
    } else {
      _startTimer();
    }
  }

  void _cancelSession() {
    timer?.cancel();
    _endSession();
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.duration.inSeconds > 0
        ? remainingTime.inSeconds / widget.duration.inSeconds
        : 0;

    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(80),
            margin: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
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
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // GIF Below Walking Text
                      Image.asset(
                        'assets/walking.gif', // Ensure you have this file in assets
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),

                      const SizedBox(height: 10),

                      // Black and White Progress Bar
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.grey,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _togglePause,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: Text(isPaused ? "Resume" : "Pause"),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _cancelSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
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
