class VideoNotification {
  
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String avatarUrl;
  final Duration timeAgo;
  final bool isWatched;

  const VideoNotification({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.avatarUrl,
    required this.timeAgo,
    this.isWatched = false,
  });
  
}
