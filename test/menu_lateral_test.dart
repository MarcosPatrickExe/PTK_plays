import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/MenuLateral.dart';

Widget _telaComMenu({
  required VoidCallback onRecuperacaoSenha,
  required VoidCallback onPrivacidade,
  required VoidCallback onConfiguracoes,
}) {
  return MaterialApp(
    home: Scaffold(
      endDrawer: MenuLateral(
        isDark: false,
        onRecuperacaoSenha: onRecuperacaoSenha,
        onPrivacidade: onPrivacidade,
        onConfiguracoes: onConfiguracoes,
      ),
      body: Builder(
        builder: (context) => Center(
          child: BotaoMenuLateral(isDark: false),
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
    expect(find.text('Configurações'), findsOneWidget);
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
}
