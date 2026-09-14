import '../i18n/Idioma.dart';

String traduzirErroDeAuth(String codigo) {
  switch (codigo) {
    case 'email-already-in-use':
      return textos.erroEmailJaCadastrado;
    case 'invalid-email':
      return textos.erroEmailInvalido;
    case 'weak-password':
      return textos.erroSenhaFraca;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return textos.erroLoginOuSenha;
    case 'nickname-em-uso':
      return textos.erroNicknameEmUso;
    case 'too-many-requests':
      return textos.erroMuitasTentativas;
    case 'network-request-failed':
      return textos.erroSemInternet;
    case 'unauthorized-domain':
      return textos.erroDominioNaoAutorizado;
    case 'popup-blocked':
      return textos.erroPopupBloqueado;
    // Nao citar provedor aqui: este codigo vale pros dois. O Firebase o
    // devolve pra QUALQUER provedor desabilitado no Console (Authentication
    // -> Sign-in method), e a versao anterior dizia "Google" mesmo quando
    // quem tinha falhado era a Apple — mandando quem investiga pro painel
    // errado. Foi um dos suspeitos da reprovacao de 27/ago/2026.
    case 'operation-not-allowed':
      return textos.erroMetodoDesabilitado;
    default:
      return textos.erroGenerico;
  }
}

/// Traduz os codigos que NAO vem do Firebase Auth: Firestore (regras, rede)
/// e Storage (upload de foto e midia). Antes de 12/set esses erros passavam
/// por traduzirErroDeAuth, que nao conhece nenhum deles — entao um
/// `permission-denied` das regras ou um `unauthorized` do Storage caia no
/// "Algo deu errado" generico, escondendo justamente os dois casos que mais
/// aparecem quando uma regra nova nao foi publicada.
String traduzirErroDeServico(String codigo) {
  switch (codigo) {
    // Firestore e Storage usam nomes diferentes pra mesma ideia.
    case 'permission-denied':
    case 'unauthorized':
      return textos.erroSemPermissao;
    case 'unauthenticated':
      return textos.erroSessaoExpirada;
    case 'unavailable':
    case 'deadline-exceeded':
    case 'retry-limit-exceeded':
      return textos.erroServidorIndisponivel;
    case 'not-found':
    case 'object-not-found':
      return textos.erroItemNaoExiste;
    case 'already-exists':
      return textos.erroJaExiste;
    case 'resource-exhausted':
    case 'quota-exceeded':
      return textos.erroLimiteDoServico;
    case 'cancelled':
    case 'canceled':
      return textos.erroOperacaoCancelada;
    default:
      return textos.erroGenerico;
  }
}
