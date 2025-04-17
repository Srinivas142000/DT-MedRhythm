import 'package:audioplayers/audioplayers.dart';

/**
 * Manages local audio playback based on user BPM.
 * A class that manages audio playback for local songs, including playing, pausing, resuming, and stopping songs.
 * It also provides functionality for selecting songs based on BPM and maintaining a history of played songs.
 */
class LocalAudioManager {
  /**
   * The AudioPlayer instance from the audioplayers package.
   * @type {AudioPlayer}
   */
  final AudioPlayer _audioPlayer = AudioPlayer();

  /**
   * @returns {AudioPlayer}
   */
  AudioPlayer get audioPlayer => _audioPlayer;

  /**
   * List of songs.
   * @type {string[]}
   */
  // A list of available songs for playback
  final List<String> songs = [
    "audio/Rose.mp3",
    "audio/Grenade.mp3",
    "audio/Halo.mp3",
    "audio/Roar.mp3",
    "audio/High.mp3",
    "audio/Winter.mp3",
    "audio/Sao_Paulo.mp3",
    "audio/Man_Down.mp3",
    "audio/Miss_independent.mp3",
    "audio/GONE.mp3",
    "audio/Sorry.mp3",
    "audio/Mine.mp3",
    "audio/Switch.mp3",
  ];

  /**
   * History of songs played during the session.
   * @type {string[]}
   */
  final List<String> playedHistory = [];

  /** @type {string?} Currently playing song path. */
  String? _currentSong;

  /** @type {number?} Last BPM used to choose the song. */
  double? _currentBpm;

  /**
   * BPM difference threshold before switching the songs.
   * @type {number}
   */
  final double threshold;

  /**
   * Constructor with an adjustable  BPM threshold.
   * @param {object} [options]
   * @param {number} [options.threshold=10.0] BPM difference threshold.
   * Creates a LocalAudioManager with an optional BPM threshold for song selection.
   * 
   * @param threshold [double] The threshold for selecting songs based on BPM (default is 10.0).
   */
  LocalAudioManager({this.threshold = 10.0});

  /**
   * Returns the ideal BPM for a given song based on the name of the song.
   * @param {string} song - The song name.
   * @returns {number} Ideal BPM.
   */
  double idealBpmForSong(String song) {
    if (song.contains("GONE")) return 190.0;
    if (song.contains("Mine")) return 170.0;
    if (song.contains("Miss_independent")) return 180.0;
    if (song.contains("Man_Down")) return 160.0;
    if (song.contains("Sao_Paulo")) return 150.0;
    if (song.contains("Winter")) return 60.0;
    if (song.contains("Switch")) return 100.0;
    if (song.contains("High")) return 130.0;
    if (song.contains("Roar")) return 90.0;
    if (song.contains("Halo")) return 80.0;
    if (song.contains("Grenade")) return 110.0;
    if (song.contains("Rose")) return 120.0;
    // Fallback BPM if the song isn't recognized.
    return 100.0;
  }

  /**
   * Chooses the best song for a given BPM.
   * - If the current song's ideal BPM is within the threshold, keep playing it.
   * - otherwise it  picks the song whose ideal BPM is closest to `bpm`.
   *
   * @param {number} bpm - The current BPM.
   * @returns {string} Path of the chosen song.
   */
  String selectSongForBpm(double bpm) {
    if (_currentSong != null && _currentBpm != null) {
      double currentIdeal = idealBpmForSong(_currentSong!);
      if ((bpm - currentIdeal).abs() < threshold) {
        return _currentSong!;
      }
    }

    String bestSong = songs[0];
    double minDifference = double.infinity;
    for (String song in songs) {
      double ideal = idealBpmForSong(song);
      double diff = (bpm - ideal).abs();
      if (diff < minDifference) {
        minDifference = diff;
        bestSong = song;
      }
    }
    return bestSong;
  }

  /**
   * Stops any current song playback and plays `songPath` if not already playing.
   *
   * @param {string} songPath - Asset path to play.
   * @returns {Promise<void>}
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
        await _audioPlayer.play(AssetSource(songPath));
        print("Playing song: $songPath");
      } catch (e) {
        print("Error playing song: $e");
      }
    }
  }

  /**
   * Selects and plays the best song for the given BPM.
   *
   * @param {number} bpm - The current BPM.
   * @returns {Promise<void>}
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
   * @returns {Promise<void>}
   */
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /**
   * Resumes playback of the current song.
   * @returns {Promise<void>}
   * Resumes the currently paused song.
   */
  Future<void> resume() async {
    if (_currentSong != null) {
      await _audioPlayer.play(AssetSource(_currentSong!));
    }
  }

  /**
   * Stops playback entirely and resets state.
   * @returns {Promise<void>}
   * Stops the currently playing song, clearing the current song and BPM information.
   */
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _currentBpm = null;
  }
}