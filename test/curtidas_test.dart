import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/AvatarUsuario.dart';
import 'package:ptk_plays/components/BarraDeCurtidas.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/i18n/Idioma.dart';
import 'package:ptk_plays/view/Home.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';

import 'fake_post_repository.dart';

UserModel _pessoa(String uid) => UserModel(
      uid: uid,
      nickname: uid,
      email: '$uid@teste.com',
      fotoUrl: '',
      avatarPreset: 'gamer',
      cargo: 'inscrito',
      categorias: const [],
      status: 'online',
      criadoEm: DateTime(2026, 1, 1),
      ultimoAcesso: null,
      badges: const [],
      contadores: const {},
    );

PostModel _post({List<String> curtidoPor = const []}) => PostModel(
      id: 'p1',
      tipo: PostModel.tipoAvisoTexto,
      autorUid: 'uid-autor',
      autorNickname: 'PTKzin',
      criadoEm: DateTime.now(),
      texto: 'um aviso',
      curtidoPor: curtidoPor,
    );

void main() {
  tearDown(() => IdiomaApp.definir(Idioma.ptBR));

  group('a contagem sai da lista, e não de um contador separado', () {
    test('post sem ninguém tem zero curtidas', () {
      expect(_post().curtidas, 0);
    });

    test('a contagem acompanha o tamanho da lista', () {
      expect(_post(curtidoPor: ['a', 'b', 'c']).curtidas, 3);
    });

    test('foiCurtidoPor diz se sou eu', () {
      final post = _post(curtidoPor: ['a', 'b']);

      expect(post.foiCurtidoPor('a'), isTrue);
      expect(post.foiCurtidoPor('z'), isFalse);
      // Deslogado não curtiu nada — e sem esta checagem o `contains(null)`
      // seria uma comparação sempre falsa que o compilador não acusa.
      expect(post.foiCurtidoPor(null), isFalse);
    });

    test('post antigo, gravado quando isto era um int, chega com lista vazia', () {
      // Não é perda de dado: antes de existir a lista, ninguém tinha
      // curtido nada — o `curtidas: 0` do Firestore dizia exatamente isso.
      final post = PostModel.fromFirestore('p1', {
        'tipo': PostModel.tipoAvisoTexto,
        'autorUid': 'u',
        'autorNickname': 'PTKzin',
        'curtidas': 0,
      });

      expect(post.curtidoPor, isEmpty);
      expect(post.curtidas, 0);
    });
  });

  group('a barra de curtidas', () {
    Widget tela({
      List<String> curtidoPor = const [],
      bool euCurti = false,
      VoidCallback? onCurtir,
      List<UserModel> perfis = const [],
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BarraDeCurtidas(
            isDark: false,
            curtidoPor: curtidoPor,
            euCurti: euCurti,
            onCurtir: onCurtir,
            carregarPerfis: (uids) async => perfis,
          ),
        ),
      );
    }

    testWidgets('sem curtida nenhuma, convida em vez de mostrar "0"', (tester) async {
      await tester.pumpWidget(tela());
      await tester.pumpAndSettle();

      expect(find.text('Seja a primeira pessoa a curtir'), findsOneWidget);
      // "0 curtidas" só informaria que ninguém quis; o convite diz que o
      // toque é seu.
      expect(find.textContaining('0 curtidas'), findsNothing);
    });

    testWidgets('uma curtida usa o singular', (tester) async {
      await tester.pumpWidget(tela(curtidoPor: ['a'], perfis: [_pessoa('a')]));
      await tester.pumpAndSettle();

      expect(find.text('1 curtida'), findsOneWidget);
    });

    testWidgets('mais de uma usa o plural', (tester) async {
      await tester.pumpWidget(tela(curtidoPor: ['a', 'b'], perfis: [_pessoa('a'), _pessoa('b')]));
      await tester.pumpAndSettle();

      expect(find.text('2 curtidas'), findsOneWidget);
    });

    testWidgets('o coração enche depois do toque', (tester) async {
      await tester.pumpWidget(tela(curtidoPor: ['eu'], euCurti: true, perfis: [_pessoa('eu')]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.text('Descurtir'), findsOneWidget);
    });

    testWidgets('sem sessão o coração aparece, mas não responde', (tester) async {
      // O card continua legível pra quem não entrou; o toque é que não
      // leva a lugar nenhum. Esconder a barra faria o feed mudar de forma
      // dependendo de estar logado.
      await tester.pumpWidget(tela(onCurtir: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      // Nada a assertar além de não explodir: o teste existe pra garantir
      // que tocar sem sessão não derruba a tela.
    });

    testWidgets('tocar chama o callback', (tester) async {
      var chamou = false;
      await tester.pumpWidget(tela(onCurtir: () => chamou = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Curtir'));
      await tester.pump();

      expect(chamou, isTrue);
    });

    testWidgets('comentar e compartilhar aparecem, mas desabilitados', (tester) async {
      // O lugar deles no layout já fica reservado: escondê-los faria a
      // barra mudar de forma quando eles chegarem.
      await tester.pumpWidget(tela());
      await tester.pumpAndSettle();

      expect(find.text('Comentar'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
      expect(find.byType(Tooltip), findsNWidgets(2));
    });

    testWidgets('em inglês, a barra inteira troca de língua', (tester) async {
      IdiomaApp.definir(Idioma.enUS);
      await tester.pumpWidget(tela(curtidoPor: ['a', 'b'], perfis: [_pessoa('a')]));
      await tester.pumpAndSettle();

      expect(find.text('Like'), findsOneWidget);
      expect(find.text('2 likes'), findsOneWidget);
    });
  });

  group('as miniaturas de quem curtiu', () {
    Widget tela({required List<String> curtidoPor, required List<UserModel> perfis}) {
      return MaterialApp(
        home: Scaffold(
          body: BarraDeCurtidas(
            isDark: false,
            curtidoPor: curtidoPor,
            euCurti: false,
            onCurtir: () {},
            // Respeita o limite igual ao repositório de verdade.
            carregarPerfis: (uids) async => perfis.take(maximoDeMiniaturas).toList(),
          ),
        ),
      );
    }

    testWidgets('desenha um avatar por pessoa', (tester) async {
      // É o pedido que originou a feature: o avaliador da loja tem que
      // conseguir ver que gente de verdade interagiu, sem criar conta.
      await tester.pumpWidget(tela(
        curtidoPor: ['a', 'b'],
        perfis: [_pessoa('a'), _pessoa('b')],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarUsuario), findsNWidgets(2));
    });

    testWidgets('acima do limite, o resto vira "+N"', (tester) async {
      await tester.pumpWidget(tela(
        curtidoPor: ['a', 'b', 'c', 'd', 'e'],
        perfis: [_pessoa('a'), _pessoa('b'), _pessoa('c'), _pessoa('d'), _pessoa('e')],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarUsuario), findsNWidgets(maximoDeMiniaturas));
      expect(find.text('+2'), findsOneWidget);
      // A contagem continua dizendo o total, e não o que coube na tela.
      expect(find.text('5 curtidas'), findsOneWidget);
    });

    testWidgets('exatamente no limite não mostra "+0"', (tester) async {
      await tester.pumpWidget(tela(
        curtidoPor: ['a', 'b', 'c'],
        perfis: [_pessoa('a'), _pessoa('b'), _pessoa('c')],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('enquanto os perfis não chegam, a contagem já aparece', (tester) async {
      // A leitura dos perfis é uma ida ao servidor. Segurar a contagem até
      // ela voltar faria o card piscar um vazio em toda rolagem do feed.
      await tester.pumpWidget(tela(curtidoPor: ['a'], perfis: [_pessoa('a')]));
      await tester.pump();

      expect(find.text('1 curtida'), findsOneWidget);
    });
  });

  group('o card do feed', () {
    Widget feed(PostModel post, {String? uidAtual, FakePostRepository? repo}) {
      return MaterialApp(
        home: Scaffold(
          body: ListaDoFeed(
            isDark: false,
            postagens: [post],
            ehAdmin: false,
            uidAtual: uidAtual,
            postViewModel: PostViewModel(repo ?? FakePostRepository()),
          ),
        ),
      );
    }

    testWidgets('tocar em curtir manda curtir, com o uid de quem tocou', (tester) async {
      final repo = FakePostRepository();
      await tester.pumpWidget(feed(_post(), uidAtual: 'eu', repo: repo));
      await tester.pump();

      await tester.tap(find.text('Curtir'));
      await tester.pump();

      expect(repo.curtidas, hasLength(1));
      expect(repo.curtidas.first.uid, 'eu');
      expect(repo.curtidas.first.curtir, isTrue);
    });

    testWidgets('tocar de novo num post que eu já curti manda DESCURTIR', (tester) async {
      // O sentido sai do estado que a tela já tem, e não de uma ida ao
      // servidor pra reler o que ela sabe — é o que faz o gesto parecer
      // instantâneo.
      final repo = FakePostRepository();
      await tester.pumpWidget(feed(_post(curtidoPor: ['eu']), uidAtual: 'eu', repo: repo));
      await tester.pump();

      await tester.tap(find.text('Descurtir'));
      await tester.pump();

      expect(repo.curtidas.first.curtir, isFalse);
    });

    testWidgets('a barra aparece em post de texto', (tester) async {
      await tester.pumpWidget(feed(_post(), uidAtual: 'eu'));
      await tester.pump();

      expect(find.byType(BarraDeCurtidas), findsOneWidget);
    });

    testWidgets('a barra aparece também na enquete', (tester) async {
      // O pedido foi "curtidas pra todos os tipos de post". A enquete é a
      // que mais fácil ficaria de fora, porque ela já tem interação
      // própria.
      final enquete = PostModel(
        id: 'e1',
        tipo: PostModel.tipoEnquete,
        autorUid: 'uid-autor',
        autorNickname: 'PTKzin',
        criadoEm: DateTime.now(),
        titulo: 'Qual jogo?',
        opcoes: const [PostOpcaoEnquete(texto: 'A'), PostOpcaoEnquete(texto: 'B')],
      );

      await tester.pumpWidget(feed(enquete, uidAtual: 'eu'));
      await tester.pump();

      expect(find.byType(BarraDeCurtidas), findsOneWidget);
    });

    testWidgets('a barra aparece também no aviso de live', (tester) async {
      final live = PostModel(
        id: 'l1',
        tipo: PostModel.tipoAoVivo,
        autorUid: 'uid-canal',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime.now(),
        plataformasAoVivo: const {'youtube': PostPlataformaAoVivo(link: 'https://y.t/x')},
      );

      await tester.pumpWidget(feed(live, uidAtual: 'eu'));
      await tester.pump();

      expect(find.byType(BarraDeCurtidas), findsOneWidget);
    });
  });

  // O que NÃO dá pra testar aqui: se as regras do Firestore aceitam a
  // escrita. `podeCurtir()` em `firestore.rules` é avaliada no servidor, e
  // este projeto não tem harness de teste de regras. Conferir à mão, com
  // as regras publicadas:
  //
  //  1. curtir um post de outra pessoa funciona;
  //  2. descurtir funciona, e a contagem volta;
  //  3. curtir com a conta suspensa é recusado (a regra checa
  //     `contaBloqueada()`);
  //  4. a curtida não deixa editar mais nada do post junto — é o que o
  //     `hasOnly(['curtidoPor'])` garante;
  //  5. apagar a conta tira as curtidas dela dos posts dos outros.
}
