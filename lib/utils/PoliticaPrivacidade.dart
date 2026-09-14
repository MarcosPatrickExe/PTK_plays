import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher_url;
import '../components/ModalMSG.dart';
import '../i18n/Idioma.dart';
import '../view/PoliticaPrivacidadeWeb.dart';

/// URL original (em inglês) da política de privacidade do PTK Plays,
/// hospedada no Blogger.
const String urlPoliticaPrivacidade = 'https://ptkplaysapp.blogspot.com/2025/12/ptk-plays-app-privacy-policy.html';

/// Monta a URL da política de privacidade a exibir.
///
/// Quem decide é **o idioma que o app está falando**, e não a região do
/// aparelho. Antes era `locale.countryCode == 'BR'`, e isso errava nos dois
/// sentidos: quem configurava só `pt`, sem região, lia a política em inglês
/// com o app inteiro em português; e quem trocasse o idioma na mão
/// continuaria preso à região do aparelho, que não muda junto.
///
/// Em português, a página original (em inglês) sai traduzida pelo proxy
/// `translate.goog` do Google Tradutor, em vez de mantermos uma segunda
/// cópia do texto à mão — política de privacidade em duas versões que
/// divergem com o tempo é pior que tradução automática.
String urlPoliticaPrivacidadeParaIdioma(Idioma idioma) {
  if (idioma == Idioma.ptBR) {
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

  final uri = Uri.parse(urlPoliticaPrivacidadeParaIdioma(IdiomaApp.atual));
  final consegueAbrir = await launcher_url.canLaunchUrl(uri);
  if (!context.mounted) return;

  if (consegueAbrir) {
    await launcher_url.launchUrl(uri, mode: launcher_url.LaunchMode.externalApplication);
  } else {
    mostrarErroCustom(context, title: textos.ops, msg: textos.politicaNaoAbriu);
  }
}
