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
      return 'Email ou senha incorretos.';
    case 'too-many-requests':
      return 'Muitas tentativas. Tente novamente mais tarde.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    default:
      return 'Algo deu errado. Tente novamente.';
  }
}
