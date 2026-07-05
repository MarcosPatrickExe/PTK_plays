import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ptk_plays/data/repositories/AuthRepository.dart';
import 'package:ptk_plays/data/repositories/YouTubeRepository.dart';
import 'package:ptk_plays/data/services/YouTubeService.dart';
import 'package:ptk_plays/firebase_options.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/utils/app_theme.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'view/SplashScreen.dart';
import './utils/utils.dart';
import 'package:provider/provider.dart';


Future<void> main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

    AuthRepository authRepo = AuthRepository();
    AuthViewModel authVM = AuthViewModel(authRepo);

    return MaterialApp(
      title: 'PTK plays',
      debugShowCheckedModeBanner: true,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: context.read<ThemeController>().getThemeMode,
      home: SplashScreen( viewmodelYTtemp: ytVM, apiKEYtemp: Utils.APIkey, authViewModelTemp: authVM ),
    );
    
  }
  
}
