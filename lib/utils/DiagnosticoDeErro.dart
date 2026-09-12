import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'AuthErrorTranslator.dart';

/// O padrao de mensagem de erro do app: texto em portugues pra pessoa, mais
/// um codigo curto que diz A CAUSA pra quem vai investigar.
///
/// Por que isto existe, e por que vale a feiura do codigo na tela: em build
/// de release o `debugPrint` do try/catch nao vai a lugar nenhum. Quem
/// reporta uma falha e sempre alguem sem o aparelho plugado num Mac — um
/// revisor da App Store, um inscrito no Discord, o proprio usuario do app.
/// O que chega ate nos e um print da tela. Se o print so diz "Ops! Tente
/// novamente", a investigacao comeca do zero.
///
/// Foi exatamente isso que aconteceu com o login da Apple: DUAS rodadas de
/// revisao da App Store (17/ago e 27/ago de 2026) gastas adivinhando a
/// causa a partir de um popup generico, porque "provedor desligado no
/// Firebase", "regra do Firestore barrou a escrita" e "a Apple recusou"
/// produziam a MESMA tela. Ver CHECKPOINT.md, atencao 4.
///
/// **Quando NAO usar**: erro de validacao de formulario (campo vazio, senha
/// curta, e-mail invalido). Ali nao houve excecao nenhuma — nao ha causa
/// pra diagnosticar, e o codigo seria ruido em cima de uma mensagem que a
/// pessoa ja sabe como resolver. Ver a regra do Toast/modal no CLAUDE.md.

/// Identificador curto e estavel da falha, no formato `familia/detalhe`.
///
/// A familia importa mais que o detalhe: ela diz em qual camada parar de
/// procurar. `auth/` e o Firebase Auth, `cloud_firestore/` sao as regras ou
/// a rede, `firebase_storage/` e o upload, `apple/` e `google/` sao os
/// provedores, `plataforma/` e codigo nativo (camera, galeria, navegador).
String codigoDeErro(Object erro) {
  // Os dois provedores sociais vem primeiro porque sao os unicos tipos que
  // nao herdam de nada abaixo — a ordem aqui e so legibilidade.
  final codigoSocial = _codigoDeProvedorSocial(erro);
  if (codigoSocial != null) return codigoSocial;

  // FirebaseAuthException E uma FirebaseException: tem que vir antes, senao
  // todo erro de autenticacao seria rotulado com o plugin generico.
  if (erro is FirebaseAuthException) return 'auth/${erro.code}';
  if (erro is FirebaseException) return '${erro.plugin}/${erro.code}';
  if (erro is PlatformException) return 'plataforma/${erro.code}';
  return 'inesperado/${erro.runtimeType}';
}

/// Cola o codigo na mensagem. Duas linhas em branco no meio porque o codigo
/// nao e parte da frase — ele e a nota de rodape que a pessoa vai fotografar
/// junto sem precisar entender.
String comCodigo(String mensagem, Object erro) =>
    comCodigoManual(mensagem, codigoDeErro(erro));

/// Mesma coisa, pra falha que **nao tem excecao**: quando e o proprio app
/// que detecta a condicao, como um link que nenhum aplicativo instalado
/// sabe abrir (`canLaunchUrl` devolve false sem lancar nada).
///
/// Inventar um `Exception` so pra ter o que passar pro [comCodigo] seria
/// pior: o codigo diria o tipo da excecao falsa, e nao a condicao real.
/// Aqui o codigo e escrito a mao — mas o formato na tela e o mesmo, que e o
/// que importa pra quem le o print.
String comCodigoManual(String mensagem, String codigo) => '$mensagem\n\n(código: $codigo)';

/// A melhor frase em portugues que se consegue dizer sobre [erro], sem o
/// codigo (use [comCodigo] pra juntar os dois).
///
/// A generica de verdade — "Algo deu errado" — e o ultimo recurso, nao o
/// primeiro: quase toda falha real do app cai num codigo conhecido do
/// Firebase, e dizer "sem conexao" ou "voce nao tem permissao" poupa a
/// pessoa de tentar de novo a esmo.
String mensagemDeErro(Object erro) {
  if (erro is FirebaseAuthException) return traduzirErroDeAuth(erro.code);
  if (erro is FirebaseException) return traduzirErroDeServico(erro.code);
  return 'Algo deu errado. Tente novamente.';
}

/// [mensagemDeErro] + [comCodigo] numa chamada so — o caminho normal.
String mensagemComCodigo(Object erro) => comCodigo(mensagemDeErro(erro), erro);

String? _codigoDeProvedorSocial(Object erro) {
  // Casadas por nome de tipo, e nao por `is`, de proposito: assim este
  // arquivo nao precisa importar sign_in_with_apple nem google_sign_in, que
  // sao pacotes so de plataforma. Um `is` aqui puxaria os dois pra dentro de
  // qualquer teste que tocasse neste util.
  final tipo = erro.runtimeType.toString();
  if (tipo == 'SignInWithAppleAuthorizationException') {
    return 'apple/${_campoCode(erro)}';
  }
  if (tipo == 'GoogleSignInException') return 'google/${_campoCode(erro)}';
  return null;
}

/// O `code` dos dois pacotes sociais e um enum, cujo `toString()` sai como
/// `AuthorizationErrorCode.unknown`. Aqui fica so o `unknown`.
String _campoCode(Object erro) {
  try {
    final bruto = (erro as dynamic).code.toString();
    final ponto = bruto.lastIndexOf('.');
    return ponto == -1 ? bruto : bruto.substring(ponto + 1);
  } catch (_) {
    return 'desconhecido';
  }
}
