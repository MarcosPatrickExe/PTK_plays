import 'package:flutter/material.dart';
import 'package:ptk_plays/data/repositories/YouTubeRepository.dart';
import 'package:ptk_plays/data/services/YouTubeService.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'view/home.dart';
import 'view/splash_screen.dart';
import './utils/utils.dart';

void main () {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build( BuildContext context ) {
    
    YouTubeService ytServi = YouTubeService( Utils.APIkey );
    YouTubeRepository ytRepo = YouTubeRepository( ytServi );
    YoutubeViewModel ytVM = YoutubeViewModel(ytRepo);
    
    
    return MaterialApp(
      title: 'PTK plays',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto', // Default, but explicit is fine
        useMaterial3: true,
      ),
      home: SplashScreen( viewmodelYTtemp: ytVM, apiKEYtemp: Utils.APIkey ),
    );
    
  }
  
}
