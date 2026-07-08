import 'package:flutter/material.dart';

/// Limita a largura do conteudo a uma fracao da largura da janela quando ela
/// e "larga" (web/desktop/tablet), pra evitar que os cards se estiquem ate
/// a borda da tela. Abaixo do breakpoint (celular), o conteudo ocupa a
/// largura inteira normalmente — por isso e seguro usar em qualquer tela.
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
      child: SizedBox(width: largura * maxWidthFraction, child: child),
    );
  }
}

/// Igual ao [ResponsiveCenter], mas so aplica um teto de largura (nao forca
/// uma largura fixa). Pra usar dentro de layouts que ja tem seu proprio
/// Center/padding (como Login/Cadastro) sem atropelar esse layout no celular.
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
      constraints: BoxConstraints(maxWidth: largura * maxWidthFraction),
      child: child,
    );
  }
}
