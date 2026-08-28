import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/view/Home.dart';

Widget _comPost(PostModel post) {
  return MaterialApp(
    home: Scaffold(body: PostCard(isDark: false, post: post)),
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

    testWidgets('sem thumbnail em nenhuma plataforma, nao tenta renderizar nenhuma imagem', (tester) async {
      final post = PostModel(
        id: 'p3',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        plataformasAoVivo: {'youtube': const PostPlataformaAoVivo(link: 'https://www.youtube.com/watch?v=abc')},
      );

      await tester.pumpWidget(_comPost(post));

      expect(find.byType(Image), findsNothing);
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

  // O toque nas badges (abre a live via url_launcher) nao tem teste
  // automatizado: assim como em test/politica_privacidade_test.dart, o
  // url_launcher depende do canal de plataforma nativo, que nao existe
  // neste ambiente de `flutter test` - so a logica de renderizacao acima
  // (qual link vai em qual badge, na ordem certa) e validada.
}
