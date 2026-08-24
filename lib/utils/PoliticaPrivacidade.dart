import 'package:flutter/widgets.dart' show Locale;

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
