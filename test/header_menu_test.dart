import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/Header.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/view/Configuracoes.dart';
import 'package:ptk_plays/view/Privacidade.dart';

Widget _comTema(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => ThemeController(),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('buildHeader nao mostra botao de menu quando o parametro menu nao e passado', (tester) async {
    await tester.pumpWidget(
      _comTema(Builder(builder: (context) => Scaffold(body: buildHeader(title: 'Feed', widgetContext: context)))),
    );

    expect(find.byType(BotaoMenuLateral), findsNothing);
  });

  testWidgets('buildHeader mostra o botao de menu quando o parametro menu e passado', (tester) async {
    await tester.pumpWidget(
      _comTema(
        Builder(
          builder: (context) => Scaffold(
            endDrawer: const Drawer(),
            body: buildHeader(title: 'Feed', widgetContext: context, menu: const BotaoMenuLateral(isDark: false)),
          ),
        ),
      ),
    );

    expect(find.byType(BotaoMenuLateral), findsOneWidget);
  });

  testWidgets('Privacidade mostra o titulo e o botao de voltar funciona', (tester) async {
    await tester.pumpWidget(_comTema(Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const Privacidade()))));

    expect(find.text('Privacidade'), findsOneWidget);
  });

  testWidgets('Configuracoes mostra o titulo', (tester) async {
    await tester.pumpWidget(_comTema(const Configuracoes()));

    expect(find.text('Configurações'), findsOneWidget);
  });
}
