import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Limita a largura do conteudo a uma fracao da largura da janela quando ela
/// e "larga" (web/desktop/tablet), pra evitar que os cards se estiquem ate
/// a borda da tela. So se aplica na Web — no app nativo (Android/iOS) o
/// conteudo sempre ocupa a largura inteira, sem essa restricao.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidthFraction;
  final double breakpoint;

  /// So pra teste de widget conseguir simular "web" sem precisar rodar em
  /// --platform chrome. Em producao fica sempre null (usa o kIsWeb real).
  final bool? isWebOverride;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidthFraction = 0.5,
    this.breakpoint = 700,
    this.isWebOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (!(isWebOverride ?? kIsWeb)) return child;

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
/// Tambem restrito a Web, pelo mesmo motivo.
class ResponsiveMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidthFraction;
  final double breakpoint;

  /// So pra teste de widget conseguir simular "web" sem precisar rodar em
  /// --platform chrome. Em producao fica sempre null (usa o kIsWeb real).
  final bool? isWebOverride;

  const ResponsiveMaxWidth({
    super.key,
    required this.child,
    this.maxWidthFraction = 0.5,
    this.breakpoint = 700,
    this.isWebOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (!(isWebOverride ?? kIsWeb)) return child;

    final largura = MediaQuery.of(context).size.width;
    if (largura <= breakpoint) return child;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: largura * maxWidthFraction),
      child: child,
    );
  }
}
