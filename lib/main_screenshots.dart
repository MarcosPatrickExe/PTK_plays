// Harness temporario para gerar screenshots de App Store com dados fake,
// sem tocar o Firebase de producao (nem inicializa o SDK). Nao faz parte do
// app publicado.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/data/models/VideoNotification.dart';
import 'package:ptk_plays/data/repositories/PostRepository.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/utils/app_theme.dart';
import 'package:ptk_plays/view/Cadastro.dart';
import 'package:ptk_plays/view/Home.dart';
import 'package:ptk_plays/view/Login.dart';
import 'package:ptk_plays/view/Profile.dart';
import 'package:ptk_plays/view/SplashScreen.dart';
import 'package:ptk_plays/view/Videos.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';

/// Resolve pra URL do asset bundle (assets/mock_photos/*, declarado no
/// pubspec.yaml) servido pelo proprio app. Evita depender de qualquer
/// dominio externo pra mostrar uma imagem de verdade (nao um icone de erro
/// quebrado) nos cards, ja que dominios de imagem externos (picsum,
/// YouTube, etc.) estao bloqueados neste ambiente.
String _mockPhoto(String filename) => Uri.base.resolve('assets/assets/mock_photos/$filename').toString();

final UserModel _usuarioFake = UserModel(
  uid: 'uid-fake-001',
  nickname: 'PatrickGamer',
  email: 'patrick@ptkplays.com',
  fotoUrl: '',
  cargo: 'vip',
  categorias: const ['gamer', 'streamer'],
  status: 'online',
  criadoEm: DateTime(2024, 3, 12),
  ultimoAcesso: DateTime(2026, 7, 6),
  badges: const ['Fundador', '100 dias seguidos'],
  contadores: const {'comentarios': 42, 'curtidas': 318, 'cliquesLive': 15},
);

/// Implementa (em vez de estender) AuthViewModel pra nunca tocar em
/// FirebaseAuth/Firestore, ja que o Firebase JS SDK nao carrega neste
/// ambiente (gstatic.com bloqueado).
class FakeAuthViewModel implements AuthViewModel {
  @override
  bool get usuarioLogado => true;

  @override
  String? get uidAtual => _usuarioFake.uid;

  @override
  Stream<UserModel?> streamUsuarioAtual() => Stream.value(_usuarioFake);

  @override
  Future<void> logout() async {}

  @override
  Future<String?> loginComGoogle() async => null;

  @override
  Future<String?> loginComApple() async => null;

  @override
  Future<String?> excluirConta({required String senha}) async => null;

  @override
  Future<String?> cadastrar({
    required String nickname,
    required String email,
    required String senha,
  }) async =>
      null;

  @override
  Future<String?> login({required String loginOuEmail, required String senha}) async => null;
}

class FakePostRepository implements PostRepository {
  static final List<PostModel> _posts = [
    PostModel(
      id: 'p1',
      tipo: PostModel.tipoAoVivo,
      autorUid: 'uid-canal',
      autorNickname: 'PTK Plays',
      criadoEm: DateTime.now().subtract(const Duration(minutes: 8)),
      texto: 'Bora de Elden Ring hoje! Chega lá pra jogar junto 🎮',
      linksPorPlataforma: const {
        'youtube': 'https://youtube.com/watch?v=fake',
        'twitch': 'https://twitch.tv/ptk_joga',
      },
    ),
    PostModel(
      id: 'p2',
      tipo: PostModel.tipoEnquete,
      autorUid: 'uid-canal',
      autorNickname: 'PTK Plays',
      criadoEm: DateTime.now().subtract(const Duration(hours: 3)),
      titulo: 'Qual jogo a gente encara na live de sexta?',
      opcoes: const [
        PostOpcaoEnquete(texto: 'Elden Ring', votos: 132),
        PostOpcaoEnquete(texto: 'Hollow Knight: Silksong', votos: 208),
        PostOpcaoEnquete(texto: 'Baldur\'s Gate 3', votos: 76),
      ],
      votantes: const ['uid-fake-001'],
      votosPorUsuario: const {'uid-fake-001': 1},
    ),
    PostModel(
      id: 'p3',
      tipo: PostModel.tipoAvisoFoto,
      autorUid: 'uid-canal',
      autorNickname: 'PTK Plays',
      criadoEm: DateTime.now().subtract(const Duration(hours: 20)),
      texto: 'Setup novo ficou show! Quem curtiu? 🔥',
      fotoUrl: _mockPhoto('post_photo.jpg'),
    ),
    PostModel(
      id: 'p4',
      tipo: PostModel.tipoAvisoTexto,
      autorUid: 'uid-canal',
      autorNickname: 'PTK Plays',
      criadoEm: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      texto: 'Semana que vem tem sorteio de key pra galera da comunidade, fica ligado!',
    ),
  ];

  @override
  Stream<List<PostModel>> streamPostagens() => Stream.value(_posts);

  @override
  Future<void> votar({required String postId, required int indiceOpcao, required String uid}) async {}
}

class FakeYoutubeViewModel implements YoutubeViewModel {
  static final List<VideoNotification> _videos = [
    VideoNotification(
      videoTitle: 'ELDEN RING mas eu não sei jogar - PARTE 1',
      channelTittle: 'PTK Plays',
      thumbnailUrl: _mockPhoto('video_thumb_1.jpg'),
      avatarUrl: _mockPhoto('avatar.jpg'),
      publishedAt: '2026-07-01T18:00:00Z',
      videoID: 'fake1',
    ),
    VideoNotification(
      videoTitle: 'Reagindo aos memes da galera do chat',
      channelTittle: 'PTK Plays',
      thumbnailUrl: _mockPhoto('video_thumb_2.jpg'),
      avatarUrl: _mockPhoto('avatar.jpg'),
      publishedAt: '2026-06-28T18:00:00Z',
      videoID: 'fake2',
    ),
    VideoNotification(
      videoTitle: 'Live de sexta: Hollow Knight Silksong ao vivo',
      channelTittle: 'PTK Plays',
      thumbnailUrl: _mockPhoto('video_thumb_3.jpg'),
      avatarUrl: _mockPhoto('avatar.jpg'),
      publishedAt: '2026-06-20T18:00:00Z',
      videoID: 'fake3',
    ),
    VideoNotification(
      videoTitle: 'Respondendo perguntas da comunidade #12',
      channelTittle: 'PTK Plays',
      thumbnailUrl: _mockPhoto('video_thumb_4.jpg'),
      avatarUrl: _mockPhoto('avatar.jpg'),
      publishedAt: '2026-06-14T18:00:00Z',
      videoID: 'fake4',
    ),
  ];

  @override
  Future<List<VideoNotification>> loadVideos() async => _videos;
}

void main() {
  // fonts.gstatic.com esta bloqueado neste ambiente; sem isso o app trava
  // minutos tentando buscar cada peso de fonte antes de cair no fallback.
  GoogleFonts.config.allowRuntimeFetching = false;

  // ThemeController nao segue o tema do sistema, entao usamos ?theme=dark
  // na URL pra escolher o modo ao gerar os screenshots.
  final themeController = ThemeController();
  if (Uri.base.queryParameters['theme'] == 'dark') {
    themeController.toggleTheme();
  }

  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: const ScreenshotApp(),
    ),
  );
}

class ScreenshotApp extends StatelessWidget {
  const ScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = FakeAuthViewModel();
    final ytVM = FakeYoutubeViewModel();
    const apiKey = '';

    return MaterialApp(
      title: 'PTK plays - screenshots',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: context.watch<ThemeController>().getThemeMode,
      routes: {
        '/splash': (_) => SplashScreen(viewmodelYTtemp: ytVM, apiKEYtemp: apiKey, authViewModelTemp: authVM),
        '/login': (_) => Login(viewmodelYT: ytVM, apiKey: apiKey, authViewModel: authVM),
        '/cadastro': (_) => Cadastro(viewmodelYT: ytVM, apiKey: apiKey, authViewModel: authVM),
        '/home': (_) => HomePage(viewmodelYT: ytVM, apiKEY: apiKey, authViewModel: authVM, postRepository: FakePostRepository()),
        '/videos': (_) => Videos(viewmodelYT: ytVM, apiKEY: apiKey, authViewModel: authVM),
        '/profile': (_) => Profile(viewmodelYT: ytVM, apiKey: apiKey, authViewModel: authVM),
      },
      initialRoute: '/home',
    );
  }
}
