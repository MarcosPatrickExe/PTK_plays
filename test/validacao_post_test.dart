import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/ValidacaoPost.dart';

void main() {
  group('validarAviso', () {
    test('recusa texto vazio ou só espaço', () {
      expect(validarAviso(''), isNotNull);
      expect(validarAviso('    '), isNotNull);
    });

    test('aceita um aviso normal', () {
      expect(validarAviso('Live hoje às 21h!'), isNull);
    });

    test('recusa acima do limite de caracteres', () {
      expect(validarAviso('a' * (limiteCaracteresAviso + 1)), isNotNull);
      expect(validarAviso('a' * limiteCaracteresAviso), isNull);
    });
  });

  group('validarEnquete', () {
    test('exige pergunta', () {
      expect(validarEnquete(pergunta: '  ', opcoes: ['Um', 'Dois']), isNotNull);
    });

    test('exige pelo menos duas opções preenchidas', () {
      expect(validarEnquete(pergunta: 'Qual jogo?', opcoes: ['Um', '   ']), isNotNull);
      expect(validarEnquete(pergunta: 'Qual jogo?', opcoes: ['Um', 'Dois']), isNull);
    });

    test('recusa opções repetidas', () {
      expect(validarEnquete(pergunta: 'Qual jogo?', opcoes: ['Um', 'Um']), isNotNull);
    });

    test('recusa mais opções do que o máximo', () {
      final demais = List.generate(maximoOpcoesEnquete + 1, (i) => 'Opção $i');
      expect(validarEnquete(pergunta: 'Qual jogo?', opcoes: demais), isNotNull);
    });
  });

  test('opcoesPreenchidas apara espaços e descarta campos vazios', () {
    expect(opcoesPreenchidas([' Um ', '', '  ', 'Dois']), ['Um', 'Dois']);
  });

  group('validarAviso com mídia', () {
    test('post sem texto é aceito quando tem foto ou vídeo anexado', () {
      expect(validarAviso('', temMidia: true), isNull);
      expect(validarAviso('   ', temMidia: true), isNull);
    });

    test('o limite de caracteres continua valendo mesmo com mídia', () {
      expect(validarAviso('a' * (limiteCaracteresAviso + 1), temMidia: true), isNotNull);
    });
  });

  group('validarTamanhoMidia', () {
    test('aceita arquivo dentro do limite de cada tipo', () {
      expect(validarTamanhoMidia(bytes: limiteBytesImagem, ehVideo: false), isNull);
      expect(validarTamanhoMidia(bytes: limiteBytesVideo, ehVideo: true), isNull);
    });

    test('recusa arquivo acima do limite', () {
      expect(validarTamanhoMidia(bytes: limiteBytesImagem + 1, ehVideo: false), isNotNull);
      expect(validarTamanhoMidia(bytes: limiteBytesVideo + 1, ehVideo: true), isNotNull);
    });

    test('vídeo tem folga maior que imagem', () {
      // Um arquivo de 20MB passa como vídeo e é recusado como imagem.
      const vinteMb = 20 * 1024 * 1024;
      expect(validarTamanhoMidia(bytes: vinteMb, ehVideo: true), isNull);
      expect(validarTamanhoMidia(bytes: vinteMb, ehVideo: false), isNotNull);
    });
  });
}
