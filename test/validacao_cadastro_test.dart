import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/MascaraTelefoneWhatsapp.dart';
import 'package:ptk_plays/utils/ValidacaoCadastro.dart';

void main() {
  group('validarNickname', () {
    test('recusa vazio e só espaço', () {
      expect(validarNickname(''), isNotNull);
      expect(validarNickname('   '), isNotNull);
    });

    test('recusa nick curto demais', () {
      expect(validarNickname('ab'), isNotNull);
      expect(validarNickname('abc'), isNull);
    });

    test('recusa nick longo demais', () {
      expect(validarNickname('a' * (maximoCaracteresNickname + 1)), isNotNull);
      expect(validarNickname('a' * maximoCaracteresNickname), isNull);
    });

    test('recusa @, que o login usa pra diferenciar nick de e-mail', () {
      expect(validarNickname('fulano@teste'), isNotNull);
    });

    test('aceita um nick normal', () {
      expect(validarNickname('PTKzin'), isNull);
    });
  });

  group('validarEmail', () {
    test('recusa vazio e formatos sem cara de e-mail', () {
      expect(validarEmail(''), isNotNull);
      expect(validarEmail('fulano'), isNotNull);
      expect(validarEmail('fulano@'), isNotNull);
      expect(validarEmail('fulano@teste'), isNotNull);
      expect(validarEmail('fulano @teste.com'), isNotNull);
    });

    test('aceita um e-mail normal', () {
      expect(validarEmail('fulano@teste.com'), isNull);
      expect(validarEmail('  fulano@teste.com.br '), isNull);
    });
  });

  group('validarConfirmacaoEmail', () {
    test('recusa confirmação vazia', () {
      expect(validarConfirmacaoEmail(email: 'a@b.com', confirmacao: ''), isNotNull);
    });

    test('recusa e-mails diferentes', () {
      expect(validarConfirmacaoEmail(email: 'a@b.com', confirmacao: 'c@d.com'), isNotNull);
    });

    test('aceita iguais, ignorando espaços e maiúsculas', () {
      expect(validarConfirmacaoEmail(email: 'a@b.com', confirmacao: ' A@B.com '), isNull);
    });
  });

  group('validarSenha', () {
    test('recusa vazia e curta', () {
      expect(validarSenha(''), isNotNull);
      expect(validarSenha('a' * (minimoCaracteresSenha - 1)), isNotNull);
    });

    test('aceita a partir do mínimo', () {
      expect(validarSenha('a' * minimoCaracteresSenha), isNull);
    });
  });

  group('validarConfirmacaoSenha', () {
    test('recusa vazia e diferente', () {
      expect(validarConfirmacaoSenha(senha: '123456', confirmacao: ''), isNotNull);
      expect(validarConfirmacaoSenha(senha: '123456', confirmacao: '123457'), isNotNull);
    });

    test('senha diferencia maiúscula de minúscula, ao contrário do e-mail', () {
      expect(validarConfirmacaoSenha(senha: 'Senha123', confirmacao: 'senha123'), isNotNull);
    });

    test('aceita iguais', () {
      expect(validarConfirmacaoSenha(senha: '123456', confirmacao: '123456'), isNull);
    });
  });

  group('validarWhatsappObrigatorio', () {
    test('recusa vazio — aqui o número não é opcional', () {
      expect(validarWhatsappObrigatorio(MascaraTelefoneWhatsapp.mascaraVazia), isNotNull);
    });

    test('recusa número incompleto', () {
      expect(validarWhatsappObrigatorio('+55 (11) 999'), isNotNull);
    });

    test('aceita fixo (10 dígitos) e celular (11)', () {
      expect(validarWhatsappObrigatorio('+55 (11) 3333-4444'), isNull);
      expect(validarWhatsappObrigatorio('+55 (11) 99999-8888'), isNull);
    });
  });

  group('validarFotoEscolhida', () {
    test('recusa quando não há preset nem foto tirada', () {
      expect(validarFotoEscolhida(avatarPreset: null, temFotoPropria: false), isNotNull);
      expect(validarFotoEscolhida(avatarPreset: '', temFotoPropria: false), isNotNull);
    });

    test('aceita com preset escolhido ou com foto própria', () {
      expect(validarFotoEscolhida(avatarPreset: 'otaku', temFotoPropria: false), isNull);
      expect(validarFotoEscolhida(avatarPreset: null, temFotoPropria: true), isNull);
    });
  });
}
