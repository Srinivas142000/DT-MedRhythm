import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/userappactions/audios.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({Key? key}) : super(key: key);

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final LocalAudioManager _audioManager = LocalAudioManager(threshold: 10.0);
  String? _selectedSong;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioManager.audioPlayer.onPositionChanged.listen((pos) {
      setState(() {
        _currentPosition = pos;
      });
    });
    _audioManager.audioPlayer.onDurationChanged.listen((dur) {
      setState(() {
        _totalDuration = dur;
      });
    });
    
  }

  
  String _formatTitle(String path) {
    final fileName = path.split('/').last;
    var title = fileName.replaceAll('.mp3', '');
    
    title = title.replaceAll(RegExp(r'[\-\_]+'), ' ');
    return title[0].toUpperCase() + title.substring(1);
  }

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

  Future<void> _playSong(String songPath) async {
    setState(() {
      _selectedSong = songPath;
    });
    await _audioManager.playSong(songPath);
  }

  
  Future<void> _pause() async {
    await _audioManager.pause();
  }


  Future<void> _resume() async {
    if (_selectedSong != null) {
      await _audioManager.playSong(_selectedSong!);
    }
  }


  Future<void> _stop() async {
    await _audioManager.stop();
    setState(() {
      _selectedSong = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  
  Future<void> _playNextSong() async {
    if (_selectedSong != null) {
      final currentIndex = _audioManager.songs.indexOf(_selectedSong!);
      final nextIndex = (currentIndex + 1) % _audioManager.songs.length;
      await _playSong(_audioManager.songs[nextIndex]);
    }
  }


  Future<void> _playPreviousSong() async {
    if (_selectedSong != null) {
      final currentIndex = _audioManager.songs.indexOf(_selectedSong!);
      final prevIndex = (currentIndex - 1 + _audioManager.songs.length) % _audioManager.songs.length;
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
            // Header Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "MEDRhythms Music",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            // Now Playing Section
            _buildNowPlayingSection(),
            const Divider(),
            // Playlist Section
            _buildPlaylistSection(),
          ],
        ),
      ),
    );
  }

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
          Text(
            _selectedSong != null ? _formatTitle(_selectedSong!) : "No song playing",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_currentPosition), style: const TextStyle(fontSize: 12)),
              Text(_formatDuration(_totalDuration), style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
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
          _buildSongHistory(),
        ],
      ),
    );
  }

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
                leading: Icon(Icons.music_note, color: isSelected ? Colors.green : Colors.black),
                title: Text(
                  _formatTitle(songPath),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                onTap: () async {
                  // When the user taps a song, play it.
                  await _playSong(songPath);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

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
              ? const Text("No songs played yet.", style: TextStyle(fontSize: 14))
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