import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

void _noop() {}

Widget _telaComMenu({
  required VoidCallback onRecuperacaoSenha,
  required VoidCallback onPrivacidade,
  VoidCallback onPoliticaPrivacidade = _noop,
  required VoidCallback onConfiguracoes,
  VoidCallback onSairDaConta = _noop,
  bool isDark = false,
}) {
  return MaterialApp(
    home: Scaffold(
      endDrawer: MenuLateral(
        isDark: isDark,
        onRecuperacaoSenha: onRecuperacaoSenha,
        onPrivacidade: onPrivacidade,
        onPoliticaPrivacidade: onPoliticaPrivacidade,
        onConfiguracoes: onConfiguracoes,
        onSairDaConta: onSairDaConta,
      ),
      body: Builder(
        builder: (context) => Center(
          child: BotaoMenuLateral(isDark: isDark),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('BotaoMenuLateral abre o painel lateral (endDrawer) ao ser tocado', (tester) async {
    await tester.pumpWidget(_telaComMenu(onRecuperacaoSenha: () {}, onPrivacidade: () {}, onConfiguracoes: () {}));

    expect(find.text('Menu'), findsNothing);

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Recuperação de senha'), findsOneWidget);
    expect(find.text('Privacidade'), findsOneWidget);
    expect(find.text('Política de Privacidade'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });

  testWidgets('tocar em "Sair da conta" chama o callback e fecha o painel', (tester) async {
    var chamado = false;
    await tester.pumpWidget(
      _telaComMenu(
        onRecuperacaoSenha: () {},
        onPrivacidade: () {},
        onConfiguracoes: () {},
        onSairDaConta: () => chamado = true,
      ),
    );

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
    expect(find.text('Menu'), findsNothing);
  });

  testWidgets('tocar em "Política de Privacidade" chama o callback e fecha o painel', (tester) async {
    var chamado = false;
    await tester.pumpWidget(
      _telaComMenu(
        onRecuperacaoSenha: () {},
        onPrivacidade: () {},
        onPoliticaPrivacidade: () => chamado = true,
        onConfiguracoes: () {},
      ),
    );

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Política de Privacidade'));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
    expect(find.text('Menu'), findsNothing);
  });

  testWidgets('tocar em "Recuperação de senha" chama o callback e fecha o painel', (tester) async {
    var chamado = false;
    await tester.pumpWidget(
      _telaComMenu(onRecuperacaoSenha: () => chamado = true, onPrivacidade: () {}, onConfiguracoes: () {}),
    );

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recuperação de senha'));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
    expect(find.text('Menu'), findsNothing);
  });

  testWidgets('tocar em "Privacidade" chama o callback correspondente', (tester) async {
    var chamado = false;
    await tester.pumpWidget(
      _telaComMenu(onRecuperacaoSenha: () {}, onPrivacidade: () => chamado = true, onConfiguracoes: () {}),
    );

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacidade'));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
  });

  testWidgets('tocar em "Configurações" chama o callback correspondente', (tester) async {
    var chamado = false;
    await tester.pumpWidget(
      _telaComMenu(onRecuperacaoSenha: () {}, onPrivacidade: () {}, onConfiguracoes: () => chamado = true),
    );

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
  });

  testWidgets('painel ocupa um pouco mais da metade da largura da tela', (tester) async {
    await tester.pumpWidget(_telaComMenu(onRecuperacaoSenha: () {}, onPrivacidade: () {}, onConfiguracoes: () {}));

    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    final larguraTela = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final drawerSize = tester.getSize(find.byType(Drawer));

    expect(drawerSize.width, greaterThan(larguraTela / 2));
    expect(drawerSize.width, lessThan(larguraTela));
  });

  testWidgets('painel usa fundo branco opaco no modo claro', (tester) async {
    await tester.pumpWidget(
      _telaComMenu(onRecuperacaoSenha: () {}, onPrivacidade: () {}, onConfiguracoes: () {}, isDark: false),
    );
    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    final containerClaro = tester.widget<Container>(
      find.descendant(of: find.byType(Drawer), matching: find.byType(Container)).first,
    );
    expect((containerClaro.decoration as BoxDecoration).color, AuthTheme.menuBgLight);
    expect((containerClaro.decoration as BoxDecoration).gradient, isNull);
  });

  testWidgets('painel usa o gradiente branco+roxo opaco no modo escuro', (tester) async {
    await tester.pumpWidget(
      _telaComMenu(onRecuperacaoSenha: () {}, onPrivacidade: () {}, onConfiguracoes: () {}, isDark: true),
    );
    await tester.tap(find.byType(BotaoMenuLateral));
    await tester.pumpAndSettle();

    final containerEscuro = tester.widget<Container>(
      find.descendant(of: find.byType(Drawer), matching: find.byType(Container)).first,
    );
    expect((containerEscuro.decoration as BoxDecoration).gradient, AuthTheme.menuBgGradientDark);
  });
}
