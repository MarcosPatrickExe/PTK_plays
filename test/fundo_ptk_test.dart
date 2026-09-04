import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/FundoPTK.dart';

void main() {
  group('FormaDaOnda', () {
    test('topoMaisAlto é o menor dos quatro pontos — onde a onda sobe mais', () {
      const onda = FormaDaOnda(alturaEsquerda: .52, alturaDireita: .46, curvaEsquerda: .58, curvaDireita: .40);
      expect(onda.topoMaisAlto, .40);
    });

    test('formas iguais são iguais, pra evitar repintura à toa', () {
      const a = FormaDaOnda(alturaEsquerda: .5, alturaDireita: .5, curvaEsquerda: .4, curvaDireita: .4);
      const b = FormaDaOnda(alturaEsquerda: .5, alturaDireita: .5, curvaEsquerda: .4, curvaDireita: .4);
      const c = FormaDaOnda(alturaEsquerda: .5, alturaDireita: .5, curvaEsquerda: .4, curvaDireita: .41);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ondaDaEtapa', () {
    test('cada etapa tem uma onda diferente da anterior', () {
      for (var etapa = 1; etapa < ondasDoCadastro.length; etapa++) {
        expect(
          ondaDaEtapa(etapa),
          isNot(ondaDaEtapa(etapa - 1)),
          reason: 'a etapa $etapa repetiria o desenho da anterior',
        );
      }
    });

    test('a inclinação alterna de lado entre as duas primeiras etapas', () {
      // O que dá a inclinação é a diferença entre as duas bordas: se as
      // telas seguidas caíssem pro mesmo lado, o efeito de "cada tela tem
      // seu desenho" se perderia.
      final primeira = ondaDaEtapa(0);
      final segunda = ondaDaEtapa(1);

      expect(primeira.alturaEsquerda - primeira.alturaDireita, greaterThan(0));
      expect(segunda.alturaEsquerda - segunda.alturaDireita, lessThan(0));
    });

    test('índice além do fim dá a volta, sem estourar', () {
      expect(ondaDaEtapa(ondasDoCadastro.length), ondaDaEtapa(0));
      expect(ondaDaEtapa(ondasDoCadastro.length + 2), ondaDaEtapa(2));
    });

    test('toda onda deixa espaço pra arte e pro formulário', () {
      for (final onda in ondasDoCadastro) {
        expect(onda.topoMaisAlto, greaterThan(.3), reason: 'a arte ficaria espremida demais');
        expect(onda.topoMaisAlto, lessThan(.65), reason: 'sobraria pouco espaço pro formulário');
      }
    });
  });

  group('FundoPTK', () {
    testWidgets('desenha a onda por cima da arte', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FundoPTK(asset: 'assets/ptk/ptk_nickname.jpg', onda: FormaDaOnda(
          alturaEsquerda: .5, alturaDireita: .45, curvaEsquerda: .55, curvaDireita: .4,
        ))),
      ));
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('etapa sem arte não quebra — fica só o fundo e a onda', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FundoPTK(asset: null, onda: FormaDaOnda(
          alturaEsquerda: .5, alturaDireita: .45, curvaEsquerda: .55, curvaDireita: .4,
        ))),
      ));
      await tester.pump();

      expect(find.byType(Image), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
