import 'package:audioplayers/audioplayers.dart';

/**
 * Manages local audio playback based on user BPM.
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
   */
  Future<void> resume() async {
    if (_currentSong != null) {
      await _audioPlayer.play(AssetSource(_currentSong!));
    }
  }

  /**
   * Stops playback entirely and resets state.
   * @returns {Promise<void>}
   */
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _currentBpm = null;
  }
}