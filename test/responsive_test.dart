import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/Responsive.dart';

void main() {
  Future<Size> tamanhoDoFilho(WidgetTester tester, Size tela, Widget wrapper) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: wrapper));
    return tester.getSize(find.byKey(const Key('filho')));
  }

  group('ResponsiveCenter', () {
    testWidgets('nao restringe largura em tela estreita (celular)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(400, 800),
        ResponsiveCenter(
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      expect(tamanho.width, 400);
    });

    testWidgets('restringe a 50% da largura em tela larga (desktop/web)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1400, 900),
        ResponsiveCenter(
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      expect(tamanho.width, 700); // 1400 * 0.5
    });

    testWidgets('respeita fracao customizada (video cards a 40%)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1000, 900),
        ResponsiveCenter(
          maxWidthFraction: 0.4,
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      expect(tamanho.width, 400); // 1000 * 0.4
    });
  });

  group('ResponsiveMaxWidth', () {
    testWidgets('nao restringe em tela estreita', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(400, 800),
        Center(
          child: ResponsiveMaxWidth(
            child: Container(key: const Key('filho'), color: Colors.red, width: 350, height: 10),
          ),
        ),
      );
      expect(tamanho.width, 350); // largura intrinseca do filho, sem teto aplicado
    });

    testWidgets('aplica teto de 50% em tela larga mesmo se o filho pedir mais', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1400, 900),
        Center(
          child: ResponsiveMaxWidth(
            child: Container(key: const Key('filho'), color: Colors.red, width: 2000, height: 10),
          ),
        ),
      );
      expect(tamanho.width, 700); // 1400 * 0.5, mesmo o filho pedindo 2000
    });
  });
}
