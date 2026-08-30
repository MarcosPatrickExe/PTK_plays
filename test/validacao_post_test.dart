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
}
