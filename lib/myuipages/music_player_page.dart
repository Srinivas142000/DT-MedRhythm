import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/userappactions/audios.dart';
import 'package:audioplayers/audioplayers.dart';

/**
 * Main page for the music player UI.
 * @extends {StatefulWidget}
 */
class MusicPlayerPage extends StatefulWidget {
  /**
   * Creates a new MusicPlayerPage.
   * @param {Key?} [key] - Optional widget key.
   */
  const MusicPlayerPage({Key? key}) : super(key: key);

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

/**
 * State for [MusicPlayerPage], managing playback controls and UI.
 * @extends {State<MusicPlayerPage>}
 */
class _MusicPlayerPageState extends State<MusicPlayerPage> {
  /**
   * Audio manager handles song selection and playback based on BPM thresholds.
   * @type {LocalAudioManager}
   * @private
   */
  final LocalAudioManager _audioManager = LocalAudioManager(threshold: 10.0);

  /** Currently selected song's asset path. @type {String?} @private */
  String? _selectedSong;

  /** Current playback position. @type {Duration} @private */
  Duration _currentPosition = Duration.zero;

  /** Total duration of the loaded song. @type {Duration} @private */
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Listen to playback position updates to update the seek bar.
    _audioManager.audioPlayer.onPositionChanged.listen((pos) {
      setState(() {
        _currentPosition = pos;
      });
    });
    // Listen to duration changes when a new song is loaded.
    _audioManager.audioPlayer.onDurationChanged.listen((dur) {
      setState(() {
        _totalDuration = dur;
      });
    });
  }

  /**
   * TO REPLACES ALL OTHER SYMBOLS IN THE SONG ITLE WITH A SPACE.
   * @param {String} path - Asset path of the song.
   * @returns {String} Formatted song title.
   * @private
   */
  String _formatTitle(String path) {
    final fileName = path.split('/').last;
    var title = fileName.replaceAll('.mp3', '');
    title = title.replaceAll(RegExp(r'[\-\_]+'), ' ');
    return title[0].toUpperCase() + title.substring(1);
  }

  /**
   * Convert a [Duration] into a mm:ss or hh:mm:ss string.
   * @param {Duration} duration - Duration to format.
   * @returns {String} Formatted time string.
   * @private
   */
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /**
   * Play a song and update the selected song state.
   * @param {String} songPath - Asset path of the song to play.
   * @returns {Future<void>}
   * @private
   */
  Future<void> _playSong(String songPath) async {
    setState(() {
      _selectedSong = songPath;
    });
    await _audioManager.playSong(songPath);
  }

  /**
   * Pause current playback.
   * @returns {Future<void>}
   * @private
   */
  Future<void> _pause() async {
    await _audioManager.pause();
  }

  /**
   * Resume playback of the selected song.
   * @returns {Future<void>}
   * @private
   */
  Future<void> _resume() async {
    if (_selectedSong != null) {
      await _audioManager.playSong(_selectedSong!);
    }
  }

  /**
   * Stop playback and reset UI state.
   * @returns {Future<void>}
   * @private
   */
  Future<void> _stop() async {
    await _audioManager.stop();
    setState(() {
      _selectedSong = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  /**
   * Skip to the next song in the playlist.
   * @returns {Future<void>}
   * @private
   */
  Future<void> _playNextSong() async {
    if (_selectedSong != null) {
      final currentIndex = _audioManager.songs.indexOf(_selectedSong!);
      final nextIndex =
          (currentIndex + 1) % _audioManager.songs.length; 
      await _playSong(_audioManager.songs[nextIndex]);
    }
  }

  /**
   * Go back to the previous song in the playlist.
   * @returns {Future<void>}
   * @private
   */
  Future<void> _playPreviousSong() async {
    if (_selectedSong != null) {
      final currentIndex = _audioManager.songs.indexOf(_selectedSong!);
      final prevIndex = (currentIndex - 1 + _audioManager.songs.length) %
          _audioManager.songs.length; 
      await _playSong(_audioManager.songs[prevIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),    
      bottomNavigationBar: Bottombar(), 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "MEDRhythms Music",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Now Playing card with controls and progress
            _buildNowPlayingSection(),
            const Divider(),
            // Playlist listing
            _buildPlaylistSection(),
          ],
        ),
      ),
    );
  }

  /**
   * Builds the "Now Playing" section, showing the playlist album art, title, controls, and song history.
   * @returns {Widget}
   * @private
   */
  Widget _buildNowPlayingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // playlist album art cover
          Container(
            width: 200,
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage("images/logo.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Song title
          Text(
            _selectedSong != null
                ? _formatTitle(_selectedSong!)
                : "No song playing",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Progress slider
          Slider(
            activeColor: Colors.green,
            inactiveColor: Colors.grey.shade300,
            min: 0,
            max: _totalDuration.inMilliseconds.toDouble() > 0
                ? _totalDuration.inMilliseconds.toDouble()
                : 1.0, 
            value: _currentPosition.inMilliseconds
                .clamp(0, _totalDuration.inMilliseconds)
                .toDouble(),
            onChanged: (val) async {
              final seekPos = Duration(milliseconds: val.toInt());
              await _audioManager.audioPlayer.seek(seekPos);
            },
          ),
          // Current and total duration labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Playback controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 30,
                onPressed: _playPreviousSong,
              ),
              IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 30,
                onPressed: _pause,
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 30,
                onPressed: () async {
                  if (_selectedSong != null) {
                    await _playSong(_selectedSong!);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                iconSize: 30,
                onPressed: _stop,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 30,
                onPressed: _playNextSong,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Displays the songs that have been played
          _buildSongHistory(),
        ],
      ),
    );
  }

  /**
   * Constructs the playlist section listing all available songs.
   * @returns {Widget}
   * @private
   */
  Widget _buildPlaylistSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Playlist - MEDRhythms",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: _audioManager.songs.map((songPath) {
              bool isSelected = (songPath == _selectedSong);
              return ListTile(
                leading: Icon(
                  Icons.music_note,
                  color: isSelected ? Colors.green : Colors.black,
                ),
                title: Text(
                  _formatTitle(songPath),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                tileColor:
                    isSelected ? Colors.green.withOpacity(0.1) : null,
                onTap: () async {
                  // Play tapped song
                  await _playSong(songPath);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /**
   * Builds a vertical list of previously played songs.
   * @returns {Widget}
   * @private
   */
  Widget _buildSongHistory() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Song History",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _audioManager.playedHistory.isEmpty
              ? const Text(
                  "No songs played yet.",
                  style: TextStyle(fontSize: 14),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _audioManager.playedHistory.reversed.map((songPath) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _formatTitle(songPath),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}