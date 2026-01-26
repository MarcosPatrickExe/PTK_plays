import '../services/YouTubeService.dart';
import '../models/video_notification.dart';


class YouTubeRepository {
  final YouTubeService _serviceYT;
  YouTubeRepository(this._serviceYT);



  Future<List<VideoNotification>> getChannelVideos() async {
    
    final List<dynamic> listVideos = await _serviceYT.fetchVideos();
    
    return listVideos
              .map<VideoNotification>( 
                 ( dynamic video) => VideoNotification.fromJson(video) )
                  .toList();
  }
  
  
  
}
