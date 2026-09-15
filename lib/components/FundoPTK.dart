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

/// Onda "cheia": não sobra nenhuma faixa branca, a área colorida ocupa o
/// espaço inteiro. Não é desenhada de verdade (usar com
/// [FundoPTK.desenharOnda] em `false`) — serve pro cartão do PTK da versão
/// desktop do cadastro, onde a arte vive num painel retangular próprio (o
/// contorno arredondado vem de um `ClipRRect` de fora, não da curva) e não
/// de uma faixa de tela inteira competindo por espaço com o formulário.
///
/// `fundoDaCurva` e `topoDaCurva` valem 1 nessa forma, então a arte e a
/// logo (que leem essas duas frações pra saber até onde vai a área
/// colorida) passam a considerar o painel inteiro.
const FormaDaOnda ondaInteira = FormaDaOnda(
  alturaEsquerda: 1,
  alturaDireita: 1,
  curvaEsquerda: 1,
  curvaDireita: 1,
);

/// Fundo das etapas do cadastro: a arte do PTK ocupando o alto da tela e
/// uma onda branca subindo de baixo, onde o formulário fica.
///
/// A arte troca com cross-fade quando a etapa muda, e não com corte seco,
/// porque são todas do mesmo personagem no mesmo cenário — o corte leria
/// como glitch. A **onda** troca junto, animada, o que dá a cada tela um
/// desenho próprio em vez de seis telas iguais com o texto trocado.
///
/// **As artes vêm com o cenário original delas** (15/set). Por um tempo
/// elas foram usadas recortadas, com o fundo tirado, porque enquadradas com
/// `contain` o retângulo do quadrado denunciava onde a imagem acabava. O
/// recorte resolvia a emenda e custava o cenário inteiro — as luzes, o
/// risco roxo, as estrelinhas.
///
/// Com `cover` a emenda não existe: o quadrado cobre a faixa colorida de
/// ponta a ponta, e o cenário da arte **é** o fundo. O [gradienteDoCenario]
/// continua atrás, agora só pra enquanto a imagem carrega.
///
/// A imagem não recebe escurecimento — o texto todo vive na parte branca.
class FundoPTK extends StatelessWidget {
  final String? asset;
  final FormaDaOnda onda;

  /// Logo mostrada no lugar da arte, na etapa que não tem uma. Fica
  /// centralizada na área colorida, com o degradê que a funde no fundo.
  final String? logo;

  /// Desliga a curva branca. Usado no cartão do PTK da versão desktop do
  /// cadastro (combinado com `onda: ondaInteira`), onde a arte ocupa um
  /// painel retangular próprio — o contorno arredondado sai de um
  /// `ClipRRect` de quem chama, não da curva — em vez de disputar espaço
  /// com um formulário sobreposto, como no celular.
  final bool desenharOnda;

  const FundoPTK({
    super.key,
    required this.asset,
    required this.onda,
    this.logo,
    this.desenharOnda = true,
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

  /// A arte cobrindo a faixa colorida — a parte da tela acima da onda.
  ///
  /// **`cover`, e não `contain`.** As artes são quadradas e a faixa é mais
  /// alta que larga, então `contain` encaixava o quadrado pela largura e
  /// deixava uma sobra de gradiente em cima dele — com uma emenda
  /// horizontal visível bem no meio da tela. Era essa emenda que obrigava a
  /// recortar o fundo das artes.
  ///
  /// O corte que o `cover` faz é nas **laterais**, e o personagem está
  /// centralizado: o que sai é cenário. Numa tela de celular a conta dá
  /// corte zero na vertical — a faixa é mais alta que larga, então o
  /// quadrado é escalado pela altura e sobra largura pra cortar.
  ///
  /// A faixa vai até [FormaDaOnda.fundoDaCurva], o ponto **mais baixo** da
  /// onda: daí pra baixo a faixa branca cobre a largura toda, então nada
  /// que a arte desenhe ali seria visto.
  Widget _arte() {
    return LayoutBuilder(
      key: ValueKey(asset),
      builder: (context, restricoes) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: restricoes.maxHeight * onda.fundoDaCurva,
            width: double.infinity,
            child: Image.asset(
              asset!,
              fit: BoxFit.cover,
              // O topo é o que não pode ser cortado: é onde estão a cabeça
              // e, na selfie, o celular que sobe mais que ela. Numa faixa
              // baixa e larga (tablet em paisagem) o corte vertical existe,
              // e ancorar no topo garante que ele saia de baixo — onde a
              // onda já cobriria de qualquer jeito.
              alignment: Alignment.topCenter,
            ),
          ),
        );
      },
    );
  }

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
          child: asset == null ? const SizedBox.expand(key: ValueKey('sem-arte')) : _arte(),
        ),
        // A onda é animada por interpolação dos quatro números da forma, e
        // não por cross-fade: assim ela "escorre" de um desenho pro outro,
        // em vez de uma sumir enquanto a outra aparece. É esse mesmo
        // mecanismo que faz a onda "encher a tela" quando o teclado abre —
        // a forma vira a ondaCheia e a curva sobe escorrendo, como líquido
        // subindo num copo.
        //
        // No cartão do desktop (desenharOnda: false) essa camada nem entra:
        // lá o contorno arredondado é do painel inteiro, não de uma curva.
        if (desenharOnda)
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

/// A conta de onde o degradê e o desfoque da logo podem existir sem
/// encostar no desenho.
///
/// Vive fora do widget porque é **só a conta** — e foi a conta que errou
/// duas vezes. Até 15/set as paradas do degradê eram frações da **onda**
/// (`topoDaCurva * .78`, `* .95`): onde a logo estava não entrava no
/// cálculo. Como a logo é centralizada na faixa colorida, ela termina bem
/// acima do fim da faixa — e o véu roxo, ancorado na faixa, começava em
/// cima do rosto. O ajuste de 13/set empurrou as paradas pra baixo e
/// continuou sendo chute: seguia sem saber onde a logo acabava, e por isso
/// voltou a cobrir o PTK no aparelho do usuário.
///
/// Agora as duas coisas nascem da **base do quadrado da logo**: o degradê
/// só existe no vão entre ela e a onda, e o desfoque só toca os últimos
/// [fracaoBorrada] do quadrado — a faixa que o próprio arquivo já dissolve
/// no alfa, que é a única borda que havia pra esconder.
class MedidasDaLogo {
  /// Altura total do fundo, em px.
  final double altura;

  /// A faixa colorida que sobra acima do cume da onda, em px. É nela que a
  /// logo é centralizada.
  final double faixaVisivel;

  /// Lado do quadrado da logo, em px.
  final double lado;

  /// Fração da tela a partir da qual a onda cobre a largura inteira.
  final double fundoDaCurva;

  const MedidasDaLogo._({
    required this.altura,
    required this.faixaVisivel,
    required this.lado,
    required this.fundoDaCurva,
  });

  factory MedidasDaLogo.em({
    required FormaDaOnda onda,
    required double altura,
    required double largura,
  }) {
    final faixa = altura * onda.topoDaCurva;
    return MedidasDaLogo._(
      altura: altura,
      faixaVisivel: faixa,
      // A logo cabe na faixa (96% dela) ou na largura (82%), o que for
      // menor: no celular quem limita é a largura.
      lado: (faixa * .96).clamp(0.0, largura * .82),
      fundoDaCurva: onda.fundoDaCurva,
    );
  }

  /// Onde o quadrado da logo começa e termina, em px a partir do topo.
  double get topoDaLogo => (faixaVisivel - lado) / 2;
  double get baseDaLogo => (faixaVisivel + lado) / 2;

  /// A base da logo como fração da tela — o ponto onde o degradê pode
  /// começar a escurecer.
  double get fimDaLogo => altura <= 0 ? 0 : (baseDaLogo / altura).clamp(0.0, fundoDaCurva);

  /// As três paradas do degradê, em fração da **tela** (ele é pintado num
  /// `Positioned.fill`): transparente até a logo acabar, roxo fechando só
  /// onde a onda já cobre tudo.
  List<double> get paradasDoDegrade {
    // O clamp não é paranoia: `fundoDaCurva` vem de amostrar a Bézier, e
    // na [ondaInteira] (a do cartão do desktop, cujos quatro números são 1)
    // a soma dá 1.0000000000000004. Uma parada acima de 1 derruba o
    // LinearGradient em tempo de execução — e é justamente a onda que a
    // tela de boas-vindas usa no desktop, onde a logo existe.
    final fim = fundoDaCurva.clamp(0.0, 1.0);
    final inicio = fimDaLogo.clamp(0.0, fim);
    return [inicio, inicio + (fim - inicio) * .5, fim];
  }

  /// Quanto do quadrado, medido de baixo pra cima, o desfoque alcança.
  static const fracaoBorrada = .12;

  /// As paradas da máscara de desfoque, em fração da **faixa** — é ela que
  /// dá altura às duas cópias da logo, então a máscara é medida nela e não
  /// na tela.
  List<double> get paradasDoBorrado {
    if (faixaVisivel <= 0) return const [0, .5, 1];
    final fim = (baseDaLogo / faixaVisivel).clamp(0.0, 1.0);
    final inicio = ((baseDaLogo - lado * fracaoBorrada) / faixaVisivel).clamp(0.0, fim);
    return [0, inicio, fim];
  }
}

/// Logo do canal na área colorida, desaparecendo conforme desce: nítida em
/// cima, com a borda de baixo dissolvida antes de encontrar a onda.
///
/// O embaçamento progressivo sai de duas camadas com máscaras opostas — o
/// Flutter não tem blur com intensidade variável. A de cima é a logo
/// nítida, revelada até a base do quadrado; a de baixo é a mesma logo
/// embaçada, revelada só no último pedacinho. Onde as duas se encontram, a
/// passagem de uma pra outra é o que dá a impressão de foco se perdendo.
///
/// O efeito é fraco de propósito, e desde 15/set ele é **medido pela
/// logo**, não pela onda — ver [MedidasDaLogo]. O arquivo já tem o alfa
/// dissolvido nas últimas linhas (o busto era quadrado e terminava num
/// corte reto), então não sobra borda pra esconder: desfoque e degradê
/// fortes só embaçavam o rosto sem resolver nada.
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
        final medidas = MedidasDaLogo.em(
          onda: onda,
          altura: restricoes.maxHeight,
          largura: restricoes.maxWidth,
        );

        // A logo e as duas máscaras vivem dentro da faixa, e não da tela
        // inteira: é o que faz o desfoque acompanhar a altura que sobrou,
        // em vez de pegar só o comecinho da imagem.
        final logo = SizedBox(
          height: medidas.faixaVisivel,
          child: Center(
            child: SizedBox(
              width: medidas.lado,
              height: medidas.lado,
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
                  _comMascara(medidas, child: logo, revelarNoTopo: false, borrar: true),
                  _comMascara(medidas, child: logo, revelarNoTopo: true, borrar: false),
                ],
              ),
            ),
            // Degradê por cima de tudo: transparente enquanto a logo
            // existe, roxo mais fechado só encostando na onda. Quem resolve
            // a borda de baixo da logo é o alfa dissolvido no próprio
            // arquivo — este degradê só costura o vão entre a logo e a
            // curva, e por isso começa exatamente onde o desenho acaba.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.transparent, Color(0x142A1163), Color(0x662A1163)],
                    stops: medidas.paradasDoDegrade,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _comMascara(
    MedidasDaLogo medidas, {
    required Widget child,
    required bool revelarNoTopo,
    required bool borrar,
  }) {
    final cores = revelarNoTopo
        ? const [Colors.white, Colors.white, Colors.transparent]
        : const [Colors.transparent, Colors.transparent, Colors.white];

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (limites) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: cores,
        stops: medidas.paradasDoBorrado,
      ).createShader(limites),
      child: borrar
          ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5), child: child)
          : child,
    );
  }
}
