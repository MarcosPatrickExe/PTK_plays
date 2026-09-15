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

    test('ondaInteira não deixa nenhuma faixa branca — a área colorida é o painel inteiro', () {
      // É a onda do cartão do PTK da versão desktop do cadastro
      // (FundoPTK.desenharOnda: false): sem faixa branca nenhuma pra
      // reservar, fundoDaCurva/topoDaCurva viram 1 — arte e logo passam a
      // considerar o painel inteiro como área colorida.
      expect(ondaInteira.fundoDaCurva, closeTo(1, .0001));
      expect(ondaInteira.topoDaCurva, closeTo(1, .0001));
    });

    test('toda onda deixa espaço pra arte e pro formulário', () {
      for (final onda in ondasDoCadastro) {
        expect(onda.fundoDaCurva, greaterThan(.3), reason: 'a arte ficaria espremida demais');
        expect(onda.topoDoConteudo(), lessThan(.75), reason: 'sobraria pouco espaço pro formulário');
      }
    });
  });

  group('MedidasDaLogo', () {
    // Onda de referência: é a primeira etapa do cadastro, a das
    // boas-vindas, que é onde a logo aparece.
    const onda = FormaDaOnda(alturaEsquerda: .52, alturaDireita: .46, curvaEsquerda: .58, curvaDireita: .40);

    MedidasDaLogo medidasDeCelular() =>
        MedidasDaLogo.em(onda: onda, altura: 800, largura: 411);

    test('o degradê só começa depois que a logo acaba — era isso que cobria o PTK', () {
      final medidas = medidasDeCelular();
      final paradas = medidas.paradasDoDegrade;

      // A primeira parada (a transparente) não pode cair dentro do
      // quadrado da logo. A conta antiga era `topoDaCurva * .78`, que
      // nessa tela dava .349 — e a logo só terminava em .434, ou seja, o
      // véu roxo entrava ~68px desenho adentro, bem na altura da boca e do
      // microfone do headset.
      expect(paradas.first * 800, greaterThanOrEqualTo(medidas.baseDaLogo - .01));
      expect(onda.topoDaCurva * .78 * 800, lessThan(medidas.baseDaLogo),
          reason: 'a conta antiga deixaria de ser um bug e o teste perderia o sentido');
    });

    test('o degradê ainda fecha na onda, pra costurar o vão até a curva', () {
      final paradas = medidasDeCelular().paradasDoDegrade;

      expect(paradas.last, closeTo(onda.fundoDaCurva, .0001));
      expect(paradas[1], greaterThan(paradas.first));
      expect(paradas[1], lessThan(paradas.last));
    });

    test('o desfoque só alcança os últimos 12% do quadrado, onde o alfa já dissolve', () {
      final medidas = medidasDeCelular();
      final paradas = medidas.paradasDoBorrado;

      // As paradas do borrado são frações da FAIXA (é ela que dá altura às
      // duas cópias da logo), não da tela.
      final inicioEmPx = paradas[1] * medidas.faixaVisivel;
      final fimEmPx = paradas[2] * medidas.faixaVisivel;

      expect(fimEmPx, closeTo(medidas.baseDaLogo, .01));
      expect(medidas.baseDaLogo - inicioEmPx, closeTo(medidas.lado * MedidasDaLogo.fracaoBorrada, .01));
      // O rosto fica na metade de cima do quadrado: o borrado não chega lá.
      expect(inicioEmPx, greaterThan(medidas.topoDaLogo + medidas.lado / 2));
    });

    test('as paradas nunca desandam, em nenhuma onda e em nenhuma tela', () {
      // Um LinearGradient com paradas fora de ordem estoura em tempo de
      // execução — e o cálculo depende de três números que vêm de fora
      // (altura, largura e a onda da etapa).
      for (final onda in [...ondasDoCadastro, ondaCheia, ondaInteira]) {
        for (final tela in const [Size(411, 800), Size(320, 480), Size(1024, 600), Size(600, 1024)]) {
          final medidas = MedidasDaLogo.em(onda: onda, altura: tela.height, largura: tela.width);
          final degrade = medidas.paradasDoDegrade;
          final borrado = medidas.paradasDoBorrado;

          for (final paradas in [degrade, borrado]) {
            for (var i = 1; i < paradas.length; i++) {
              expect(paradas[i], greaterThanOrEqualTo(paradas[i - 1]),
                  reason: 'paradas fora de ordem em $onda / $tela');
            }
            expect(paradas.first, inInclusiveRange(0, 1));
            expect(paradas.last, inInclusiveRange(0, 1));
          }
        }
      }
    });

    test('a logo continua cabendo na faixa acima do cume', () {
      final medidas = medidasDeCelular();

      expect(medidas.topoDaLogo, greaterThanOrEqualTo(0));
      expect(medidas.baseDaLogo, lessThanOrEqualTo(medidas.faixaVisivel + .01));
      expect(medidas.fimDaLogo, lessThanOrEqualTo(onda.fundoDaCurva));
    });

    test('numa faixa alta quem limita a logo é a largura, e a base sobe junto', () {
      // Aparelho estreito e comprido: o quadrado não pode crescer além de
      // 82% da largura, então sobra vão entre a logo e a onda — e é
      // exatamente esse vão que o degradê tem pra si.
      final medidas = MedidasDaLogo.em(onda: onda, altura: 1200, largura: 360);

      expect(medidas.lado, closeTo(360 * .82, .01));
      expect(medidas.baseDaLogo, lessThan(medidas.faixaVisivel));
      expect(medidas.paradasDoDegrade.first, lessThan(medidas.paradasDoDegrade.last),
          reason: 'sem vão o degradê não teria onde existir');
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

    testWidgets('a arte COBRE a faixa acima da onda, de ponta a ponta', (tester) async {
      const onda = FormaDaOnda(
        alturaEsquerda: .5,
        alturaDireita: .45,
        curvaEsquerda: .55,
        curvaDireita: .4,
      );

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FundoPTK(asset: 'assets/ptk/ptk_nickname.webp', onda: onda)),
      ));
      await tester.pump();

      final tela = tester.getSize(find.byType(FundoPTK));
      final arte = tester.getRect(find.byType(Image));

      // A arte vai até o ponto mais baixo da onda, e não além: dali pra
      // baixo a faixa branca cobre a largura toda, e nada desenhado ali
      // seria visto.
      expect(arte.bottom, lessThanOrEqualTo(tela.height * onda.fundoDaCurva + 1));

      // **Encosta na borda de cima, e isso é o novo contrato.** Até 15/set
      // sobrava uma folga ali, porque a arte vinha recortada e era
      // encaixada com `contain` — a folga impedia o cabelo de tocar a
      // borda. Agora a arte traz o cenário original dela e cobre a faixa
      // inteira: qualquer folga no topo mostraria o gradiente do app atrás,
      // com uma emenda horizontal no meio da tela.
      expect(arte.top, lessThanOrEqualTo(0.5));
      expect(arte.width, greaterThanOrEqualTo(tela.width - 1));
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

    testWidgets('desenharOnda: false tira a curva branca, sem tirar a arte', (tester) async {
      // O cartão do PTK da versão desktop do cadastro usa exatamente essa
      // combinação (ondaInteira + desenharOnda: false): o contorno
      // arredondado sai de um ClipRRect de fora, não de uma curva por cima
      // da arte.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FundoPTK(asset: 'assets/ptk/ptk_nickname.webp', onda: ondaInteira, desenharOnda: false),
        ),
      ));
      await tester.pump();

      // CustomPaint sempre existe em algum lugar da árvore do Material —
      // o teste checa que NENHUM deles pinta a curva (_PintorDaOnda é
      // privado, então a checagem é indireta: sem o CustomPaint dela, o
      // widget correspondente à curva simplesmente não está lá).
      final semOnda = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(semOnda.any((c) => c.painter.runtimeType.toString() == '_PintorDaOnda'), isFalse);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('com ondaInteira a arte ocupa o painel inteiro, não só uma fração', (tester) async {
      // fundoDaCurva == 1 pra essa onda: a "faixa colorida" que a arte
      // preenche (ver FundoPTK._arte) passa a ser a altura do painel
      // inteiro, em vez de parar onde a onda desceria no celular.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FundoPTK(asset: 'assets/ptk/ptk_nickname.webp', onda: ondaInteira, desenharOnda: false),
        ),
      ));
      await tester.pump();

      final tela = tester.getSize(find.byType(FundoPTK));
      final arte = tester.getRect(find.byType(Image));

      expect(arte.bottom, closeTo(tela.height, 1));
    });
  });
}
