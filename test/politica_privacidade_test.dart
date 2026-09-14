import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/i18n/Idioma.dart';
import 'package:ptk_plays/utils/PoliticaPrivacidade.dart';

void main() {
  group('urlPoliticaPrivacidadeParaIdioma', () {
    test('em português retorna a URL traduzida via translate.goog', () {
      final url = urlPoliticaPrivacidadeParaIdioma(Idioma.ptBR);

      expect(url, contains('ptkplaysapp-blogspot-com.translate.goog'));
      expect(url, contains('_x_tr_tl=pt'));
    });

    test('em inglês retorna a página original, sem proxy de tradução', () {
      expect(urlPoliticaPrivacidadeParaIdioma(Idioma.enUS), urlPoliticaPrivacidade);
    });

    test('quem tem só "pt", sem região, lê a política em português', () {
      // Era o buraco da versão anterior, que decidia por
      // `locale.countryCode == 'BR'`: um aparelho configurado em `pt` sem
      // região caía no inglês com o app inteiro em português. Agora quem
      // manda é o idioma que o app resolveu falar, e ele não depende de
      // região nenhuma.
      final idioma = idiomaPara([const Locale('pt')]);

      expect(idioma, Idioma.ptBR);
      expect(urlPoliticaPrivacidadeParaIdioma(idioma), contains('translate.goog'));
    });

    test('português de Portugal também lê em português', () {
      // Mudança de comportamento consciente: antes pt_PT ia pro inglês,
      // porque a regra olhava o país. Uma pessoa que configurou o aparelho
      // em português lê melhor em português — mesmo que a tradução
      // automática seja pro pt-BR.
      final idioma = idiomaPara([const Locale('pt', 'PT')]);

      expect(idioma, Idioma.ptBR);
    });
  });

  // abrirPoliticaPrivacidade (lib/utils/PoliticaPrivacidade.dart) nao tem
  // teste automatizado direto: fora da Web ela navega pra
  // PoliticaPrivacidadeWeb, que usa InAppWebView - esse widget nao
  // consegue ser construido no ambiente do `flutter test` (sem os
  // bindings de plataforma do plugin, o teste trava/falha so de tentar
  // montar a arvore). Na Web, o ramo abre uma aba nova via url_launcher,
  // dependente de navegador de verdade. Nenhum dos dois ramos e validavel
  // neste ambiente - so a logica pura de URL/idioma acima e testada.
}
