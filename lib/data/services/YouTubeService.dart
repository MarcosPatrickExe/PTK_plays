import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:ptk_plays/utils/utils.dart';

class YouTubeService {
  final String _apiKEY;

  YouTubeService( this._apiKEY );

  Future<List<dynamic>> fetchVideos() async {
    
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'key': this._apiKEY,
      'part': 'snippet',
      'channelId': Utils.channelID,
      'order': 'date',
      // 'maxResults': '10',
      'type': 'video',
      'maxResults': '4',
    });

    final Response channelResponse = await http.get(uri);

    if (channelResponse.statusCode == 200) {
      var data = json.decode(channelResponse.body);
      final items = data['items'];

     // print('\n\n \n \n \n=======================================================================> \n\n');
/*
      for (var ite in items) {
        print(ite['snippet']);

        // print('Video name: ${ite['snippet']['title']}');
      }
*/
     // print('\n\n \n \n \n=======================================================================> \n\n');

      return Future.value(items);
      
    } else {
      throw Exception('Erro ${channelResponse.statusCode}: ${channelResponse.body}');
    }
  }
}
