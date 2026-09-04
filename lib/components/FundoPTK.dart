import 'dart:ui' show ImageFilter;

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

  /// Altura da curva em `t` (0 na borda esquerda, 1 na direita), como
  /// fração da tela. É a Bézier cúbica que o pintor desenha.
  double alturaEm(double t) {
    final u = 1 - t;
    return u * u * u * alturaEsquerda +
        3 * u * u * t * curvaEsquerda +
        3 * u * t * t * curvaDireita +
        t * t * t * alturaDireita;
  }

  /// O ponto **mais baixo** por onde a curva passa. É daí pra baixo que a
  /// faixa branca existe em toda a largura da tela — e por isso é ele, e
  /// não o ponto mais alto, que diz onde o texto pode começar sem escapar
  /// pra cima da arte num canto ou noutro.
  ///
  /// Vem de amostragem, e não dos quatro números direto: [curvaEsquerda] e
  /// [curvaDireita] são pontos de **controle** da Bézier — a curva é puxada
  /// na direção deles, mas nunca chega neles. Usar o número cru daria uma
  /// altura que a curva não tem.
  double get fundoDaCurva {
    var maior = alturaEsquerda;
    const amostras = 48;
    for (var i = 0; i <= amostras; i++) {
      final altura = alturaEm(i / amostras);
      if (altura > maior) maior = altura;
    }
    return maior;
  }

  /// O ponto mais baixo da curva **dentro de uma metade** da tela. Serve
  /// pra o texto poder subir até o cume: um bloco que ocupa só metade da
  /// largura não precisa esperar a curva descer do outro lado.
  double fundoDaMetade({required bool esquerda}) {
    final de = esquerda ? 0.0 : .5;
    final ate = esquerda ? .5 : 1.0;

    var maior = alturaEm(de);
    const amostras = 24;
    for (var i = 0; i <= amostras; i++) {
      final altura = alturaEm(de + (ate - de) * i / amostras);
      if (altura > maior) maior = altura;
    }
    return maior;
  }

  /// O ponto **mais alto** por onde a curva passa — o cume. Acima dele a
  /// área colorida existe em toda a largura, então é até aí que a logo da
  /// tela de boas-vindas pode descer sem a onda cortar um pedaço dela.
  double get topoDaCurva {
    var menor = alturaEsquerda;
    const amostras = 48;
    for (var i = 0; i <= amostras; i++) {
      final altura = alturaEm(i / amostras);
      if (altura < menor) menor = altura;
    }
    return menor;
  }

  /// De que lado a onda subiu mais. O texto fica sempre à esquerda, então
  /// isso não decide mais *onde* ele fica — decide quanto espaço livre ele
  /// tem: com o cume à esquerda o texto sobe alto e pode quebrar em mais
  /// linhas; com o cume à direita ele nasce mais baixo e precisa ser mais
  /// compacto.
  bool get cumeEhAEsquerda => fundoDaMetade(esquerda: true) < fundoDaMetade(esquerda: false);

  /// Onde o texto começa: logo abaixo da curva **na metade esquerda**, com
  /// uma folga pequena. É a metade esquerda porque é aí que o texto fica,
  /// sempre — medir pelo lado do cume deixaria a curva passar por cima do
  /// título toda vez que o cume caísse à direita.
  ///
  /// Ainda assim sobe mais que [topoDoConteudo], que precisa esperar a
  /// curva inteira passar porque os campos ocupam a largura toda.
  double topoDoTexto({double fracaoDeFolga = .04}) {
    final fundo = fundoDaMetade(esquerda: true);
    return fundo + (1 - fundo) * fracaoDeFolga;
  }

  /// Onde o conteúdo de largura cheia (os campos) pode começar:
  /// [fracaoDeFolga] da altura da faixa branca fica livre acima dele, pra
  /// não nascer colado na curva.
  double topoDoConteudo({double fracaoDeFolga = .2}) {
    final fundo = fundoDaCurva;
    return fundo + (1 - fundo) * fracaoDeFolga;
  }

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

/// A onda quando o teclado está aberto: sobe quase até o topo, cobrindo
/// quase toda a arte. Perder o PTK de vista nesse momento é de propósito —
/// o que importa ali é a pessoa conseguir digitar sem o campo espremido
/// contra o teclado.
const FormaDaOnda ondaCheia = FormaDaOnda(
  alturaEsquerda: .10,
  alturaDireita: .07,
  curvaEsquerda: .05,
  curvaDireita: .12,
);

/// A onda da etapa, ou a [ondaCheia] enquanto a pessoa digita.
FormaDaOnda ondaDaEtapa(int indice, {bool tecladoAberto = false}) {
  if (tecladoAberto) return ondaCheia;
  return ondasDoCadastro[indice % ondasDoCadastro.length];
}

/// Fundo das etapas do cadastro: a arte do PTK ocupando o alto da tela e
/// uma onda branca subindo de baixo, onde o formulário fica.
///
/// A arte troca com cross-fade quando a etapa muda, e não com corte seco,
/// porque são todas do mesmo personagem no mesmo cenário — o corte leria
/// como glitch. A **onda** troca junto, animada, o que dá a cada tela um
/// desenho próprio em vez de seis telas iguais com o texto trocado.
///
/// As artes têm o fundo recortado (PNG/WebP com transparência), então quem
/// pinta a área de cima é o [gradienteDoCenario] daqui — o PTK fica por
/// cima dele sem nenhuma emenda visível. Foi por isso que o fundo original
/// das artes saiu: o retângulo delas denunciava onde a imagem acabava.
/// A imagem entra em `cover` alinhada ao topo e não recebe escurecimento —
/// o texto todo vive na parte branca.
class FundoPTK extends StatelessWidget {
  final String? asset;
  final FormaDaOnda onda;

  /// Quanto a arte sobe, como fração da altura da tela. As artes têm o PTK
  /// de corpo inteiro, mas o que interessa aqui é o rosto: puxando pra
  /// cima, ele aparece inteiro em vez de ficar espremido no cantinho de
  /// cima. A faixa que sobra vazia embaixo fica sempre coberta pela onda.
  final double deslocamentoDaArte;

  /// Afasta a arte, como quem dá um passo pra trás: abaixo de 1 o PTK
  /// aparece inteiro, com o objeto que ele segura (o @, a logo do
  /// WhatsApp) sem cortar. O espaço que sobra nas bordas cai no gradiente
  /// de fundo, que imita o próprio cenário das artes.
  final double escalaDaArte;

  /// Logo mostrada no lugar da arte, na etapa que não tem uma. Fica
  /// centralizada na área colorida, com o degradê que a funde no fundo.
  final String? logo;

  const FundoPTK({
    super.key,
    required this.asset,
    required this.onda,
    this.deslocamentoDaArte = .12,
    this.escalaDaArte = .84,
    this.logo,
  });

  /// Cores tiradas do próprio cenário das artes (azul no alto, roxo
  /// embaixo): é o que faz a borda que sobra ao afastar a arte passar
  /// despercebida.
  static const gradienteDoCenario = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF152A86), Color(0xFF3B1D8F), Color(0xFF6B21C8)],
    stops: [0, .55, 1],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Aparece enquanto a arte carrega, nas bordas que sobram ao afastá-la
        // e nas etapas que não têm arte.
        const DecoratedBox(decoration: BoxDecoration(gradient: gradienteDoCenario)),
        if (logo != null) _LogoComDegrade(asset: logo!, onda: onda),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (filho, animacao) => FadeTransition(opacity: animacao, child: filho),
          child: asset == null
              ? const SizedBox.expand(key: ValueKey('sem-arte'))
              : FractionalTranslation(
                  translation: Offset(0, -deslocamentoDaArte),
                  child: Transform.scale(
                    scale: escalaDaArte,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      asset!,
                      key: ValueKey(asset),
                      fit: BoxFit.cover,
                      // Topo, e não centro: é onde está o rosto do PTK em
                      // todas as artes. Centralizado, a cabeça sairia do
                      // enquadramento em tela larga.
                      alignment: Alignment.topCenter,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
        ),
        // A onda é animada por interpolação dos quatro números da forma, e
        // não por cross-fade: assim ela "escorre" de um desenho pro outro,
        // em vez de uma sumir enquanto a outra aparece. É esse mesmo
        // mecanismo que faz a onda "encher a tela" quando o teclado abre —
        // a forma vira a ondaCheia e a curva sobe escorrendo, como líquido
        // subindo num copo.
        TweenAnimationBuilder<FormaDaOnda>(
          tween: _TweenDeOnda(fim: onda),
          duration: const Duration(milliseconds: 480),
          // easeOutCubic sobe rápido e desacelera no fim, que é como um
          // líquido se acomoda ao parar de encher.
          curve: Curves.easeOutCubic,
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

/// Logo do canal na área colorida, desaparecendo conforme desce: nítida em
/// cima, embaçada e coberta por um roxo escuro perto da onda.
///
/// O embaçamento progressivo sai de duas camadas com máscaras opostas — o
/// Flutter não tem blur com intensidade variável. A de cima é a logo
/// nítida, revelada só no topo; a de baixo é a mesma logo embaçada,
/// revelada só na parte inferior. Onde as duas se encontram, a passagem de
/// uma pra outra é o que dá a impressão de foco se perdendo.
class _LogoComDegrade extends StatelessWidget {
  final String asset;

  /// A onda daquela etapa: é o cume dela que diz até onde vai a área
  /// colorida visível, e portanto onde a logo cabe inteira.
  final FormaDaOnda onda;

  const _LogoComDegrade({required this.asset, required this.onda});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        // A logo fica centralizada na faixa colorida que sobra acima do
        // cume — não no meio da tela. Centralizar na tela inteira jogava
        // ela pra baixo e a onda comia um pedaço.
        final faixaVisivel = restricoes.maxHeight * onda.topoDaCurva;
        final lado = (faixaVisivel * .62).clamp(0.0, restricoes.maxWidth * .5);

        // A logo e as duas máscaras vivem dentro da faixa, e não da tela
        // inteira: é o que faz o desfoque e o escurecimento acompanharem a
        // altura que sobrou, em vez de pegarem só o comecinho da imagem.
        final logo = SizedBox(
          height: faixaVisivel,
          child: Center(
            child: SizedBox(
              width: lado,
              height: lado,
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ),
        );

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  _comMascara(child: logo, revelarNoTopo: false, borrar: true),
                  _comMascara(child: logo, revelarNoTopo: true, borrar: false),
                ],
              ),
            ),
            // Degradê por cima de tudo: transparente no alto, roxo escuro
            // encostando na onda. As paradas seguem a curva — o escuro
            // fecha só onde a onda já cobre tudo (fundoDaCurva), pra não
            // sobrar um corte reto no meio da área colorida.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.transparent, Color(0x662A1163), Color(0xE62A1163)],
                    stops: [onda.topoDaCurva * .35, onda.topoDaCurva * .85, onda.fundoDaCurva],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _comMascara({required Widget child, required bool revelarNoTopo, required bool borrar}) {
    final cores = revelarNoTopo
        ? const [Colors.white, Colors.white, Colors.transparent]
        : const [Colors.transparent, Colors.transparent, Colors.white];

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (limites) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: cores,
        stops: const [0, .45, .8],
      ).createShader(limites),
      child: borrar
          ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9), child: child)
          : child,
    );
  }
}
