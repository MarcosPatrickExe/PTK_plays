import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:ptk_plays/utils/utils.dart';

class YouTubeService {
  final String _apiKEY;
  YouTubeService(this._apiKEY);

  Future<List<dynamic>> fetchVideos() async {
    // Playlist "uploads" do canal: mesmo ID do canal trocando o prefixo UC por UU.
    final String uploadsPlaylistId = Utils.channelID.replaceFirst('UC', 'UU');

    final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
      'key': this._apiKEY,
      'part': 'snippet',
      'playlistId': uploadsPlaylistId,
      'maxResults': '4',
    });

    final Response channelResponse = await http.get(uri, headers: Utils.apiHeaders);

    if (channelResponse.statusCode == 200) {
      var data = json.decode(channelResponse.body);
      final items = data['items'];

      return Future.value(items);
    } else {
      throw Exception('Erro ${channelResponse.statusCode}: ${channelResponse.body}');
    }
  }
}
