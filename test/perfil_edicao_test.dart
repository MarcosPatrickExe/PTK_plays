// Testa as pecas puras usadas pela tela de edicao de perfil
// (lib/view/EditarPerfil.dart): validacao do nickname e o round-trip da
// mascara de WhatsApp entre o valor salvo no Firestore e o texto exibido
// no campo (pre-preenchimento do formulario).

import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/MascaraTelefoneWhatsapp.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';

void main() {
  group('validarNickname', () {
    test('nickname vazio e invalido', () {
      expect(validarNickname(''), isNotNull);
    });

    test('nickname so com espacos e invalido', () {
      expect(validarNickname('   '), isNotNull);
    });

    test('nickname com @ e invalido', () {
      expect(validarNickname('fulano@teste'), isNotNull);
    });

    test('nickname valido retorna null', () {
      expect(validarNickname('Fulano'), isNull);
    });
  });

  group('MascaraTelefoneWhatsapp.aplicarEm (pre-preenche o campo de edicao)', () {
    test('telefone vazio salvo vira a mascara vazia', () {
      expect(MascaraTelefoneWhatsapp.aplicarEm(''), MascaraTelefoneWhatsapp.mascaraVazia);
    });

    test('telefone salvo no formato +55DDNNNNNNNNN preenche a mascara', () {
      expect(MascaraTelefoneWhatsapp.aplicarEm('+5511999998888'), '+55 (11) 99999-8888');
    });
  });

  group('MascaraTelefoneWhatsapp.paraSalvar (ida e volta com aplicarEm)', () {
    test('mascara vazia nao gera nada pra salvar', () {
      expect(MascaraTelefoneWhatsapp.paraSalvar(MascaraTelefoneWhatsapp.mascaraVazia), '');
    });

    test('numero preenchido volta pro mesmo formato salvo originalmente', () {
      const original = '+5511999998888';
      final mascarado = MascaraTelefoneWhatsapp.aplicarEm(original);
      expect(MascaraTelefoneWhatsapp.paraSalvar(mascarado), original);
    });
  });
}
