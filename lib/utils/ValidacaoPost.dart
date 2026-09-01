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

/// Tamanho maximo da midia anexada a um post (so o admin anexa). O
/// `storage.rules` repete esses numeros — la e que eles valem de verdade,
/// aqui e so pra avisar antes de gastar a conexao do usuario.
const int limiteBytesImagem = 10 * 1024 * 1024;
const int limiteBytesVideo = 50 * 1024 * 1024;
const int limiteCaracteresPergunta = 120;
const int maximoOpcoesEnquete = 5;
const int minimoOpcoesEnquete = 2;

/// [temMidia] afrouxa a exigencia de texto: um post que ja tem foto ou
/// video nao precisa de legenda pra fazer sentido.
String? validarAviso(String texto, {bool temMidia = false}) {
  final valor = texto.trim();
  if (valor.isEmpty && !temMidia) return 'Escreva alguma coisa antes de publicar.';
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

/// Checa o tamanho do arquivo escolhido antes de subir. Retorna null quando
/// cabe, ou a mensagem pro modal de erro.
String? validarTamanhoMidia({required int bytes, required bool ehVideo}) {
  final limite = ehVideo ? limiteBytesVideo : limiteBytesImagem;
  if (bytes <= limite) return null;

  final limiteEmMb = limite ~/ (1024 * 1024);
  return ehVideo
      ? 'O vídeo passou de $limiteEmMb MB. Escolha um menor ou corte um trecho.'
      : 'A imagem passou de $limiteEmMb MB. Escolha uma menor.';
}
