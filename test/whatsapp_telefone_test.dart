// Testa a mascara "+55 (DD) NNNNN-NNNN" do campo opcional de WhatsApp
// adicionado no cadastro (lib/view/Cadastro.dart) e a validacao que anda
// junto dela. O numero e usado futuramente em notificacoes/recuperacao de
// conta/2FA via WhatsApp Business API (ver ROADMAP.md).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/MascaraTelefoneWhatsapp.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';

TextEditingValue _digitar(String textoDigitado) {
  return MascaraTelefoneWhatsapp().formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: textoDigitado, selection: TextSelection.collapsed(offset: textoDigitado.length)),
  );
}

void main() {
  group('MascaraTelefoneWhatsapp', () {
    test('campo vazio mostra o DDI fixo e os espacos do DDD/numero em branco', () {
      expect(_digitar('').text, '+55 (  )      -    ');
    });

    test('primeiro digito preenche o inicio do DDD, resto continua em branco', () {
      final resultado = _digitar('1');
      expect(resultado.text, '+55 (1 )      -    ');
      expect(resultado.selection.baseOffset, 6);
    });

    test('numero completo (DDD + 9 digitos) fica todo preenchido', () {
      final resultado = _digitar('11999998888');
      expect(resultado.text, '+55 (11) 99999-8888');
      expect(resultado.selection.baseOffset, resultado.text.length);
    });

    test('digitos alem dos 11 esperados sao truncados', () {
      final resultado = _digitar('551199999888899');
      expect(resultado.text, '+55 (55) 11999-9988');
    });
  });

  group('validarTelefoneWhatsapp (recebe o texto ja mascarado)', () {
    test('mascara vazia (nada digitado) e valida, pois o campo e opcional', () {
      expect(validarTelefoneWhatsapp(MascaraTelefoneWhatsapp.mascaraVazia), isNull);
    });

    test('numero completo com DDD + 9 digitos (celular) e valido', () {
      expect(validarTelefoneWhatsapp('+55 (11) 99999-8888'), isNull);
    });

    test('numero completo com DDD + 8 digitos (fixo) e valido', () {
      expect(validarTelefoneWhatsapp('+55 (11) 9999-8888'), isNull);
    });

    test('numero incompleto (faltando digitos do DDD/numero) e invalido', () {
      expect(validarTelefoneWhatsapp('+55 (11) 999-8888'), isNotNull);
    });

    test('so o DDD preenchido, sem numero, e invalido', () {
      expect(validarTelefoneWhatsapp('+55 (11)      -    '), isNotNull);
    });
  });
}
