import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../components/AuthWidgets.dart';
import '../i18n/Idioma.dart';
import '../utils/PoliticaPrivacidade.dart';
import '../utils/ThemeController.dart';

/// Mostra a política de privacidade dentro do próprio app (em vez de abrir
/// o navegador externo), com botões flutuantes de voltar/trocar tema por
/// cima, fixos, pro usuário sempre saber que pode sair da página quando
/// quiser. A URL exibida (original em inglês, ou traduzida pro português
/// via translate.goog) segue o idioma em que o app está falando -
/// ver [urlPoliticaPrivacidadeParaIdioma].
class PoliticaPrivacidadeWeb extends StatelessWidget {
  const PoliticaPrivacidadeWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;
    final url = urlPoliticaPrivacidadeParaIdioma(context.watch<IdiomaController>().idioma);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(initialUrlRequest: URLRequest(url: WebUri(url))),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: BotaoVoltar(isDark: isDark, onTap: () => Navigator.of(context).pop()),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: BotaoTema(isDark: isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
