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
    case 'operation-not-allowed':
      return 'O login com Google não está habilitado pra esse app no momento.';
    default:
      return 'Algo deu errado. Tente novamente.';
  }
}
