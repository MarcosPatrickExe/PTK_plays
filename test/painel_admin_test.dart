import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AvatarUsuario.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/data/models/Conquista.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/data/repositories/AdminRepository.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/view/PainelAdmin.dart';

import 'fake_post_repository.dart';

/// Substitui o Firestore na aba "Usuários": devolve a lista fixa que o
/// teste montou, e guarda as ações de moderação em vez de escrever.
class FakeAdminRepository implements AdminRepository {
  final List<UserModel> usuarios;
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _telaDoPainel(List<UserModel> usuarios) {
  return ChangeNotifierProvider(
    create: (_) => ThemeController(),
    child: MaterialApp(
      home: PainelAdmin(
        admin: _usuario(cargo: 'admin'),
        repository: FakeAdminRepository(usuarios),
        postRepository: FakePostRepository(),
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

  // Banir/suspender de verdade não tem teste de ponta a ponta: a escrita
  // depende do Firestore real e a regra que barra um não-admin está em
  // firestore.rules (`ehAdmin()`), que precisa do emulador ou de produção
  // pra validar — ver ROADMAP.md.
}
