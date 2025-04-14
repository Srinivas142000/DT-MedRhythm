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

    if (_audioManager.songs.isNotEmpty) {
      _selectedSong = _audioManager.songs[0];
      _audioManager.playSong(_selectedSong!);
    }
  }


  String _formatTitle(String path) {
    final fileName = path.split('/').last.replaceAll('.mp3', '');
    return fileName.replaceAll('-', ' ');
  }


  String _formatDuration(Duration d) {
    String twoDigits(int n) => n >= 10 ? "$n" : "0$n";
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final hours = d.inHours;
    if (hours > 0) {
      return "${twoDigits(hours)}:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }

  Future<void> _playNextSong() async {
    if (_selectedSong != null) {
      final songs = _audioManager.songs;
      final currentIndex = songs.indexOf(_selectedSong!);
      final nextIndex = (currentIndex + 1) % songs.length;
      setState(() {
        _selectedSong = songs[nextIndex];
      });
      await _audioManager.playSong(_selectedSong!);
    }
  }

  Future<void> _playPreviousSong() async {
    if (_selectedSong != null) {
      final songs = _audioManager.songs;
      final currentIndex = songs.indexOf(_selectedSong!);
      final prevIndex = (currentIndex - 1 + songs.length) % songs.length;
      setState(() {
        _selectedSong = songs[prevIndex];
      });
      await _audioManager.playSong(_selectedSong!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      bottomNavigationBar: Bottombar(),
      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                alignment: Alignment.centerLeft,
                child: const Text(
                  "MEDRhythms",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              _buildNowPlayingSection(),

              _buildPlaylistList(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlayingSection() {
    final currentSongTitle =
        _selectedSong != null ? _formatTitle(_selectedSong!) : "No song playing";

    final posText = _formatDuration(_currentPosition);
    final durText = _formatDuration(_totalDuration);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Album cover
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

          // Song Title
          Text(
            currentSongTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              activeColor: Colors.green,
              inactiveColor: Colors.grey.shade300,
              min: 0,
              max: _totalDuration.inMilliseconds.toDouble().clamp(0, double.maxFinite),
              value: _currentPosition.inMilliseconds
                  .clamp(0, _totalDuration.inMilliseconds)
                  .toDouble(),
              onChanged: (val) async {
                final seekPos = Duration(milliseconds: val.toInt());
                await _audioManager.audioPlayer.seek(seekPos);
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(posText, style: const TextStyle(fontSize: 12)),
              Text(durText, style: const TextStyle(fontSize: 12)),
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
                onPressed: () => _audioManager.pause(),
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 30,
                onPressed: () async {
                  if (_selectedSong != null) {
                    await _audioManager.playSong(_selectedSong!);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                iconSize: 30,
                onPressed: () {
                  _audioManager.stop();
                  setState(() {
                    _selectedSong = null;
                  });
                },
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

  Widget _buildPlaylistList() {
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
            "More from this playlist",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: _audioManager.songs.map((songPath) {
              final isSelected = songPath == _selectedSong;
              final displayTitle = _formatTitle(songPath);
              return ListTile(
                leading: Icon(
                  Icons.music_note,
                  color: isSelected ? Colors.green : Colors.black,
                ),
                title: Text(
                  displayTitle,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () async {
                  setState(() {
                    _selectedSong = songPath;
                  });
                  await _audioManager.playSong(songPath);
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
          if (_audioManager.playedHistory.isEmpty)
            const Text("No songs played yet.", style: TextStyle(fontSize: 14))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _audioManager.playedHistory.reversed.map((songPath) {
                final title = _formatTitle(songPath);
                return Text(
                  title,
                  style: const TextStyle(fontSize: 14),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
