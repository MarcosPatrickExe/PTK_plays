import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher_url;
import '../components/ModalMSG.dart';

/// URL da política de privacidade do PTK Plays, hospedada no Blogger.
const String urlPoliticaPrivacidade = 'https://ptkplaysapp.blogspot.com/2025/12/ptk-plays-app-privacy-policy.html';

/// Abre uma URL externa no navegador do dispositivo. Mostra o modal de erro
/// padrão se não for possível abrir - mesma UX já usada pra abrir vídeo do
/// YouTube em Videos.dart, extraída aqui porque o menu lateral precisa da
/// mesma coisa pra abrir a política de privacidade.
Future<void> abrirLinkExterno(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final consegueAbrir = await launcher_url.canLaunchUrl(uri);
  if (!context.mounted) return;

  if (consegueAbrir) {
    await launcher_url.launchUrl(uri, mode: launcher_url.LaunchMode.externalApplication);
  } else {
    mostrarErroCustom(context, title: "Ops!", msg: "Não foi possível abrir o link :/");
  }
}
