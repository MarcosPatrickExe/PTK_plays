// Testa as pecas puras usadas pela tela de edicao de perfil
// (lib/view/EditarPerfil.dart): validacao do nickname, validacao do avatar
// pre-definido e o round-trip da mascara de WhatsApp entre o valor salvo no
// Firestore e o texto exibido no campo (pre-preenchimento do formulario).

import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/AvatarPreset.dart';
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

  group('validarAvatarPreset', () {
    test('null (nenhum avatar escolhido) e invalido', () {
      expect(validarAvatarPreset(null), isNotNull);
    });

    test('string vazia e invalida', () {
      expect(validarAvatarPreset(''), isNotNull);
    });

    test('chave que nao existe no catalogo e invalida', () {
      expect(validarAvatarPreset('atleta'), isNotNull);
    });

    test('chave valida do catalogo retorna null', () {
      expect(validarAvatarPreset('gamer'), isNull);
    });
  });

  group('catalogoAvataresPreset', () {
    test('tem exatamente os 6 personas definidos', () {
      final chaves = catalogoAvataresPreset.map((p) => p.chave).toSet();
      expect(chaves, {'gamer', 'streamer', 'inscrito', 'blogueiro', 'maratonista', 'otaku'});
    });

    test('assetDoAvatarPreset resolve o caminho de uma chave valida', () {
      expect(assetDoAvatarPreset('otaku'), 'assets/avatares/avatar_otaku.png');
    });

    test('assetDoAvatarPreset retorna null pra chave vazia ou invalida', () {
      expect(assetDoAvatarPreset(''), isNull);
      expect(assetDoAvatarPreset('inexistente'), isNull);
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
