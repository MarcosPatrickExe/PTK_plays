import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ptk_plays/i18n/Idioma.dart';
import 'package:ptk_plays/components/ContaGate.dart';
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

  // Antes do Firebase e antes de qualquer tela: a partir daqui toda frase
  // do app ja sai na lingua certa, inclusive as mensagens de erro que o
  // proprio `initializeApp` pode gerar.
  //
  // So aqui, e nunca dentro do catalogo: se a deteccao morasse no global,
  // todo `flutter test` viraria ingles (o ambiente de teste responde en-US)
  // e centenas de asserts de texto quebrariam sem nada ter mudado no app.
  IdiomaApp.detectar();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext _) => ThemeController()),
        ChangeNotifierProvider(create: (BuildContext _) => IdiomaController()),
      ],
      child: const MyApp(),
    )
  );
}
 

class MyApp extends StatelessWidget {
  
  const MyApp({ Key? key }) : super(key: key);

  // Fica fora do build() pra ser o mesmo GlobalKey em toda a vida do app —
  // e o que permite o ContaGate navegar pro Login apos o logout, mesmo
  // vivendo acima da navegacao (fora do alcance de Navigator.of(context)).
  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build( BuildContext context ) {
    
    YouTubeService ytServi = YouTubeService( Utils.APIkey );
    YouTubeRepository ytRepo = YouTubeRepository( ytServi );
    YoutubeViewModel ytVM = YoutubeViewModel(ytRepo);

    AuthRepository authRepo = AuthRepository();
    AuthViewModel authVM = AuthViewModel(authRepo);

    // `watch`, e nao `read`: trocar o idioma nas configuracoes precisa
    // redesenhar o app inteiro, e e esta linha que faz isso acontecer.
    final idioma = context.watch<IdiomaController>().idioma;

    return MaterialApp(
      // O nome do app nao e traduzido de proposito: e marca, nao texto.
      title: 'PTK plays',
      debugShowCheckedModeBanner: true,
      locale: idioma.locale,
      supportedLocales: Idioma.values.map((i) => i.locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: context.read<ThemeController>().getThemeMode,
      navigatorKey: _navigatorKey,
      home: SplashScreen( viewmodelYTtemp: ytVM, apiKEYtemp: Utils.APIkey, authViewModelTemp: authVM ),
      // Cobre QUALQUER tela com a tela de bloqueio quando a conta logada
      // esta banida/suspensa (ver ContaGate) — nao so o Feed.
      builder: (context, child) => ContaGate(
        authViewModel: authVM,
        viewmodelYT: ytVM,
        apiKey: Utils.APIkey,
        navigatorKey: _navigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    
  }
  
}
