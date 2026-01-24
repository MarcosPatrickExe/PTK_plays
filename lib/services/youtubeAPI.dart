import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../utils/utils.dart';

Future<List<String>> fetchVideos() async {
  final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
    'key': Utils.APIkey,
    'part': 'snippet',
    'channelId': Utils.channelID,
    'order': 'date',
    // 'maxResults': '10',
    'type': 'video',
  });

  final Response channelResponse = await http.get(uri);

  if (channelResponse.statusCode == 200) {
    var data = json.decode(channelResponse.body);
    final items = data['items'];

    print('\n\n \n \n \n=======================================================================> \n\n');

    for (var ite in items) {
      print(ite['snippet']);
      
      // print('Video name: ${ite['snippet']['title']}');
    }

    print('\n\n \n \n \n=======================================================================> \n\n');

    return Future.value(items);
  } else {
    throw Exception('Erro ${channelResponse.statusCode}: ${channelResponse.body}');
  }
}
