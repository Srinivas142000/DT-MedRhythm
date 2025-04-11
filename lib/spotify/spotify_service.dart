import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  bool isConnected = false;

  Future<void> authenticateSpotify() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: "efb55f4d1e874d6fb5fbfdafc57fbaab",
        redirectUrl: "medrhythms://spotifycallback",
      );
      isConnected = true;
      print("Connected to Spotify!");
    } catch (e) {
      print("Error connecting to Spotify: $e");
    }
  }

  Future<void> startPlayback(String spotifyUri) async {
    if (!isConnected) {
      await authenticateSpotify();
    }
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
      print("Playback started for: $spotifyUri");
    } catch (e) {
      print("Error starting Spotify playback: $e");
    }
  }

  Future<void> pausePlayback() async {
    try {
      await SpotifySdk.pause();
      print("Playback paused");
    } catch (e) {
      print("Error pausing playback: $e");
    }
  }

  Future<void> resumePlayback() async {
    try {
      await SpotifySdk.resume();
      print("Playback resumed");
    } catch (e) {
      print("Error resuming playback: $e");
    }
  }

  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
      print("Skipped to next track");
    } catch (e) {
      print("Error skipping to next track: $e");
    }
  }

  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
      print("Skipped to previous track");
    } catch (e) {
      print("Error skipping to previous track: $e");
    }
  }
}
