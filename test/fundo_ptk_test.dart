import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/FundoPTK.dart';

void main() {
  group('FormaDaOnda', () {
    test('a curva começa e termina nas alturas das bordas', () {
      const onda = FormaDaOnda(alturaEsquerda: .52, alturaDireita: .46, curvaEsquerda: .58, curvaDireita: .40);

      expect(onda.alturaEm(0), closeTo(.52, .0001));
      expect(onda.alturaEm(1), closeTo(.46, .0001));
    });

    test('a curva nunca alcança os pontos de controle — foi o que causou o bug', () {
      // O texto escapava pra cima da arte porque o cálculo antigo tratava
      // curvaEsquerda/curvaDireita como alturas por onde a curva passa. Ela
      // é só puxada na direção deles.
      const onda = FormaDaOnda(alturaEsquerda: .52, alturaDireita: .46, curvaEsquerda: .58, curvaDireita: .40);

      for (var i = 0; i <= 20; i++) {
        final altura = onda.alturaEm(i / 20);
        expect(altura, greaterThan(.40), reason: 'chegou no ponto de controle de cima');
        expect(altura, lessThan(.58), reason: 'chegou no ponto de controle de baixo');
      }
    });

    test('fundoDaCurva é o ponto mais baixo por onde a curva passa', () {
      const onda = FormaDaOnda(alturaEsquerda: .52, alturaDireita: .46, curvaEsquerda: .58, curvaDireita: .40);
      final fundo = onda.fundoDaCurva;

      // Nenhuma amostra pode ficar abaixo dele, senão a faixa branca não
      // existiria em toda a largura naquele ponto.
      for (var i = 0; i <= 40; i++) {
        expect(onda.alturaEm(i / 40), lessThanOrEqualTo(fundo + .0001));
      }
      // E ele é uma altura real da curva, não um dos números crus.
      expect(fundo, greaterThanOrEqualTo(.52));
    });

    test('topoDoConteudo desce a folga pedida dentro da faixa branca', () {
      const onda = FormaDaOnda(alturaEsquerda: .5, alturaDireita: .5, curvaEsquerda: .5, curvaDireita: .5);

      // Curva reta em .5: a faixa branca é a metade de baixo, e 20% dela
      // são 10% da tela.
      expect(onda.fundoDaCurva, closeTo(.5, .0001));
      expect(onda.topoDoConteudo(), closeTo(.6, .0001));
      expect(onda.topoDoConteudo(fracaoDeFolga: 0), closeTo(.5, .0001));
    });

    test('o cume é o lado onde a curva subiu mais', () {
      // Sobe à direita (altura menor = mais alto na tela).
      const subindoADireita = FormaDaOnda(
        alturaEsquerda: .55,
        alturaDireita: .40,
        curvaEsquerda: .55,
        curvaDireita: .40,
      );
      expect(subindoADireita.cumeEhAEsquerda, isFalse);

      const subindoAEsquerda = FormaDaOnda(
        alturaEsquerda: .40,
        alturaDireita: .55,
        curvaEsquerda: .40,
        curvaDireita: .55,
      );
      expect(subindoAEsquerda.cumeEhAEsquerda, isTrue);
    });

    test('o texto sobe mais que os campos, porque não ocupa a largura toda', () {
      for (final onda in ondasDoCadastro) {
        expect(
          onda.topoDoTexto(),
          lessThan(onda.topoDoConteudo()),
          reason: 'o texto não estaria aproveitando o espaço livre embaixo da curva',
        );
      }
    });

    test('o texto começa abaixo da curva na metade esquerda, onde ele fica', () {
      for (final onda in ondasDoCadastro) {
        final topo = onda.topoDoTexto();

        // Metade esquerda porque o texto do cadastro é sempre alinhado à
        // esquerda — inclusive quando o cume está do outro lado, caso em
        // que ele simplesmente nasce mais baixo.
        for (var i = 0; i <= 24; i++) {
          expect(
            onda.alturaEm(.5 * i / 24),
            lessThan(topo),
            reason: 'a curva passaria por cima do texto',
          );
        }
      }
    });

    test('com o cume à direita o texto nasce mais baixo que com o cume à esquerda', () {
      const cumeAEsquerda = FormaDaOnda(
        alturaEsquerda: .40,
        alturaDireita: .55,
        curvaEsquerda: .40,
        curvaDireita: .55,
      );
      const cumeADireita = FormaDaOnda(
        alturaEsquerda: .55,
        alturaDireita: .40,
        curvaEsquerda: .55,
        curvaDireita: .40,
      );

      expect(cumeAEsquerda.cumeEhAEsquerda, isTrue);
      expect(cumeADireita.cumeEhAEsquerda, isFalse);
      expect(cumeAEsquerda.topoDoTexto(), lessThan(cumeADireita.topoDoTexto()));
    });

    test('o topo da curva é o ponto mais alto por onde ela passa', () {
      for (final onda in [...ondasDoCadastro, ondaCheia]) {
        final topo = onda.topoDaCurva;
        for (var i = 0; i <= 40; i++) {
          expect(
            onda.alturaEm(i / 40),
            greaterThanOrEqualTo(topo - 1e-9),
            reason: 'a logo seria cortada pela onda nesse ponto',
          );
        }
        expect(topo, lessThanOrEqualTo(onda.fundoDaCurva));
      }
    });

    test('o conteúdo de largura cheia sempre começa abaixo da curva inteira', () {
      for (final onda in [...ondasDoCadastro, ondaCheia]) {
        final topo = onda.topoDoConteudo();
        for (var i = 0; i <= 40; i++) {
          expect(
            onda.alturaEm(i / 40),
            lessThan(topo),
            reason: 'a curva passaria por cima do texto nessa onda',
          );
        }
      }
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

    test('com o teclado aberto, qualquer etapa usa a onda cheia', () {
      for (var etapa = 0; etapa < ondasDoCadastro.length; etapa++) {
        expect(ondaDaEtapa(etapa, tecladoAberto: true), ondaCheia);
      }
    });

    test('a onda cheia sobe quase até o topo, liberando a tela pro teclado', () {
      expect(ondaCheia.fundoDaCurva, lessThan(.15));
    });

    test('toda onda deixa espaço pra arte e pro formulário', () {
      for (final onda in ondasDoCadastro) {
        expect(onda.fundoDaCurva, greaterThan(.3), reason: 'a arte ficaria espremida demais');
        expect(onda.topoDoConteudo(), lessThan(.75), reason: 'sobraria pouco espaço pro formulário');
      }
    });
  });

  group('FundoPTK', () {
    testWidgets('desenha a onda por cima da arte', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FundoPTK(asset: 'assets/ptk/ptk_nickname.webp', onda: FormaDaOnda(
          alturaEsquerda: .5, alturaDireita: .45, curvaEsquerda: .55, curvaDireita: .4,
        ))),
      ));
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a logo das boas-vindas cabe inteira na faixa colorida acima do cume', (tester) async {
      const onda = FormaDaOnda(
        alturaEsquerda: .5,
        alturaDireita: .45,
        curvaEsquerda: .55,
        curvaDireita: .4,
      );

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FundoPTK(asset: null, onda: onda, logo: 'assets/ptk/ptk_logo.webp')),
      ));
      await tester.pump();

      final tela = tester.getSize(find.byType(FundoPTK));
      // Duas cópias da logo (a nítida e a borrada) compõem o degradê.
      final caixa = tester.getRect(find.byType(Image).first);

      expect(caixa.bottom, lessThanOrEqualTo(tela.height * onda.topoDaCurva + 1));
      expect(caixa.top, greaterThan(0));
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
