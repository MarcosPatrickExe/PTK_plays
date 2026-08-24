import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/PoliticaPrivacidade.dart';

void main() {
  group('localeIndicaBrasil', () {
    test('locale pt_BR indica Brasil', () {
      expect(localeIndicaBrasil(const Locale('pt', 'BR')), isTrue);
    });

    test('locale en_US nao indica Brasil', () {
      expect(localeIndicaBrasil(const Locale('en', 'US')), isFalse);
    });

    test('locale sem countryCode nao indica Brasil', () {
      expect(localeIndicaBrasil(const Locale('pt')), isFalse);
    });
  });

  group('urlPoliticaPrivacidadeParaLocale', () {
    test('locale do Brasil retorna a URL traduzida via translate.goog', () {
      final url = urlPoliticaPrivacidadeParaLocale(const Locale('pt', 'BR'));

      expect(url, contains('ptkplaysapp-blogspot-com.translate.goog'));
      expect(url, contains('_x_tr_tl=pt'));
    });

    test('locale fora do Brasil retorna a URL original em ingles', () {
      final url = urlPoliticaPrivacidadeParaLocale(const Locale('en', 'US'));

      expect(url, urlPoliticaPrivacidade);
    });

    test('qualquer pais fora do Brasil (ex: Portugal, tambem pt) fica em ingles', () {
      final url = urlPoliticaPrivacidadeParaLocale(const Locale('pt', 'PT'));

      expect(url, urlPoliticaPrivacidade);
    });
  });
}
