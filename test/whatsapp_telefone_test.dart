// Testa a validacao do campo opcional de WhatsApp adicionado no cadastro
// (lib/view/Cadastro.dart), que permite ao usuario informar o numero para
// uso futuro em notificacoes/recuperacao de conta/2FA via WhatsApp Business
// API (ver ROADMAP.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';

void main() {
  group('validarTelefoneWhatsapp', () {
    test('campo vazio e valido, pois e opcional', () {
      expect(validarTelefoneWhatsapp(''), isNull);
    });

    test('campo so com espacos e valido (equivale a vazio)', () {
      expect(validarTelefoneWhatsapp('   '), isNull);
    });

    test('numero com DDD e valido', () {
      expect(validarTelefoneWhatsapp('11999998888'), isNull);
    });

    test('numero formatado com parenteses/traco/espacos e valido', () {
      expect(validarTelefoneWhatsapp('(11) 99999-8888'), isNull);
    });

    test('numero internacional com + e codigo de pais e valido', () {
      expect(validarTelefoneWhatsapp('+55 11 99999-8888'), isNull);
    });

    test('numero curto demais (sem DDD) e invalido', () {
      expect(validarTelefoneWhatsapp('998888'), isNotNull);
    });

    test('numero absurdamente longo e invalido', () {
      expect(validarTelefoneWhatsapp('1234567890123456'), isNotNull);
    });
  });
}
