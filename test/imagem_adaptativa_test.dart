import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/ImagemAdaptativa.dart';

void main() {
  group('aspectoDoCard', () {
    test('mantém a proporção da foto quando ela cabe nos limites', () {
      expect(aspectoDoCard(1080, 1080), 1);
      expect(aspectoDoCard(1080, 1350), closeTo(0.8, 0.001)); // 4:5
      expect(aspectoDoCard(1600, 900), closeTo(16 / 9, 0.001));
    });

    test('retrato de celular (9:16) aparece inteiro, sem virar 4:5', () {
      expect(aspectoDoCard(1080, 1920), closeTo(9 / 16, 0.001));
    });

    test('corta o exagero: mais comprida que 9:16 e mais larga que 1.91:1', () {
      expect(aspectoDoCard(500, 3000), aspectoMinimoDoCard);
      expect(aspectoDoCard(3000, 500), aspectoMaximoDoCard);
    });

    test('dimensão inválida cai no quadrado, sem dividir por zero', () {
      expect(aspectoDoCard(0, 100), 1);
      expect(aspectoDoCard(100, 0), 1);
    });
  });

  group('ImagemAdaptativa', () {
    testWidgets('desenha a imagem dentro de um AspectRatio', (tester) async {
      // Em `flutter test` toda requisição de imagem falha, então o que dá
      // pra afirmar aqui é o esqueleto: o card existe e é proporcional
      // (quadrado, o padrão de antes de medir a foto).
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImagemAdaptativa(url: 'https://exemplo/foto.jpg', isDark: false),
          ),
        ),
      );
      await tester.pump();

      final aspecto = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspecto.aspectRatio, 1);
    });
  });
}
