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

  // Nao ha group de 'validarConfirmacaoSenha': a funcao deixou de existir
  // junto com o campo "Confirme a senha" (14/set). O que substitui esse
  // teste e o widget test que garante UM campo na etapa de senha, em
  // test/criar_conta_test.dart — se o campo voltar por engano, e la que
  // quebra.

  group('validarWhatsappOpcional', () {
    test('campo vazio passa: o WhatsApp deixou de ser obrigatório em 13/set', () {
      // Era obrigatório, e isso era risco de reprovação 5.1.1(ii) — a Apple
      // recusa app que EXIGE dado pessoal não essencial ao que ele faz.
      expect(validarWhatsappOpcional(MascaraTelefoneWhatsapp.mascaraVazia), isNull);
    });

    test('número pela metade continua barrado', () {
      // O que se ganha permitindo isso seria um número que não chama
      // ninguém — pior que nenhum, porque parece que temos contato.
      expect(validarWhatsappOpcional('+55 (11) 999'), isNotNull);
    });

    test('fixo e celular completos passam', () {
      expect(validarWhatsappOpcional('+55 (11) 3333-4444'), isNull);
      expect(validarWhatsappOpcional('+55 (11) 99999-8888'), isNull);
    });
  });

  group('whatsappCompleto', () {
    test('separa vazio, pela metade e completo', () {
      expect(whatsappCompleto(MascaraTelefoneWhatsapp.mascaraVazia), isFalse);
      expect(whatsappCompleto('+55 (11) 999'), isFalse);
      expect(whatsappCompleto('+55 (11) 3333-4444'), isTrue);
      expect(whatsappCompleto('+55 (11) 99999-8888'), isTrue);
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
