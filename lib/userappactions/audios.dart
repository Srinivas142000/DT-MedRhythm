import 'package:audioplayers/audioplayers.dart';

/**
 * A class that manages audio playback for local songs, including playing, pausing, resuming, and stopping songs.
 * It also provides functionality for selecting songs based on BPM and maintaining a history of played songs.
 */
class LocalAudioManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;

  // A list of available songs for playback
  final List<String> songs = [
    "audio/Heavy.mp3",
    "audio/All_In_My_Head.mp3",
    "audio/spread-your-legs-97-bpm-instrumental-233227.mp3",
    "audio/crayon-sparklers-beat-89-bpm-186298.mp3",
    "audio/holidays-dancehall-instrumental-106-bpm-231232.mp3",
    "audio/late-flight-from-detroit-em-100-191484.mp3",
    "audio/metal-aggressive-90-bpm-loop-13539.mp3",
    "audio/metal-workout-90-bpm-medium1-13722.mp3",
    "audio/relax-yourself-110-bpm-dancehall-instrumental-233180.mp3",
    "audio/StockTune-Heartbeat Of The Celebration_1744573622.mp3",
    "audio/wet-dreams-101-bpm-instrumental-235130.mp3",
  ];

  // History of played songs
  final List<String> playedHistory = [];

  String? _currentSong;
  double? _currentBpm;
  final double threshold;

  /**
   * Creates a LocalAudioManager with an optional BPM threshold for song selection.
   * 
   * @param threshold [double] The threshold for selecting songs based on BPM (default is 10.0).
   */
  LocalAudioManager({this.threshold = 10.0});

  /**
   * Plays a song from the given song path.
   * If the song is different from the current song, it stops the current song, adds it to the history, and plays the new song.
   * 
   * @param songPath [String] The path of the song to play.
   */
  Future<void> playSong(String songPath) async {
    if (songPath != _currentSong) {
      _currentSong = songPath;
      playedHistory.add(songPath);
      await _audioPlayer.stop();
      try {
        // Play the asset.
        await _audioPlayer.play(AssetSource(songPath));
        print("Playing song: $songPath");
      } catch (e) {
        print("Error playing song: $e");
      }
    }
  }

  /**
   * Determines the ideal BPM for a given song.
   * The BPM is based on the song's title.
   * 
   * @param song [String] The song's path or title.
   * @returns [double] The ideal BPM for the given song.
   */
  double idealBpmForSong(String song) {
    if (song.contains("Heavy")) return 95.0;
    if (song.contains("All_In_My_Head")) return 100.0;
    if (song.contains("spread-your-legs")) return 97.0;
    if (song.contains("crayon-sparklers-beat")) return 89.0;
    if (song.contains("holidays-dancehall")) return 106.0;
    if (song.contains("late-flight")) return 100.0;
    if (song.contains("metal-aggressive")) return 90.0;
    if (song.contains("metal-workout")) return 90.0;
    if (song.contains("relax-yourself")) return 110.0;
    if (song.contains("StockTune")) return 100.0;
    if (song.contains("wet-dreams")) return 101.0;

    return 100.0; // Default BPM if no specific match
  }

  /**
   * Selects a song based on the BPM.
   * If the current song's BPM is close enough to the given BPM, the current song is selected.
   * Otherwise, a different song from the list is selected based on the BPM threshold.
   * 
   * @param bpm [double] The BPM to base the song selection on.
   * @returns [String] The path of the selected song.
   */
  String selectSongForBpm(double bpm) {
    if (_currentSong != null && _currentBpm != null) {
      double currentIdeal = idealBpmForSong(_currentSong!);
      if ((bpm - currentIdeal).abs() < threshold) {
        return _currentSong!;
      }
    }
    return bpm < 100 ? songs[0] : songs[1]; // Default song selection
  }

  /**
   * Selects and plays the appropriate song based on the given BPM.
   * If the selected song is different from the current one, it will be played.
   * 
   * @param bpm [double] The BPM to base the song selection on.
   */
  Future<void> playSongForBpm(double bpm) async {
    String chosenSong = selectSongForBpm(bpm);
    if (chosenSong != _currentSong) {
      await playSong(chosenSong);
    }
    _currentBpm = bpm;
  }

  /**
   * Pauses the currently playing song.
   */
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /**
   * Resumes the currently paused song.
   */
  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  /**
   * Stops the currently playing song, clearing the current song and BPM information.
   */
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _currentBpm = null;
  }
}
