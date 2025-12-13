import 'dart:convert';
import 'package:http/http.dart' as http;

final String apiKey = "YOUR_API_KEY";
final String channelId = "YOUR_CHANNEL_ID"; // e.g., "UC_Fh8jueZhKYjcSNgbQMzog" for Flutter

Future<List<String>> fetchChannelVideoIds() async {
  // 1. First, find the 'uploads' playlist ID for the channel
  String channelUrl = 'https://www.youtube.com/@patrickson_plays';
  var channelResponse = await http.get(Uri.parse(channelUrl));
  var channelData = json.decode(channelResponse.body);
  String uploadsPlaylistId = channelData['items'][0]['contentDetails']['relatedPlaylists']['uploads'];

  // 2. Then, fetch videos from that playlist
  String playlistUrl = 'www.googleapis.com';
  var playlistResponse = await http.get(Uri.parse(playlistUrl));
  var playlistData = json.decode(playlistResponse.body);

  List<String> videoIds = [];
  
  for (var item in playlistData['items']) {
    videoIds.add(item['snippet']['resourceId']['videoId']);
  }
  return videoIds;
}
