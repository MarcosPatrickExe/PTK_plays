import '../data/repositories/YouTubeRepository.dart';
import '../data/models/video_notification.dart';

class YoutubeViewModel {
  
  final YouTubeRepository _repository;
  YoutubeViewModel(this._repository);




  Future<List<VideoNotification>> loadVideos() async {
    
    return await _repository.getChannelVideos();
  }
}
