import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/spotify/spotify_service.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({Key? key}) : super(key: key);

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final String playlistUri = "https://open.spotify.com/playlist/5JpANhLlGcgZcLFcrNhL7j";
  bool isPlaying = false;
  SpotifyService spotifyService = SpotifyService();

  Future<void> _togglePlayback() async {
    if (isPlaying) {
      await spotifyService.pausePlayback();
    } else {
      await spotifyService.startPlayback(playlistUri);
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  Future<void> _skipNext() async {
    await spotifyService.skipNext();
  }

  Future<void> _skipPrevious() async {
    await spotifyService.skipPrevious();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text("Now Playing Your Custom Playlist"),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _skipPrevious,
              ),
              ElevatedButton(
                onPressed: _togglePlayback,
                child: Text(isPlaying ? "Pause" : "Play"),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _skipNext,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Bottombar(),
    );
  }
}
