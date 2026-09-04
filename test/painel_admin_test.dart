import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AvatarUsuario.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/data/models/Conquista.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/data/repositories/AdminRepository.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/view/PainelAdmin.dart';

import 'fake_post_repository.dart';

/// Substitui o Firestore na aba "Usuários": devolve a lista fixa que o
/// teste montou, e guarda as ações de moderação em vez de escrever.
class FakeAdminRepository implements AdminRepository {
  final List<UserModel> usuarios;
  final List<String> removidos = [];

  /// Quantos posts a remoção em cascata diz ter apagado junto.
  int postsApagadosNaRemocao = 0;

  FakeAdminRepository(this.usuarios);

  @override
  Stream<List<UserModel>> streamUsuarios() => Stream.value(usuarios);

  @override
  Future<void> banirUsuario(String uid, {String? motivo}) async {}

  @override
  Future<void> suspenderUsuario(String uid, {required Duration duracao, String? motivo}) async {}

  @override
  Future<void> reativarUsuario(String uid) async {}

  @override
  Future<int> removerUsuario(String uid) async {
    removidos.add(uid);
    return postsApagadosNaRemocao;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _telaDoPainel(
  List<UserModel> usuarios, {
  FakeAdminRepository? repositorio,
  FakePostRepository? postRepositorio,
  bool escuro = false,
}) {
  return ChangeNotifierProvider(
    create: (_) {
      final tema = ThemeController();
      if (escuro) tema.toggleTheme();
      return tema;
    },
    child: MaterialApp(
      home: PainelAdmin(
        admin: _usuario(cargo: 'admin'),
        repository: repositorio ?? FakeAdminRepository(usuarios),
        postRepository: postRepositorio ?? FakePostRepository(),
      ),
    ),
  );
}

void _noop() {}

UserModel _usuario({
  required String cargo,
  String estadoModeracao = 'ativo',
  String nickname = 'PTKzin',
  String fotoUrl = '',
}) {
  return UserModel(
    uid: 'uid-1',
    nickname: nickname,
    email: 'marcospatrick039474@gmail.com',
    fotoUrl: fotoUrl,
    cargo: cargo,
    categorias: const [],
    status: 'online',
    criadoEm: DateTime(2026, 7, 5),
    ultimoAcesso: null,
    badges: const ['novato'],
    contadores: const {},
    estadoModeracao: estadoModeracao,
  );
}

Widget _telaComMenu({required bool ehAdmin, VoidCallback onPainelAdmin = _noop}) {
  return MaterialApp(
    home: Scaffold(
      endDrawer: MenuLateral(
        isDark: false,
        ehAdmin: ehAdmin,
        onPainelAdmin: onPainelAdmin,
        onRecuperacaoSenha: _noop,
        onPrivacidade: _noop,
        onPoliticaPrivacidade: _noop,
        onConfiguracoes: _noop,
        onSairDaConta: _noop,
      ),
      body: Builder(builder: (context) => Center(child: BotaoMenuLateral(isDark: false))),
    ),
  );
}

/// O painel encadeia animações (troca de aba, menu que fecha, diálogo que
/// abre) e ainda espera o `StreamBuilder` da lista resolver — e o fundo
/// anima em loop, então `pumpAndSettle` nunca terminaria. Alguns frames
/// espaçados cobrem tudo isso.
Future<void> _esperar(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  group('UserModel.ehAdmin', () {
    test('so e admin quem tem cargo "admin"', () {
      expect(_usuario(cargo: 'admin').ehAdmin, isTrue);
      expect(_usuario(cargo: 'vip').ehAdmin, isFalse);
      expect(_usuario(cargo: 'inscrito').ehAdmin, isFalse);
    });

    test('conta sem estadoModeracao gravado conta como ativa', () {
      expect(_usuario(cargo: 'inscrito').estadoModeracao, 'ativo');
    });
  });

  test('o catalogo de conquistas tem a badge de administrador', () {
    expect(catalogoConquistas.any((c) => c.chave == 'admin'), isTrue);
    expect(labelConquista('admin'), 'Administrador');
  });

  testWidgets('"Painel ADM" NAO aparece no menu pra quem nao e admin', (tester) async {
    await tester.pumpWidget(_telaComMenu(ehAdmin: false));

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Painel ADM'), findsNothing);
  });

  testWidgets('"Painel ADM" aparece e chama o callback quando o usuario e admin', (tester) async {
    var abriu = false;
    await tester.pumpWidget(_telaComMenu(ehAdmin: true, onPainelAdmin: () => abriu = true));

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();
    expect(find.text('Painel ADM'), findsOneWidget);

    await tester.tap(find.text('Painel ADM'));
    await tester.pumpAndSettle();

    expect(abriu, isTrue);
    expect(find.text('Menu'), findsNothing);
  });

  // pumpAndSettle não serve neste grupo: o fundo do painel (AuthBackground)
  // anima em loop infinito, então nunca há um frame "estável" pra esperar.
  group('Painel ADM > Usuários', () {
    testWidgets('cada card da lista mostra a foto de perfil do usuário', (tester) async {
      await tester.pumpWidget(_telaDoPainel([
        _usuario(cargo: 'inscrito', nickname: 'Antônio'),
        _usuario(cargo: 'inscrito', nickname: 'Igor'),
      ]));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Antônio'), findsOneWidget);
      expect(find.text('Igor'), findsOneWidget);
      expect(find.byType(AvatarUsuario), findsNWidgets(2));
    });

    testWidgets('o menu de 3 pontinhos tem um ícone em cada opção', (tester) async {
      await tester.pumpWidget(_telaDoPainel([_usuario(cargo: 'inscrito')]));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('conta já moderada troca suspender/banir por reativar, com o ícone certo', (tester) async {
      await tester.pumpWidget(_telaDoPainel([_usuario(cargo: 'inscrito', estadoModeracao: 'banido')]));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.block), findsNothing);
    });

    testWidgets('"Ver perfil" mostra a foto do usuário junto dos dados', (tester) async {
      // A foto do login com Google não aparecia aqui: o modal não tinha
      // avatar nenhum, e na Web o Image.network cru falhava sem o fallback
      // pra <img> (ver FotoPerfilRede).
      await tester.pumpWidget(_telaDoPainel([
        _usuario(cargo: 'inscrito', nickname: 'Antônio', fotoUrl: 'https://lh3.googleusercontent.com/foto'),
      ]));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Ver perfil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Um avatar no card da lista e outro no modal aberto por cima.
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.byType(AvatarUsuario), findsNWidgets(2));
    });
  });

  group('Painel ADM > remover usuário', () {
    testWidgets('a opção aparece no menu, junto das de moderação', (tester) async {
      await tester.pumpWidget(_telaDoPainel([_usuario(cargo: 'inscrito')]));
      await _esperar(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _esperar(tester);

      expect(find.text('Remover usuário'), findsOneWidget);
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    });

    testWidgets('cancelar no diálogo não remove nada', (tester) async {
      final repo = FakeAdminRepository([_usuario(cargo: 'inscrito', nickname: 'Antônio')]);
      await tester.pumpWidget(_telaDoPainel(const [], repositorio: repo));
      await _esperar(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _esperar(tester);
      await tester.tap(find.text('Remover usuário'));
      await _esperar(tester);

      // O diálogo avisa que o login no Firebase sobrevive — é a parte que
      // o clique não deixa óbvia.
      expect(find.textContaining('login dela no Firebase continua existindo'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await _esperar(tester);

      expect(repo.removidos, isEmpty);
    });

    testWidgets('confirmar remove a conta e diz quantos posts foram junto', (tester) async {
      final repo = FakeAdminRepository([_usuario(cargo: 'inscrito', nickname: 'Antônio')])
        ..postsApagadosNaRemocao = 3;
      await tester.pumpWidget(_telaDoPainel(const [], repositorio: repo));
      await _esperar(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _esperar(tester);
      await tester.tap(find.text('Remover usuário'));
      await _esperar(tester);
      await tester.tap(find.text('Remover'));
      await _esperar(tester);

      expect(repo.removidos, ['uid-1']);
      expect(find.textContaining('3 post(s)'), findsOneWidget);
    });
  });

  group('Painel ADM no tema escuro', () {
    // A TabBar tem 6 abas: na janela padrão do teste (800x600) as últimas
    // ficam fora da área tocável. Uma janela de desktop deixa todas
    // alcançáveis, que é como o admin usa o painel de verdade.
    setUp(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
      view.physicalSize = const Size(1400, 1000);
      view.devicePixelRatio = 1;
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });
    });

    testWidgets('o menu de 3 pontinhos não abre branco (texto sumia no fundo)', (tester) async {
      await tester.pumpWidget(_telaDoPainel([_usuario(cargo: 'inscrito')], escuro: true));
      await _esperar(tester);

      final menu = tester.widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>));
      expect(menu.color, isNot(Colors.white));
    });

    testWidgets('no tema claro o menu segue branco', (tester) async {
      await tester.pumpWidget(_telaDoPainel([_usuario(cargo: 'inscrito')]));
      await _esperar(tester);

      final menu = tester.widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>));
      expect(menu.color, Colors.white);
    });

    testWidgets('a lixeira do post fica branca, e não vermelha no fundo roxo', (tester) async {
      final posts = FakePostRepository()
        ..postagensDoStream = [
          PostModel(
            id: 'p1',
            tipo: PostModel.tipoAvisoTexto,
            autorUid: 'uid-1',
            autorNickname: 'PTKzin',
            criadoEm: DateTime(2026, 9, 1),
            texto: 'Aviso de teste',
          ),
        ];

      await tester.pumpWidget(_telaDoPainel(const [], postRepositorio: posts, escuro: true));
      await _esperar(tester);

      // Vai pra aba Posts, onde a lixeira mora.
      await tester.tap(find.text('Posts'));
      await _esperar(tester);

      final lixeira = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
      expect(lixeira.color, Colors.white);
    });

    testWidgets('o post aparece inteiro, sem cortar em duas linhas', (tester) async {
      const textoLongo = 'Primeira linha do aviso. Segunda linha do aviso. '
          'Terceira linha do aviso, que antes era cortada e escondia justamente '
          'o que o admin precisa ler antes de apagar o post.';

      final posts = FakePostRepository()
        ..postagensDoStream = [
          PostModel(
            id: 'p1',
            tipo: PostModel.tipoAvisoTexto,
            autorUid: 'uid-1',
            autorNickname: 'PTKzin',
            criadoEm: DateTime(2026, 9, 1),
            texto: textoLongo,
          ),
        ];

      await tester.pumpWidget(_telaDoPainel(const [], postRepositorio: posts));
      await _esperar(tester);
      await tester.tap(find.text('Posts'));
      await _esperar(tester);

      final texto = tester.widget<Text>(find.text(textoLongo));
      expect(texto.maxLines, isNull);
    });
  });

  // A cascata em si (posts + reserva de nickname + documento) e a regra que
  // barra um não-admin (`ehAdmin()` em firestore.rules) não têm teste de
  // ponta a ponta: dependem do Firestore real ou do emulador — ver
  // ROADMAP.md.
}
