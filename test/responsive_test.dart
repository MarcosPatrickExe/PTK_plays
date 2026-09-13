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
    testWidgets('nao restringe largura na web em tela estreita (celular)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(400, 800),
        ResponsiveCenter(
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      expect(tamanho.width, 400);
    });

    testWidgets('restringe proporcionalmente na web em tela larga (notebook)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1400, 900),
        ResponsiveCenter(
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      // Faixa <=1400 (notebook) usa base 0.65 da escala calibrada em Responsive.dart.
      expect(tamanho.width, 910); // 1400 * 0.65
    });

    testWidgets('respeita fracao customizada na web (video cards a 40%)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1000, 900),
        ResponsiveCenter(
          maxWidthFraction: 0.4,
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      // Faixa <=1000 usa base 0.85; 0.4 pedido escala essa base (0.4/0.5 = 80%).
      expect(tamanho.width, 680); // 1000 * (0.85 * 0.8)
    });

    testWidgets('reduz a fracao efetiva conforme a tela fica mais larga (4K)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(3840, 2160),
        ResponsiveCenter(
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      // Faixa >2560 (4K) usa base 0.3, bem mais estreita que em telas menores,
      // pra evitar cards/formularios esticados demais em monitores grandes.
      expect(tamanho.width, 1152); // 3840 * 0.3
    });

    testWidgets('restringe tambem fora da web em tela larga (iPad/tablet)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1400, 900),
        ResponsiveCenter(
          child: Container(key: const Key('filho'), color: Colors.red, width: double.infinity, height: 10),
        ),
      );
      // Ate 13/set isto media 1400 (sem restricao nenhuma fora da web), e
      // era o motivo de cada tela do app esticar de ponta a ponta no iPad.
      // Quem decide agora e a largura, nao a plataforma.
      expect(tamanho.width, 910); // 1400 * 0.65, igual ao navegador
    });
  });

  group('ResponsiveMaxWidth', () {
    testWidgets('nao restringe na web em tela estreita', (tester) async {
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

    testWidgets('aplica teto proporcional na web em tela larga mesmo se o filho pedir mais', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1400, 900),
        Center(
          child: ResponsiveMaxWidth(
            child: Container(key: const Key('filho'), color: Colors.red, width: 2000, height: 10),
          ),
        ),
      );
      expect(tamanho.width, 910); // 1400 * 0.65, mesmo o filho pedindo 2000
    });

    testWidgets('aplica teto tambem fora da web em tela larga (iPad/tablet)', (tester) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        const Size(1400, 900),
        Center(
          child: ResponsiveMaxWidth(
            child: Container(key: const Key('filho'), color: Colors.red, width: 2000, height: 10),
          ),
        ),
      );
      expect(tamanho.width, 910); // 1400 * 0.65 — o teto passou a valer no nativo tambem
    });
  });

  // O aparelho das duas reprovacoes da Apple. As medidas sao as reais:
  // 1180x820 pontos. O print de 12/set mostrava o cartao de login esticado
  // de ponta a ponta em retrato — que e o que estes testes travam.
  group('cartão de login no iPad Air 11"', () {
    // Mesma conta que o Login.dart faz: _fracaoNaFaixa(largura, 0.3).
    Future<double> larguraDoCartao(WidgetTester tester, Size tela) async {
      final tamanho = await tamanhoDoFilho(
        tester,
        tela,
        Center(
          child: ResponsiveMaxWidth(
            maxWidthFraction: 0.3,
            child: Container(
              key: const Key('filho'),
              color: Colors.red,
              width: double.infinity,
              height: 10,
            ),
          ),
        ),
      );
      return tamanho.width;
    }

    testWidgets('em retrato (820) não ocupa mais que metade da tela', (tester) async {
      final largura = await larguraDoCartao(tester, const Size(820, 1180));

      // Faixa <=1000 usa base 0.85; 0.85 * (0.3/0.5) = 0.51.
      expect(largura, closeTo(820 * 0.51, 1));
      // O que o print mostrava: 0.85 da tela, quase encostando nas bordas.
      expect(largura, lessThan(820 * 0.6));
    });

    testWidgets('em paisagem (1180) encolhe mais ainda, em proporção', (tester) async {
      final largura = await larguraDoCartao(tester, const Size(1180, 820));

      // Faixa <=1400 usa base 0.65; 0.65 * 0.6 = 0.39.
      expect(largura, closeTo(1180 * 0.39, 1));
      // A regra que importa: quanto mais larga a tela, MENOR a fracao — em
      // pontos absolutos os dois ficam parecidos (~418 e ~460), que e o que
      // faz o cartao nao mudar de cara ao girar o aparelho.
      expect(largura, closeTo(460, 40));
    });

    testWidgets('celular não é afetado por nada disso', (tester) async {
      // O breakpoint de 700 existe pra isto: nenhum telefone em retrato
      // chega la, entao o layout de celular fica exatamente como estava.
      final largura = await larguraDoCartao(tester, const Size(390, 844));
      expect(largura, 390);
    });
  });
}
