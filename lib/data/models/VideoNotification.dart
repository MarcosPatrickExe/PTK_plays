class VideoNotification {
  final String videoTitle;
  final String channelTittle;
  final String thumbnailUrl;
  final String avatarUrl;
  final String publishedAt;

  const VideoNotification({
    required this.videoTitle,
    required this.channelTittle,
    required this.thumbnailUrl,
    required this.avatarUrl,
    required this.publishedAt,
  });
  

  factory VideoNotification.fromJson( Map<String, dynamic> content ) {

    print('\n\n \n \n \n=======================================================================> \n\n');
    print('video title: ${content['snippet']['title']}');
    print('video title: ${content['snippet']['channelTitle']}');
    print('video title: ${content['snippet']['publishedAt']}');
    
    print('\n\n \n \n \n=======================================================================> \n\n');

    return VideoNotification(
      videoTitle: content['snippet']['title'],
      channelTittle: content['snippet']['channelTitle'],
      thumbnailUrl: content['snippet']['thumbnails']['high']['url'],
      avatarUrl: "https://yt3.googleusercontent.com/4mCK-MnbSW_HtTjUoH96315rCeYtnlSk6hBpxN0K3TzB3iz8YZJZOcdWKcWelYS-0GRJih4CoQ=s160-c-k-c0x00ffffff-no-rj",
      publishedAt: content['snippet']['publishedAt'],
    );
  }
}
