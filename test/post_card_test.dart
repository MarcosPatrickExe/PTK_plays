import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/ImagemAdaptativa.dart';
import 'package:ptk_plays/components/VideoPost.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/view/Home.dart';

Widget _comPost(PostModel post) {
  return MaterialApp(
    home: Scaffold(body: PostCard(isDark: false, post: post)),
  );
}

/// Card de mídia dentro de uma lista rolável e numa largura de celular, que
/// é onde ele vive de verdade. Sem isso a imagem, que é proporcional à
/// largura, estoura a altura fixa da tela de teste.
Widget _comPostRolavel(PostModel post) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: ListView(children: [PostCard(isDark: false, post: post)]),
        ),
      ),
    ),
  );
}

void main() {
  group('PostCard - tipo aoVivo', () {
    testWidgets('mostra o titulo, o jogo e o horario de inicio da plataforma ativa', (tester) async {
      final post = PostModel(
        id: 'p1',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        plataformasAoVivo: {
          'twitch': PostPlataformaAoVivo(
            link: 'https://twitch.tv/patrickson_plays',
            titulo: 'Rankeada até de madrugada',
            jogo: 'Valorant',
            iniciadaEm: DateTime(2026, 8, 27, 21, 5),
          ),
        },
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.text('Rankeada até de madrugada'), findsOneWidget);
      expect(find.textContaining('Valorant'), findsOneWidget);
      expect(find.textContaining('21:05'), findsOneWidget);
      expect(find.text('AO VIVO'), findsOneWidget);
    });

    testWidgets('mostra uma badge clicavel por plataforma ativa, na ordem YouTube > Twitch > Kick', (tester) async {
      final post = PostModel(
        id: 'p2',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        plataformasAoVivo: {
          'kick': PostPlataformaAoVivo(link: 'https://kick.com/patrickson_plays'),
          'youtube': PostPlataformaAoVivo(link: 'https://www.youtube.com/watch?v=abc'),
        },
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Kick'), findsOneWidget);
      expect(find.text('Twitch'), findsNothing);

      final ordemDosTextos = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((t) => t == 'YouTube' || t == 'Kick')
          .toList();
      expect(ordemDosTextos, ['YouTube', 'Kick']);
    });

    testWidgets('sem preview possivel em nenhuma plataforma, nao renderiza imagem', (tester) async {
      final post = PostModel(
        id: 'p3',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        // Kick sem thumbnail: o link nao carrega id de video nenhum, entao
        // nao ha de onde deduzir uma miniatura.
        plataformasAoVivo: {'kick': const PostPlataformaAoVivo(link: 'https://kick.com/patrickson_plays')},
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('live do YouTube ganha preview mesmo sem thumbnail vinda da API', (tester) async {
      final post = PostModel(
        id: 'p3b',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        plataformasAoVivo: {'youtube': const PostPlataformaAoVivo(link: 'https://www.youtube.com/watch?v=abc')},
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('sem nenhuma plataforma ativa (post legado), cai no texto generico', (tester) async {
      final post = PostModel(
        id: 'p4',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        texto: 'Corre pra assistir agora!',
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.text('Corre pra assistir agora!'), findsOneWidget);
    });
  });

  group('PostCard - live encerrada', () {
    PostModel _postEncerrado() => PostModel(
          id: 'p9',
          tipo: PostModel.tipoAoVivo,
          autorUid: 'sistema',
          autorNickname: 'PTK Plays',
          criadoEm: DateTime(2026, 8, 27, 21, 0),
          plataformasAoVivo: {
            'twitch': PostPlataformaAoVivo(
              link: 'https://twitch.tv/patrickson_plays',
              titulo: 'Rankeada até de madrugada',
              jogo: 'Valorant',
              iniciadaEm: DateTime(2026, 8, 27, 21, 5),
              aoVivo: false,
              encerradaEm: DateTime(2026, 8, 28, 0, 20),
              duracaoSegundos: 11700, // 3h 15min
              vodUrl: 'https://twitch.tv/videos/123',
            ),
          },
        );

    testWidgets('mostra duração, data de encerramento, jogo e o selo ENCERRADA', (tester) async {
      await tester.pumpWidget(_comPost(_postEncerrado()));

      expect(find.text('ENCERRADA'), findsOneWidget);
      expect(find.text('AO VIVO'), findsNothing);
      expect(find.text('Valorant'), findsOneWidget);
      expect(find.text('Durou 3h 15min'), findsOneWidget);
      expect(find.text('Encerrada em 28/08 às 00:20'), findsOneWidget);
    });

    testWidgets('a badge aponta pra gravação (vodUrl) em vez do link da live', (tester) async {
      final dados = _postEncerrado().plataformasAoVivo['twitch']!;
      expect(dados.linkParaAbrir, 'https://twitch.tv/videos/123');
    });

    testWidgets('enquanto está no ar, a badge aponta pra live e mostra o horário de início', (tester) async {
      final post = PostModel(
        id: 'p10',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime(2026, 8, 27, 21, 0),
        plataformasAoVivo: {
          'kick': PostPlataformaAoVivo(
            link: 'https://kick.com/patrickson_plays',
            jogo: 'Just Chatting',
            iniciadaEm: DateTime(2026, 8, 27, 21, 5),
          ),
        },
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.text('AO VIVO'), findsOneWidget);
      expect(find.text('Começou às 27/08 às 21:05'), findsOneWidget);
      expect(post.plataformasAoVivo['kick']!.linkParaAbrir, 'https://kick.com/patrickson_plays');
    });
  });

  group('PostPlataformaAoVivo.previewUrl', () {
    test('usa a thumbnail da plataforma quando ela manda uma (Twitch/Kick)', () {
      const dados = PostPlataformaAoVivo(
        link: 'https://twitch.tv/patrickson_plays',
        thumbnailUrl: 'https://cdn/preview.jpg',
      );
      expect(dados.previewUrl, 'https://cdn/preview.jpg');
    });

    // O YouTube nao manda thumbnail nenhuma, mas o id do video ja esta no
    // proprio link da live - a miniatura sai dai, sem chamada extra a API.
    test('deduz a miniatura do YouTube a partir do id no link', () {
      const dados = PostPlataformaAoVivo(link: 'https://www.youtube.com/watch?v=abc123');
      expect(dados.previewUrl, 'https://i.ytimg.com/vi/abc123/hqdefault.jpg');
    });

    test('retorna null quando nao da pra deduzir nada (ex: link da Kick)', () {
      const dados = PostPlataformaAoVivo(link: 'https://kick.com/patrickson_plays');
      expect(dados.previewUrl, isNull);
    });

    // Enquanto a transmissao esta no ar, a Twitch serve a previa num
    // endereco previsivel a partir do login do canal - isso faz o card ter
    // imagem mesmo antes das Cloud Functions gravarem thumbnailUrl.
    test('deduz a previa da Twitch pelo login do canal enquanto esta ao vivo', () {
      const dados = PostPlataformaAoVivo(link: 'https://twitch.tv/patrickson_plays');
      expect(
        dados.previewUrl,
        'https://static-cdn.jtvnw.net/previews-ttv/live_user_patrickson_plays-440x248.jpg',
      );
    });

    test('depois de encerrada, nao deduz previa da Twitch (o endereco some)', () {
      const dados = PostPlataformaAoVivo(link: 'https://twitch.tv/patrickson_plays', aoVivo: false);
      expect(dados.previewUrl, isNull);
    });

    test('thumbnailUrl gravado tem prioridade sobre qualquer deducao', () {
      const dados = PostPlataformaAoVivo(
        link: 'https://twitch.tv/patrickson_plays',
        thumbnailUrl: 'https://cdn/preview.jpg',
      );
      expect(dados.previewUrl, 'https://cdn/preview.jpg');
    });
  });

  group('PostPlataformaAoVivo.previewUrlAlternativo', () {
    // i.ytimg.com e bloqueado por algumas extensoes de navegador e redes;
    // img.youtube.com serve a mesma miniatura por outro dominio.
    test('troca o dominio da miniatura do YouTube', () {
      const dados = PostPlataformaAoVivo(link: 'https://www.youtube.com/watch?v=abc123');
      expect(dados.previewUrlAlternativo, 'https://img.youtube.com/vi/abc123/hqdefault.jpg');
    });

    test('nao inventa alternativa pra thumbnail que nao e do YouTube', () {
      const twitch = PostPlataformaAoVivo(link: 'https://twitch.tv/patrickson_plays');
      const semPreview = PostPlataformaAoVivo(link: 'https://kick.com/patrickson_plays');

      expect(twitch.previewUrlAlternativo, isNull);
      expect(semPreview.previewUrlAlternativo, isNull);
    });
  });

  group('PostPlataformaAoVivo.fromDynamic', () {
    test('le o formato atual (mapa com link + extras)', () {
      final dados = PostPlataformaAoVivo.fromDynamic({
        'link': 'https://twitch.tv/patrickson_plays',
        'titulo': 'Rankeada',
        'jogo': 'Valorant',
        'thumbnailUrl': 'https://cdn/preview.jpg',
      });

      expect(dados.link, 'https://twitch.tv/patrickson_plays');
      expect(dados.jogo, 'Valorant');
      expect(dados.thumbnailUrl, 'https://cdn/preview.jpg');
    });

    // Posts criados antes dos extras existirem gravam o link como texto
    // puro - sem esse ramo, um unico post antigo quebrava o Feed inteiro.
    test('le o formato legado (link como texto puro), sem quebrar', () {
      final dados = PostPlataformaAoVivo.fromDynamic('https://twitch.tv/patrickson_plays');

      expect(dados.link, 'https://twitch.tv/patrickson_plays');
      expect(dados.jogo, isNull);
      expect(dados.thumbnailUrl, isNull);
    });
  });

  testWidgets('PostCard renderiza um post legado (linksPorPlataforma com texto puro) sem erro', (tester) async {
    final post = PostModel.fromFirestore('p5', {
      'tipo': PostModel.tipoAoVivo,
      'autorUid': 'sistema',
      'autorNickname': 'PTK Plays',
      'texto': 'Corre pra assistir agora!',
      'linksPorPlataforma': {'twitch': 'https://twitch.tv/patrickson_plays'},
    });

    await tester.pumpWidget(_comPost(post));

    expect(tester.takeException(), isNull);
    expect(find.text('Twitch'), findsOneWidget);
    expect(find.text('Corre pra assistir agora!'), findsOneWidget);
  });

  group('PostCard - autoria e exclusao', () {
    PostModel _postDe({required String cargo}) => PostModel(
          id: 'p20',
          tipo: PostModel.tipoAvisoTexto,
          autorUid: 'uid-autor',
          autorNickname: 'PTKzin',
          autorCargo: cargo,
          criadoEm: DateTime.now(),
          texto: 'Bora de Elden Ring hoje!',
        );

    testWidgets('post de admin mostra o selo ADMIN; de inscrito, nao', (tester) async {
      await tester.pumpWidget(_comPost(_postDe(cargo: 'admin')));
      expect(find.text('ADMIN'), findsOneWidget);

      await tester.pumpWidget(_comPost(_postDe(cargo: 'inscrito')));
      expect(find.text('ADMIN'), findsNothing);
    });

    testWidgets('sem onExcluir, o card nao mostra o menu de 3 pontos', (tester) async {
      await tester.pumpWidget(_comPost(_postDe(cargo: 'inscrito')));

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('com onExcluir, o menu aparece e chama o callback', (tester) async {
      var pediuExclusao = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(
              isDark: false,
              post: _postDe(cargo: 'inscrito'),
              onExcluir: () async => pediuExclusao = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir post'));
      await tester.pumpAndSettle();

      expect(pediuExclusao, isTrue);
    });
  });

  // O toque nas badges (abre a live via url_launcher) nao tem teste
  // automatizado: assim como em test/politica_privacidade_test.dart, o
  // url_launcher depende do canal de plataforma nativo, que nao existe
  // neste ambiente de `flutter test` - so a logica de renderizacao acima
  // (qual link vai em qual badge, na ordem certa) e validada.

  group('PostCard - tipo avisoMidia', () {
    testWidgets('foto e vídeo aparecem no mesmo card, com a legenda', (tester) async {
      final post = PostModel(
        id: 'm1',
        tipo: PostModel.tipoAvisoMidia,
        autorUid: 'uid-admin',
        autorNickname: 'PTK Plays',
        autorCargo: 'admin',
        criadoEm: DateTime.now(),
        texto: 'Setup novo ficou show!',
        fotoUrl: 'https://exemplo/setup.jpg',
        videoUrl: 'https://exemplo/setup.mp4',
      );

      await tester.pumpWidget(_comPostRolavel(post));
      await tester.pump();

      expect(find.text('Setup novo ficou show!'), findsOneWidget);
      expect(find.byType(ImagemAdaptativa), findsOneWidget);
      expect(find.byType(VideoPost), findsOneWidget);
    });

    testWidgets('post só de vídeo não abre espaço de imagem', (tester) async {
      final post = PostModel(
        id: 'm2',
        tipo: PostModel.tipoAvisoMidia,
        autorUid: 'uid-admin',
        autorNickname: 'PTK Plays',
        autorCargo: 'admin',
        criadoEm: DateTime.now(),
        videoUrl: 'https://exemplo/clipe.mp4',
      );

      await tester.pumpWidget(_comPostRolavel(post));
      await tester.pump();

      expect(find.byType(ImagemAdaptativa), findsNothing);
      expect(find.byType(VideoPost), findsOneWidget);
    });

    testWidgets('avisoFoto antigo continua desenhando pelo mesmo caminho', (tester) async {
      final post = PostModel(
        id: 'm3',
        tipo: PostModel.tipoAvisoFoto,
        autorUid: 'uid-canal',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        texto: 'Foto antiga',
        fotoUrl: 'https://exemplo/antiga.jpg',
      );

      await tester.pumpWidget(_comPostRolavel(post));
      await tester.pump();

      expect(find.text('Foto antiga'), findsOneWidget);
      expect(find.byType(ImagemAdaptativa), findsOneWidget);
      expect(find.byType(VideoPost), findsNothing);
    });
  });
}
