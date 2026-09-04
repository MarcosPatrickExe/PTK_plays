import 'package:flutter/material.dart';

/// Formato da onda branca que separa a arte do PTK (em cima) do formulário
/// (embaixo), nas telas de cadastro.
///
/// Os quatro números são frações da altura da tela, então a onda acompanha
/// qualquer tamanho de aparelho:
/// - [alturaEsquerda] / [alturaDireita]: onde a onda encosta em cada borda —
///   a diferença entre os dois é o que dá a **inclinação**;
/// - [curvaEsquerda] / [curvaDireita]: os pontos de controle da curva, que
///   decidem se ela sobe formando uma crista ou desce formando um vale.
class FormaDaOnda {
  final double alturaEsquerda;
  final double alturaDireita;
  final double curvaEsquerda;
  final double curvaDireita;

  const FormaDaOnda({
    required this.alturaEsquerda,
    required this.alturaDireita,
    required this.curvaEsquerda,
    required this.curvaDireita,
  });

  /// O ponto mais alto que a onda alcança — é o que o formulário usa pra
  /// saber onde pode começar sem passar por cima da arte.
  double get topoMaisAlto => [alturaEsquerda, alturaDireita, curvaEsquerda, curvaDireita].reduce(
        (menor, atual) => atual < menor ? atual : menor,
      );

  // Igualdade por valor: é o que deixa o repaint acontecer só quando a onda
  // realmente muda, e o tween saber que chegou ao destino.
  @override
  bool operator ==(Object outro) =>
      outro is FormaDaOnda &&
      outro.alturaEsquerda == alturaEsquerda &&
      outro.alturaDireita == alturaDireita &&
      outro.curvaEsquerda == curvaEsquerda &&
      outro.curvaDireita == curvaDireita;

  @override
  int get hashCode => Object.hash(alturaEsquerda, alturaDireita, curvaEsquerda, curvaDireita);
}

/// Uma onda diferente por etapa, pra as telas do cadastro não parecerem
/// todas a mesma tela com o texto trocado: a inclinação alterna de lado e a
/// curva muda de altura conforme a pessoa avança.
///
/// A lista se repete quando o índice passa do fim, então funciona pra
/// qualquer quantidade de etapas.
const List<FormaDaOnda> ondasDoCadastro = [
  // Quase reta, com uma crista suave à direita.
  FormaDaOnda(alturaEsquerda: .52, alturaDireita: .46, curvaEsquerda: .58, curvaDireita: .40),
  // Inclinada pro outro lado, com vale à esquerda.
  FormaDaOnda(alturaEsquerda: .44, alturaDireita: .54, curvaEsquerda: .36, curvaDireita: .60),
  // Mais alta, com a curva bem marcada no meio.
  FormaDaOnda(alturaEsquerda: .50, alturaDireita: .44, curvaEsquerda: .34, curvaDireita: .56),
  // Descendo da esquerda pra direita, quase diagonal.
  FormaDaOnda(alturaEsquerda: .40, alturaDireita: .52, curvaEsquerda: .52, curvaDireita: .42),
  // Simétrica, com crista central.
  FormaDaOnda(alturaEsquerda: .48, alturaDireita: .48, curvaEsquerda: .34, curvaDireita: .34),
  // Vale central: a arte aparece mais nas laterais.
  FormaDaOnda(alturaEsquerda: .42, alturaDireita: .46, curvaEsquerda: .60, curvaDireita: .58),
];

FormaDaOnda ondaDaEtapa(int indice) => ondasDoCadastro[indice % ondasDoCadastro.length];

/// Fundo das etapas do cadastro: a arte do PTK ocupando o alto da tela e
/// uma onda branca subindo de baixo, onde o formulário fica.
///
/// A arte troca com cross-fade quando a etapa muda, e não com corte seco,
/// porque são todas do mesmo personagem no mesmo cenário — o corte leria
/// como glitch. A **onda** troca junto, animada, o que dá a cada tela um
/// desenho próprio em vez de seis telas iguais com o texto trocado.
///
/// O fundo colorido que já vem em cada arte é aproveitado como o fundo da
/// parte de cima: por isso a imagem entra em `cover` alinhada ao topo, e
/// não recebe escurecimento — o texto todo vive na parte branca.
class FundoPTK extends StatelessWidget {
  final String? asset;
  final FormaDaOnda onda;

  const FundoPTK({super.key, required this.asset, required this.onda});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Aparece enquanto a arte carrega e nas etapas que não têm arte.
        const ColoredBox(color: Color(0xFF3B1D8F)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (filho, animacao) => FadeTransition(opacity: animacao, child: filho),
          child: asset == null
              ? const SizedBox.expand(key: ValueKey('sem-arte'))
              : Image.asset(
                  asset!,
                  key: ValueKey(asset),
                  fit: BoxFit.cover,
                  // Topo, e não centro: é onde está o rosto do PTK em todas
                  // as artes. Centralizado, a cabeça sairia do enquadramento
                  // em tela larga.
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
        // A onda é animada por interpolação dos quatro números da forma, e
        // não por cross-fade: assim ela "escorre" de um desenho pro outro,
        // em vez de uma sumir enquanto a outra aparece.
        TweenAnimationBuilder<FormaDaOnda>(
          tween: _TweenDeOnda(fim: onda),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOut,
          builder: (context, formaAtual, _) => CustomPaint(painter: _PintorDaOnda(formaAtual)),
        ),
      ],
    );
  }
}

/// Interpola os quatro números da onda, pra transição entre duas formas.
class _TweenDeOnda extends Tween<FormaDaOnda> {
  _TweenDeOnda({required FormaDaOnda fim}) : super(begin: fim, end: fim);

  @override
  set end(FormaDaOnda? novoFim) {
    if (novoFim == null || novoFim == end) return;
    begin = evaluate(const AlwaysStoppedAnimation(1));
    super.end = novoFim;
  }

  @override
  FormaDaOnda lerp(double t) {
    final a = begin!;
    final b = end!;
    double entre(double de, double para) => de + (para - de) * t;

    return FormaDaOnda(
      alturaEsquerda: entre(a.alturaEsquerda, b.alturaEsquerda),
      alturaDireita: entre(a.alturaDireita, b.alturaDireita),
      curvaEsquerda: entre(a.curvaEsquerda, b.curvaEsquerda),
      curvaDireita: entre(a.curvaDireita, b.curvaDireita),
    );
  }
}

class _PintorDaOnda extends CustomPainter {
  final FormaDaOnda forma;

  const _PintorDaOnda(this.forma);

  @override
  void paint(Canvas canvas, Size size) {
    final caminho = Path()
      ..moveTo(0, size.height * forma.alturaEsquerda)
      ..cubicTo(
        size.width * .33,
        size.height * forma.curvaEsquerda,
        size.width * .67,
        size.height * forma.curvaDireita,
        size.width,
        size.height * forma.alturaDireita,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(caminho, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PintorDaOnda anterior) => anterior.forma != forma;
}
