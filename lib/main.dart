import 'package:flutter/material.dart';
import 'package:ptk_plays/data/repositories/YouTubeRepository.dart';
import 'package:ptk_plays/data/services/YouTubeService.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/utils/app_theme.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'view/SplashScreen.dart';
import './utils/utils.dart';
import 'package:provider/provider.dart';


void main () {
  
  runApp(
    ChangeNotifierProvider(
      create: (BuildContext _) => ThemeController(),
      child: const MyApp(),
    )
  );
}


class MyApp extends StatelessWidget {
  
  const MyApp({ Key? key }) : super(key: key);

  @override
  Widget build( BuildContext context ) {
    
    YouTubeService ytServi = YouTubeService( Utils.APIkey );
    YouTubeRepository ytRepo = YouTubeRepository( ytServi );
    YoutubeViewModel ytVM = YoutubeViewModel(ytRepo);
    
    return MaterialApp(
      title: 'PTK plays',
      debugShowCheckedModeBanner: true,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: context.read<ThemeController>().getThemeMode,
      home: SplashScreen( viewmodelYTtemp: ytVM, apiKEYtemp: Utils.APIkey ),
    );
    
  }
  
}
