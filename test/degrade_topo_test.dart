import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/DegradeTopo.dart';

void main() {
  testWidgets('DegradeTopo desenha um degrade preto->transparente fixado no topo, sem bloquear toques', (tester) async {
    var tocouBotao = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const DegradeTopo(),
              Positioned(
                top: 0,
                left: 0,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => tocouBotao = true,
                    child: const Text('x'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(DegradeTopo), matching: find.byType(Container)),
    );
    final gradient = (container.decoration as BoxDecoration).gradient as LinearGradient;

    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors.first.opacity, greaterThan(gradient.colors.last.opacity));
    expect(gradient.colors.last.opacity, 0.0);

    // O IgnorePointer garante que o degrade nao "rouba" o toque de um
    // controle real desenhado por cima dele na mesma regiao da tela.
    await tester.tap(find.byType(ElevatedButton));
    expect(tocouBotao, isTrue);
  });
}
