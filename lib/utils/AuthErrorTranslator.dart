String traduzirErroDeAuth(String codigo) {
  switch (codigo) {
    case 'email-already-in-use':
      return 'Esse email já está cadastrado. Tente fazer login.';
    case 'invalid-email':
      return 'Email inválido.';
    case 'weak-password':
      return 'A senha precisa ter pelo menos 6 caracteres.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Login ou senha incorretos.';
    case 'nickname-em-uso':
      return 'Esse nickname já está em uso. Escolha outro.';
    case 'too-many-requests':
      return 'Muitas tentativas. Tente novamente mais tarde.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    case 'unauthorized-domain':
      return 'Esse domínio não está autorizado a fazer login com Google. Avise o administrador do app.';
    case 'popup-blocked':
      return 'O navegador bloqueou o popup de login. Permita popups pra esse site e tente novamente.';
    // Nao citar provedor aqui: este codigo vale pros dois. O Firebase o
    // devolve pra QUALQUER provedor desabilitado no Console (Authentication
    // -> Sign-in method), e a versao anterior dizia "Google" mesmo quando
    // quem tinha falhado era a Apple — mandando quem investiga pro painel
    // errado. Foi um dos suspeitos da reprovacao de 27/ago/2026.
    case 'operation-not-allowed':
      return 'Esse jeito de entrar não está habilitado pra o app no momento. Avise o administrador.';
    default:
      return 'Algo deu errado. Tente novamente.';
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
      return 'Você não tem permissão pra fazer isso. Se você deveria ter, avise o administrador.';
    case 'unauthenticated':
      return 'Sua sessão expirou. Entre de novo pra continuar.';
    case 'unavailable':
    case 'deadline-exceeded':
    case 'retry-limit-exceeded':
      return 'Sem conexão com o servidor. Verifique a internet e tente de novo.';
    case 'not-found':
    case 'object-not-found':
      return 'O item que você tentou abrir não existe mais.';
    case 'already-exists':
      return 'Isso já existe.';
    case 'resource-exhausted':
    case 'quota-exceeded':
      return 'O limite do serviço foi atingido. Tente mais tarde.';
    case 'cancelled':
    case 'canceled':
      return 'A operação foi cancelada.';
    default:
      return 'Algo deu errado. Tente novamente.';
  }
}
