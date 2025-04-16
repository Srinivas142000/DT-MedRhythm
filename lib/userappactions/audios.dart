import 'package:audioplayers/audioplayers.dart';

class LocalAudioManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  AudioPlayer get audioPlayer => _audioPlayer;
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

  final List<String> playedHistory = [];

  String? _currentSong;
  double? _currentBpm;
  final double threshold;

  LocalAudioManager({this.threshold = 10.0});

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
    return 100.0;
  }

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

  Future<void> playSongForBpm(double bpm) async {
    String chosenSong = selectSongForBpm(bpm);
    if (chosenSong != _currentSong) {
      await playSong(chosenSong);
    }
    _currentBpm = bpm;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    if (_currentSong != null) {
      await _audioPlayer.play(AssetSource(_currentSong!));
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    _currentBpm = null;
  }
}