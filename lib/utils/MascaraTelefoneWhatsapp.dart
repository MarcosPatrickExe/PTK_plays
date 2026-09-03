import 'package:flutter/services.dart';

/// Mascara o campo de telefone (WhatsApp) no formato brasileiro, com o DDI
/// "+55" sempre visivel. Aceita os dois tamanhos que existem no Brasil:
///
/// - **fixo**, 10 digitos: `+55 (DD) NNNN-NNNN`
/// - **celular**, 11 digitos: `+55 (DD) NNNNN-NNNN`
///
/// O formato e decidido pela quantidade de digitos ja informados: enquanto
/// houver 10 ou menos, o campo se comporta como fixo (4+4); ao chegar o 11o
/// digito, o separador anda uma casa e vira celular (5+4). E por isso que a
/// mascara **cresce** conforme a digitacao, em vez de mostrar um gabarito de
/// espacos em branco: com dois formatos possiveis, um gabarito fixo estaria
/// errado pra metade dos numeros.
class MascaraTelefoneWhatsapp extends TextInputFormatter {
  /// Estado inicial do campo, antes de qualquer digito ser informado.
  static const mascaraVazia = '+55 ';

  /// Quantidade de digitos de um telefone fixo (DDD + 8), e de um celular
  /// (DDD + 9) — o maximo que o campo aceita.
  static const digitosDeFixo = 10;
  static const digitosDeCelular = 11;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // O "+55" fixo do prefixo tambem contem digitos ('5','5'): se extrairmos
    // digitos do texto inteiro, esses 2 digitos "de mentira" entram na
    // contagem junto com os digitos reais do DDD/numero, deslocando tudo e
    // quebrando qualquer edicao/apagamento que nao seja no fim do campo. Por
    // isso removemos o prefixo fixo antes de extrair os digitos reais.
    final corpo = newValue.text.startsWith('+55') ? newValue.text.substring(3) : newValue.text;
    final todosDigitos = corpo.replaceAll(RegExp(r'[^0-9]'), '');
    final digitos = todosDigitos.length > digitosDeCelular
        ? todosDigitos.substring(0, digitosDeCelular)
        : todosDigitos;

    // Reposiciona o cursor com base em quantos digitos reais existiam antes
    // dele no texto editado, e nao sempre no fim: e o que permite apagar ou
    // alterar um digito no meio da mascara (ex: um digito do DDD) sem o
    // cursor pular pro final a cada edicao.
    final prefixoRemovido = newValue.text.length - corpo.length;
    final offsetNoCorpo = (newValue.selection.baseOffset - prefixoRemovido).clamp(0, corpo.length);
    final digitosAntesDoCursor = corpo.substring(0, offsetNoCorpo).replaceAll(RegExp(r'[^0-9]'), '').length;
    final digitosEfetivos = digitosAntesDoCursor > digitos.length ? digitos.length : digitosAntesDoCursor;

    return TextEditingValue(
      text: _montar(digitos),
      selection: TextSelection.collapsed(offset: _posicaoDoCursor(digitosEfetivos, digitos.length)),
    );
  }

  /// Formata um numero ja salvo (ex: "+5511999998888", ou vazio) no mesmo
  /// padrao visual do campo, pra pre-preencher o formulario de edicao de
  /// perfil com o valor que o usuario ja tinha informado no cadastro.
  static String aplicarEm(String telefoneSalvo) => _montar(digitosDe(telefoneSalvo));

  /// Extrai o valor limpo a ser salvo (ex: "+5511999998888") a partir do
  /// texto mascarado do campo, descartando o "+55" fixo do prefixo.
  /// Retorna vazio se nada foi preenchido.
  static String paraSalvar(String telefoneComMascara) {
    final digitos = digitosDe(telefoneComMascara);
    return digitos.isEmpty ? '' : '+55$digitos';
  }

  /// Os digitos do DDD + numero, sem o "+55" e sem os separadores. E o que
  /// a validacao conta pra decidir se o numero esta completo.
  static String digitosDe(String telefone) {
    final todos = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    return todos.length > 2 ? todos.substring(2) : '';
  }

  /// Quantos digitos vao antes do hifen. Com 11 digitos e celular (5+4);
  /// com 10 ou menos, fixo (4+4).
  static int _digitosAntesDoHifen(int totalDeDigitos) => totalDeDigitos > digitosDeFixo ? 5 : 4;

  /// Monta o texto visivel a partir dos digitos reais, revelando cada
  /// separador so quando ha digito pra depois dele.
  static String _montar(String digitos) {
    if (digitos.isEmpty) return mascaraVazia;
    if (digitos.length < 2) return '+55 ($digitos';

    final ddd = digitos.substring(0, 2);
    final resto = digitos.substring(2);
    if (resto.isEmpty) return '+55 ($ddd)';

    final antesDoHifen = _digitosAntesDoHifen(digitos.length);
    if (resto.length <= antesDoHifen) return '+55 ($ddd) $resto';

    return '+55 ($ddd) ${resto.substring(0, antesDoHifen)}-${resto.substring(antesDoHifen)}';
  }

  /// Onde o cursor fica depois de [digitosAntes] digitos, num numero que tem
  /// [totalDeDigitos] no total (o total decide se o formato e de fixo ou de
  /// celular, o que muda a posicao do hifen).
  static int _posicaoDoCursor(int digitosAntes, int totalDeDigitos) {
    // Nenhum digito antes do cursor: no campo vazio ele fica no fim do DDI;
    // com o campo preenchido, logo antes do primeiro digito do DDD.
    if (digitosAntes == 0) return totalDeDigitos == 0 ? mascaraVazia.length : 5;

    // '+55 (' = 5 caracteres antes do primeiro digito do DDD.
    if (digitosAntes < 2) return 5 + digitosAntes;
    // '+55 (DD)' = 8 caracteres.
    if (digitosAntes == 2) return 8;
    // '+55 (DD) ' = 9 caracteres antes do primeiro digito do numero.
    if (digitosAntes <= 2 + _digitosAntesDoHifen(totalDeDigitos)) return 9 + (digitosAntes - 2);
    // Passou do hifen: soma 1 caractere por causa dele.
    return 10 + (digitosAntes - 2);
  }
}
