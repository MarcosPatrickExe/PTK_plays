import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/DegradeTopo.dart';

LinearGradient _gradienteDe(WidgetTester tester, Type tipo) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(tipo), matching: find.byType(Container)),
  );
  return (container.decoration as BoxDecoration).gradient as LinearGradient;
}

Widget _tela(Widget scrim, {VoidCallback? onBotao}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          scrim,
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: 40,
              height: 40,
              child: ElevatedButton(onPressed: onBotao, child: const Text('x')),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('DegradeTopo desenha um degrade de cima pra baixo, terminando transparente', (tester) async {
    await tester.pumpWidget(_tela(const DegradeTopo(isDark: false)));

    final gradiente = _gradienteDe(tester, DegradeTopo);
    expect(gradiente.begin, Alignment.topCenter);
    expect(gradiente.end, Alignment.bottomCenter);
    expect(gradiente.colors.first.opacity, greaterThan(gradiente.colors.last.opacity));
    expect(gradiente.colors.last.opacity, 0.0);
  });

  testWidgets('DegradeRodape espelha o do topo (de baixo pra cima)', (tester) async {
    await tester.pumpWidget(_tela(const DegradeRodape(isDark: false)));

    final gradiente = _gradienteDe(tester, DegradeRodape);
    expect(gradiente.begin, Alignment.bottomCenter);
    expect(gradiente.end, Alignment.topCenter);
    expect(gradiente.colors.last.opacity, 0.0);
  });

  testWidgets('no tema claro a sombra e roxo escuro; no escuro e preta e mais forte', (tester) async {
    await tester.pumpWidget(_tela(const DegradeTopo(isDark: false)));
    final claro = _gradienteDe(tester, DegradeTopo).colors.first;

    await tester.pumpWidget(_tela(const DegradeTopo(isDark: true)));
    final escuro = _gradienteDe(tester, DegradeTopo).colors.first;

    // Claro: roxo escuro da identidade do app, nao um cinza/preto qualquer.
    expect(claro.red, greaterThan(claro.green));
    expect(claro.blue, greaterThan(claro.green));

    // Escuro: preto puro e visivelmente mais opaco que o do tema claro.
    expect(escuro.red, 0);
    expect(escuro.green, 0);
    expect(escuro.blue, 0);
    expect(escuro.opacity, greaterThan(claro.opacity));
  });

  testWidgets('os scrims nao bloqueiam toques nos controles desenhados por cima', (tester) async {
    var tocou = false;
    await tester.pumpWidget(_tela(const DegradeTopo(isDark: false), onBotao: () => tocou = true));

    await tester.tap(find.byType(ElevatedButton));
    expect(tocou, isTrue);
  });
}
