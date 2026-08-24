import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher_url;
import '../components/ModalMSG.dart';
import '../view/PoliticaPrivacidadeWeb.dart';

/// URL original (em inglês) da política de privacidade do PTK Plays,
/// hospedada no Blogger.
const String urlPoliticaPrivacidade = 'https://ptkplaysapp.blogspot.com/2025/12/ptk-plays-app-privacy-policy.html';

/// "Localização" aqui é aproximada pelo locale/região configurados no
/// dispositivo (ou no navegador, na Web) - não é GPS nem IP, já que o app
/// não pede permissão de localização pra isso. Retorna true quando a região
/// do locale é Brasil (BR).
bool localeIndicaBrasil(Locale locale) => locale.countryCode == 'BR';

/// Monta a URL da política de privacidade a exibir: usuários com locale de
/// Brasil (BR) veem a página traduzida automaticamente pro português, via o
/// proxy translate.goog do Google Tradutor (não exige manter uma segunda
/// cópia manual do texto). Qualquer outra região vê a página original, em
/// inglês.
String urlPoliticaPrivacidadeParaLocale(Locale locale) {
  if (localeIndicaBrasil(locale)) {
    return 'https://ptkplaysapp-blogspot-com.translate.goog'
        '/2025/12/ptk-plays-app-privacy-policy.html'
        '?_x_tr_sl=en&_x_tr_tl=pt&_x_tr_hl=pt-BR&_x_tr_pto=wapp';
  }
  return urlPoliticaPrivacidade;
}

/// Abre a política de privacidade. Em Android/iOS/desktop, dentro do
/// próprio app ([PoliticaPrivacidadeWeb], com WebView nativa). Na Web,
/// numa aba nova do navegador em vez de tentar embutir num iframe: o
/// `translate.goog` (e possivelmente o próprio Blogger) recusa ser
/// carregado dentro de um iframe de outro site por segurança - isso é uma
/// restrição do lado de quem hospeda a página, não algo que dê pra
/// contornar do nosso lado. Abrir a URL diretamente (navegação de topo,
/// sem iframe) não esbarra nessa restrição.
Future<void> abrirPoliticaPrivacidade(BuildContext context) async {
  if (!kIsWeb) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PoliticaPrivacidadeWeb()));
    return;
  }

  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final uri = Uri.parse(urlPoliticaPrivacidadeParaLocale(locale));
  final consegueAbrir = await launcher_url.canLaunchUrl(uri);
  if (!context.mounted) return;

  if (consegueAbrir) {
    await launcher_url.launchUrl(uri, mode: launcher_url.LaunchMode.externalApplication);
  } else {
    mostrarErroCustom(context, title: "Ops!", msg: "Não foi possível abrir a política de privacidade :/");
  }
}
