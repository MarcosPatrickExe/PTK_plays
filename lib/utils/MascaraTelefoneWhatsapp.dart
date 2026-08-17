import 'package:flutter/services.dart';

/// Mascara o campo opcional de WhatsApp do cadastro no formato brasileiro
/// fixo "+55 (DD) NNNNN-NNNN": o DDI "+55" fica sempre visivel, e o DDD/
/// numero comecam em branco ate o usuario preencher.
class MascaraTelefoneWhatsapp extends TextInputFormatter {
  /// Estado inicial do campo, antes de qualquer digito ser informado.
  static const mascaraVazia = '+55 (  )      -    ';

  // Posicao (0-indexada) de cada uma das 11 posicoes de digito no texto
  // formatado "+55 (DD) NNNNN-NNNN", usada pra reposicionar o cursor sempre
  // logo apos o ultimo digito real (nunca em cima de um espaco em branco da
  // mascara), pra que apagar com backspace funcione de forma previsivel.
  static const _posicoesDosDigitos = [5, 6, 9, 10, 11, 12, 13, 15, 16, 17, 18];

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final todosDigitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final digitos = todosDigitos.length > 11 ? todosDigitos.substring(0, 11) : todosDigitos;

    final texto = _montar(digitos);
    final cursor = digitos.isEmpty ? _posicoesDosDigitos.first : _posicoesDosDigitos[digitos.length - 1] + 1;

    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: cursor));
  }

  /// Formata um numero ja salvo (ex: "+5511999998888", ou vazio) no mesmo
  /// padrao visual do campo, pra pre-preencher o formulario de edicao de
  /// perfil com o valor que o usuario ja tinha informado no cadastro.
  static String aplicarEm(String telefoneSalvo) {
    final todosDigitos = telefoneSalvo.replaceAll(RegExp(r'[^0-9]'), '');
    final digitos = todosDigitos.length > 2 ? todosDigitos.substring(2) : '';
    return _montar(digitos);
  }

  /// Extrai o valor limpo a ser salvo (ex: "+5511999998888") a partir do
  /// texto mascarado do campo, descartando o "+55" fixo do prefixo.
  /// Retorna vazio se nada foi preenchido.
  static String paraSalvar(String telefoneComMascara) {
    final todosDigitos = telefoneComMascara.replaceAll(RegExp(r'[^0-9]'), '');
    final digitos = todosDigitos.length > 2 ? todosDigitos.substring(2) : '';
    return digitos.isEmpty ? '' : '+55$digitos';
  }

  static String _montar(String digitos) {
    final ddd = digitos.length >= 2 ? digitos.substring(0, 2) : digitos.padRight(2, ' ');
    final resto = digitos.length > 2 ? digitos.substring(2) : '';
    final parte1 = (resto.length >= 5 ? resto.substring(0, 5) : resto).padRight(5, ' ');
    final parte2 = (resto.length > 5 ? resto.substring(5) : '').padRight(4, ' ');
    return '+55 ($ddd) $parte1-$parte2';
  }
}
