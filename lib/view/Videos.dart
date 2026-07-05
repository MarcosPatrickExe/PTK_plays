import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'package:url_launcher/url_launcher.dart' as launcher_url;
import '../components/Header.dart';
import '../data/models/VideoNotification.dart';
import '../components/VideoCard.dart';
import '../utils/ThemeController.dart';

class Videos extends StatefulWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKEY;
  final AuthViewModel authViewModel;

  const Videos({
    super.key,
    required this.viewmodelYT,
    required this.apiKEY,
    required this.authViewModel,
  });

  @override
  State<Videos> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<Videos> {

  late Future<List<VideoNotification>> _videosCards;
  static List<VideoNotification>? _loadedVideoCards;

  @override
  void initState() {
    super.initState();

    if (_VideoScreenState._loadedVideoCards == null) {
      _videosCards = widget.viewmodelYT.loadVideos();
    }
  }

  void _abrirVideo( String videoId ) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    if( await launcher_url.canLaunchUrl(url) ){
      await launcher_url.launchUrl(url, mode: launcher_url.LaunchMode.externalApplication);
    } else {
      mostrarErroCustom(context, title: "Ops!", msg: "Não foi possível abrir o vídeo :/");
    }
  }

  @override
  Widget build( BuildContext context ) {
    bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight)),
          Positioned.fill(child: AuthBackground(isDark: isDark)),
          SafeArea(
            child: Column(
              children: [
                buildHeader(title: "Vídeos", widgetContext: context),
                Expanded(
                  child: ( _VideoScreenState._loadedVideoCards != null)
                      ? ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _VideoScreenState._loadedVideoCards?.length ,
                          itemBuilder: (ctx, index) {

                            if (index < _VideoScreenState._loadedVideoCards!.length) { // necessario pra evitar erro de 'out of range'

                              return VideoCard(
                                notification: _VideoScreenState._loadedVideoCards![index],
                                isDark: isDark,
                                onTap: () {
                                  this._abrirVideo( _VideoScreenState._loadedVideoCards![index].videoID );
                                },
                              );
                            }
                          },
                        )
                      : FutureBuilder(
                          future: this._videosCards,
                          builder: (BuildContext bc, AsyncSnapshot<List<VideoNotification>> snapshot) {

                            if (snapshot.connectionState == ConnectionState.waiting) {

                              return Center( child: CircularProgressIndicator(color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight) );

                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (snapshot.hasData) {
                              _VideoScreenState._loadedVideoCards = snapshot.data;

                              return ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final notification = snapshot.data![index];

                                  return VideoCard(
                                    notification: notification,
                                    isDark: isDark,
                                    onTap: () {
                                      this._abrirVideo( notification.videoID );
                                    },
                                  );
                                },
                              );
                            } else {
                              return Center(child: Text('Nenhuma postagem encontrada :/'));
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: buildBottonNavBar(
        currentIndex: 1,
        widgetContext: context,
        isDark: isDark,
        apiKey: widget.apiKEY,
        ytViewModel: widget.viewmodelYT,
        authViewModel: widget.authViewModel,
      ),
    );
  }
}
