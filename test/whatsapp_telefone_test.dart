// Testa a mascara de telefone do cadastro (lib/view/Cadastro.dart e o
// fluxo novo em lib/view/CriarConta.dart) e a validacao que anda junto
// dela. Aceita os dois formatos brasileiros: fixo "+55 (DD) NNNN-NNNN" (10
// digitos) e celular "+55 (DD) NNNNN-NNNN" (11). O numero e usado
// futuramente em notificacoes/recuperacao de conta/2FA via WhatsApp
// Business API (ver ROADMAP.md).

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
    test('campo vazio mostra so o DDI fixo', () {
      expect(_digitar('').text, '+55 ');
    });

    test('a mascara cresce conforme os digitos entram', () {
      final resultado = _digitar('1');
      expect(resultado.text, '+55 (1');
      expect(resultado.selection.baseOffset, 6);

      expect(_digitar('11').text, '+55 (11)');
      expect(_digitar('1199').text, '+55 (11) 99');
    });

    test('numero de celular (DDD + 9 digitos) fica todo preenchido', () {
      final resultado = _digitar('11999998888');
      expect(resultado.text, '+55 (11) 99999-8888');
      expect(resultado.selection.baseOffset, resultado.text.length);
    });

    test('numero fixo (DDD + 8 digitos) usa o separador uma casa antes', () {
      final resultado = _digitar('1133334444');
      expect(resultado.text, '+55 (11) 3333-4444');
      expect(resultado.selection.baseOffset, resultado.text.length);
    });

    test('o 11o digito reformata de fixo pra celular', () {
      // O usuario digitando um celular passa pelo formato de fixo no meio do
      // caminho; ao chegar o ultimo digito, o hifen anda uma casa.
      expect(_digitar('1199999888').text, '+55 (11) 9999-9888');
      expect(_digitar('11999998888').text, '+55 (11) 99999-8888');
    });

    test('digitos alem dos 11 esperados sao truncados', () {
      final resultado = _digitar('551199999888899');
      expect(resultado.text, '+55 (55) 11999-9988');
    });
  });

  group('MascaraTelefoneWhatsapp (edicao em cima de um campo ja mascarado)', () {
    // Regressao relatada pelo usuario: apagar ou alterar um digito dentro da
    // mascara (nao so no final) nao funcionava. A causa era o formatador
    // extrair digitos do texto INTEIRO (incluindo o "+55" fixo do prefixo,
    // que tambem contem os digitos '5' e '5'), absorvendo esses 2 digitos
    // "de mentira" como se fossem do DDD e deslocando todo o resto.
    final formatador = MascaraTelefoneWhatsapp();

    test('apagar o primeiro digito do DDD desloca o resto pra esquerda corretamente', () {
      // Estado anterior real (nao a partir de vazio): "+55 (19) 87654-3210".
      final oldValue = TextEditingValue(text: '+55 (19) 87654-3210', selection: const TextSelection.collapsed(offset: 6));
      // Backspace no primeiro digito do DDD ('1' no index 5): o proprio
      // Flutter ja remove o caractere e reposiciona o cursor antes de chamar
      // o formatador.
      final newValue = const TextEditingValue(text: '+55 (9) 87654-3210', selection: TextSelection.collapsed(offset: 5));

      final resultado = formatador.formatEditUpdate(oldValue, newValue);

      // Sem o fix, o "+55" vazava como 2 digitos extras: o DDD virava "55"
      // (o proprio prefixo, nunca o que o usuario digitou) e o ultimo digito
      // real era descartado por estourar o limite de 11.
      expect(resultado.text, '+55 (98) 7654-3210');
      expect(resultado.selection.baseOffset, 5);
    });

    test('apagar um digito do meio do numero desloca so o resto a partir dali', () {
      final oldValue = TextEditingValue(text: '+55 (11) 98765-4321', selection: const TextSelection.collapsed(offset: 11));
      // Apaga o '8' logo depois do DDD (mantendo o "+55 (11) " intacto).
      final newValue = const TextEditingValue(text: '+55 (11) 9765-4321', selection: TextSelection.collapsed(offset: 10));

      final resultado = formatador.formatEditUpdate(oldValue, newValue);

      expect(resultado.text, '+55 (11) 9765-4321');
      expect(resultado.selection.baseOffset, 10);
    });

    test('digitar um digito no meio insere ali, sem confundir com o prefixo fixo', () {
      final oldValue = TextEditingValue(text: '+55 (11) 9765-4321', selection: const TextSelection.collapsed(offset: 10));
      // Digita '8' de volta na mesma posicao onde foi apagado no teste anterior.
      final newValue = const TextEditingValue(text: '+55 (11) 89765-4321', selection: TextSelection.collapsed(offset: 11));

      final resultado = formatador.formatEditUpdate(oldValue, newValue);

      expect(resultado.text, '+55 (11) 89765-4321');
      expect(resultado.selection.baseOffset, 11);
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
      expect(validarTelefoneWhatsapp('+55 (11)'), isNotNull);
    });

    test('paraSalvar devolve o numero limpo com o DDI, nos dois formatos', () {
      expect(MascaraTelefoneWhatsapp.paraSalvar('+55 (11) 99999-8888'), '+5511999998888');
      expect(MascaraTelefoneWhatsapp.paraSalvar('+55 (11) 3333-4444'), '+551133334444');
      expect(MascaraTelefoneWhatsapp.paraSalvar(MascaraTelefoneWhatsapp.mascaraVazia), '');
    });

    test('aplicarEm reconstroi a mascara de um numero ja salvo', () {
      expect(MascaraTelefoneWhatsapp.aplicarEm('+5511999998888'), '+55 (11) 99999-8888');
      expect(MascaraTelefoneWhatsapp.aplicarEm('+551133334444'), '+55 (11) 3333-4444');
      expect(MascaraTelefoneWhatsapp.aplicarEm(''), '+55 ');
    });
  });
}
