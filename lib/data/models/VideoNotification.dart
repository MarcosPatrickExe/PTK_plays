class VideoNotification {
  final String videoTitle;
  final String channelTittle;
  final String thumbnailUrl;
  final String avatarUrl;
  final String publishedAt;
  final String videoID;

  /// Mesma miniatura, por outro dominio. `thumbnailUrl` vem da API do
  /// YouTube apontando pra `i.ytimg.com`, que e bloqueado por algumas
  /// extensoes de navegador e redes; `img.youtube.com` serve a mesma imagem
  /// e costuma passar. Usado como segunda tentativa em [ImagemRede].
  String get thumbnailAlternativaUrl => 'https://img.youtube.com/vi/\$videoID/hqdefault.jpg';

  const VideoNotification({
    required this.videoTitle,
    required this.channelTittle,
    required this.thumbnailUrl,
    required this.avatarUrl,
    required this.publishedAt,
    required this.videoID
  });
  

  factory VideoNotification.fromJson( Map<String, dynamic> content ) {

    return VideoNotification(
      videoTitle: content['snippet']['title'],
      channelTittle: content['snippet']['channelTitle'],
      thumbnailUrl: content['snippet']['thumbnails']['high']['url'],
      avatarUrl: "https://yt3.googleusercontent.com/4mCK-MnbSW_HtTjUoH96315rCeYtnlSk6hBpxN0K3TzB3iz8YZJZOcdWKcWelYS-0GRJih4CoQ=s160-c-k-c0x00ffffff-no-rj",
      publishedAt: content['snippet']['publishedAt'],
      videoID: content['snippet']['resourceId']['videoId']
    );
  }
}
