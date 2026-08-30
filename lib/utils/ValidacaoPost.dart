/// Validacao dos campos de uma nova publicacao do feed (ver
/// `lib/components/NovoPost.dart`). Fica separada da UI porque e a unica
/// parte do fluxo de publicar que da pra testar sem Firestore.
///
/// Retornam null quando esta tudo certo, ou a mensagem de erro pronta pra
/// ir no modal bloqueante (`mostrarErroCustom`), conforme a regra de
/// feedback do CLAUDE.md: erro de validacao de formulario e modal, nao
/// toast.
library;

const int limiteCaracteresAviso = 500;
const int limiteCaracteresPergunta = 120;
const int maximoOpcoesEnquete = 5;
const int minimoOpcoesEnquete = 2;

String? validarAviso(String texto) {
  final valor = texto.trim();
  if (valor.isEmpty) return 'Escreva alguma coisa antes de publicar.';
  if (valor.length > limiteCaracteresAviso) {
    return 'O aviso passou de $limiteCaracteresAviso caracteres. Encurte um pouco.';
  }
  return null;
}

/// [opcoes] vem crua da UI (um campo de texto por linha, alguns podem estar
/// vazios porque o usuario nao preencheu todos). Quem limpa isso e
/// [opcoesPreenchidas], usada tambem na hora de salvar.
String? validarEnquete({required String pergunta, required List<String> opcoes}) {
  final titulo = pergunta.trim();
  if (titulo.isEmpty) return 'Escreva a pergunta da enquete.';
  if (titulo.length > limiteCaracteresPergunta) {
    return 'A pergunta passou de $limiteCaracteresPergunta caracteres. Encurte um pouco.';
  }

  final validas = opcoesPreenchidas(opcoes);
  if (validas.length < minimoOpcoesEnquete) {
    return 'Uma enquete precisa de pelo menos $minimoOpcoesEnquete opções preenchidas.';
  }
  if (validas.length > maximoOpcoesEnquete) {
    return 'Uma enquete aceita no máximo $maximoOpcoesEnquete opções.';
  }
  if (validas.toSet().length != validas.length) {
    return 'Tem opções repetidas na enquete.';
  }
  return null;
}

List<String> opcoesPreenchidas(List<String> opcoes) =>
    opcoes.map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
