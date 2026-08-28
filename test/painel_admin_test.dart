import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/data/models/Conquista.dart';
import 'package:ptk_plays/data/models/UserModel.dart';

void _noop() {}

UserModel _usuario({required String cargo, String estadoModeracao = 'ativo'}) {
  return UserModel(
    uid: 'uid-1',
    nickname: 'PTKzin',
    email: 'marcospatrick039474@gmail.com',
    fotoUrl: '',
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

  // As seções do painel em si (lista de usuários, banir/suspender) não têm
  // teste de widget aqui: dependem do Firestore real (AdminRepository), que
  // não existe neste ambiente. A regra que de fato barra um não-admin está
  // em firestore.rules (`ehAdmin()`), e precisa ser validada com o
  // emulador ou em produção — ver ROADMAP.md.
}
