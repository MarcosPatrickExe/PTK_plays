import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/view/Home.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../components/Header.dart';
import '../data/models/VideoNotification.dart';
import '../components/VideoCard.dart';
import '../utils/app_theme.dart';
import '../utils/ThemeController.dart';


class Videos extends StatefulWidget {
  final YoutubeViewModel _viewmodelYT;
  final String _apiKEY;
  
  YoutubeViewModel get getViewModelYT => this._viewmodelYT;
  String get getAPIkey => this._apiKEY;

  Videos({required viewmodelYT, required apiKEY}): this._viewmodelYT = viewmodelYT, this._apiKEY = apiKEY;

  @override
  State<Videos> createState() => _VideoScreenState();
}


class _VideoScreenState extends State<Videos> {
  
  late Future<List<VideoNotification>> _videosCards;
  List<VideoNotification>? _loadedVideoCards;

  @override
  void initState() {
    super.initState();
    
    if(_loadedVideoCards == null) {
      _videosCards = super.widget.getViewModelYT.loadVideos();
    }
  }

  @override
  Widget build( BuildContext context ) {
    bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      // BODY
      body: Container(
        decoration: BoxDecoration( gradient: isDark ? AppThemes.darkBackground : AppThemes.lightBackground),
        child: SafeArea(
          child: Column(
            children: [
              buildHeader(title: "Videos", widgetContext: context),
              Expanded(
              
                child:
                  ( _loadedVideoCards != null )
                  
                  ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (ctx, index){
                      
                      if(index < _loadedVideoCards!.length ){ // necessario pra evitar erro de 'out of range'
            
                        return VideoCard(
                          notification: _loadedVideoCards![index],
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar( 
                              SnackBar( content: Text('Clicked: ${ _loadedVideoCards![index].videoTitle}') )
                            );
                          },
                        );
                      }
                       
                    },
                  )
                  : FutureBuilder(
                    future: this._videosCards,
                    builder: (BuildContext bc, AsyncSnapshot<List<VideoNotification>> snapshot) {
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show a loading indicator while waiting for data

                        return Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 213, 25, 255)));
                        
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                        
                      } else if (snapshot.hasData) {
                        this._loadedVideoCards = snapshot.data;
                        
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final notification = snapshot.data![index];

                            return VideoCard(
                              notification: notification,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clicked: ${notification.videoTitle}')));
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
      ),

      // BOTTOM
      bottomNavigationBar: buildBottonNavBar( 
           currentIndex: 1,
           widgetContext: context, 
           isDark: isDark, 
           apiKey: super.widget.getAPIkey, 
           ytViewModel: super.widget.getViewModelYT  
      )
    );
  }
}
