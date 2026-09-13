import 'package:flutter/material.dart';

/// Fracao "base" (referencia) usada pra calibrar as faixas abaixo — o valor
/// de maxWidthFraction passado por quem usa o widget escala essa faixa
/// proporcionalmente (ex: uma tela que pede 0.4 sempre fica em 80% do valor
/// calibrado pra 0.5, em qualquer faixa de resolucao).
const double _fracaoBaseCalibrada = 0.5;

/// Fracao efetiva da largura da janela numa faixa de resolucao: uma fracao
/// fixa nao funciona bem em toda faixa de tela — 50% de uma janela de
/// notebook (1280px) da uma div confortavel (~640px), mas 50% de um monitor
/// 4K (3840px) da quase 2000px, largo demais pra formulario/card ler bem.
/// Quanto mais larga a janela, menor a fracao necessaria.
double _fracaoNaFaixa(double largura, double maxWidthFraction) {
  final double base;
  if (largura <= 1000) {
    base = 0.85; // tablets/janelas pequenas: quase a largura toda
  } else if (largura <= 1400) {
    base = 0.65; // notebooks
  } else if (largura <= 1920) {
    base = 0.5; // desktop Full HD
  } else if (largura <= 2560) {
    base = 0.4; // QHD/2K
  } else {
    base = 0.3; // 4K ou maior
  }

  return base * (maxWidthFraction / _fracaoBaseCalibrada);
}

/// Limita a largura do conteudo a uma fracao da largura da tela quando ela
/// e "larga", pra evitar que os cards se estiquem ate a borda.
///
/// **Quem decide e a largura, nao a plataforma.** Ate 13/set havia um
/// `if (!kIsWeb) return child` aqui, e o efeito era um app nativo em iPad
/// esticando cada formulario de ponta a ponta — exatamente a cara de "app
/// de celular espichado" que a Apple resumiu como funcionalidade limitada
/// na reprovacao de 27/ago (guideline 4.2.2). Uma janela de navegador de
/// 1180px e um iPad de 1180pt tem o mesmo problema de leitura; a origem do
/// pixel nao muda nada.
///
/// Celular segue intocado: o `breakpoint` de 700 fica acima de qualquer
/// telefone em retrato.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidthFraction;
  final double breakpoint;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidthFraction = 0.5,
    this.breakpoint = 700,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    if (largura <= breakpoint) return child;

    return Center(
      child: SizedBox(width: largura * _fracaoNaFaixa(largura, maxWidthFraction), child: child),
    );
  }
}

/// Igual ao [ResponsiveCenter], mas so aplica um teto de largura (nao forca
/// uma largura fixa). Pra usar dentro de layouts que ja tem seu proprio
/// Center/padding (como Login/Cadastro) sem atropelar esse layout no
/// celular. Vale em qualquer plataforma, pelo mesmo motivo do
/// [ResponsiveCenter].
class ResponsiveMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidthFraction;
  final double breakpoint;

  const ResponsiveMaxWidth({
    super.key,
    required this.child,
    this.maxWidthFraction = 0.5,
    this.breakpoint = 700,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    if (largura <= breakpoint) return child;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: largura * _fracaoNaFaixa(largura, maxWidthFraction)),
      child: child,
    );
  }
}
