import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medrhythms/myuipages/bottombar.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/spotify/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:http/http.dart' as http;

// A model class that will representing a track fetched from the Spotify playlist.
class Track {
  final String name;
  final String artist;
  final String albumImageUrl;
  final String uri;

  Track({
    required this.name,
    required this.artist,
    required this.albumImageUrl,
    required this.uri,
  });
}

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({Key? key}) : super(key: key);

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<Track> tracks = [];
  bool isLoading = true;
  String? accessToken;
  final SpotifyService spotifyService = SpotifyService();

  static const String playlistId = "0Hz5WFvUteCFb8M3AgMHs8";

  @override
  void initState() {
    super.initState();
    fetchAccessTokenAndTracks();
  }


  Future<void> fetchAccessTokenAndTracks() async {
    try {
      // This call assumes that you have already authenticated,
      // but getAccessToken can be used to retrieve a valid token.
      accessToken = await SpotifySdk.getAccessToken(
        clientId: "efb55f4d1e874d6fb5fbfdafc57fbaab",
        redirectUrl: "medrhythms://spotifycallback",
      );
    } catch (e) {
      print("Error fetching access token: $e");
    }
    if (accessToken != null) {
      await fetchPlaylistTracks();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
  /// Fetches the tracks for the target playlist from Spotify’s Web API.
  Future<void> fetchPlaylistTracks() async {
    final url = "https://api.spotify.com/v1/playlists/$playlistId";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // The tracks are under data["tracks"]["items"]
        List<dynamic> items = data["tracks"]["items"];
        List<Track> fetchedTracks = [];
        for (var item in items) {
          var trackData = item["track"];
          if (trackData == null) continue;
          String name = trackData["name"] ?? "";
          String uri = trackData["uri"] ?? "";
          // Get the name of the first artist
          List<dynamic> artistsList = trackData["artists"];
          String artist = artistsList.isNotEmpty ? artistsList[0]["name"] : "";
          // Get the album image
          List<dynamic> imagesList = trackData["album"]["images"];
          String albumImageUrl = imagesList.isNotEmpty ? imagesList[0]["url"] : "";
          fetchedTracks.add(Track(
            name: name,
            artist: artist,
            albumImageUrl: albumImageUrl,
            uri: uri,
          ));
        }
        setState(() {
          tracks = fetchedTracks;
          isLoading = false;
        });
      } else {
        print("Failed to load playlist tracks: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching playlist tracks: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  leading: Image.network(
                    track.albumImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(track.name),
                  subtitle: Text(track.artist),
                  onTap: () async {
                    // When a track is tapped, start its playback.
                    await spotifyService.startPlayback(track.uri);
                  },
                );
              },
            ),
      bottomNavigationBar: Bottombar(currentIndex: 2),
    );
  }
}
