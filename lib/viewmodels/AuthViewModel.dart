import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../data/models/UserModel.dart';
import '../data/repositories/AuthRepository.dart';
import '../utils/AuthErrorTranslator.dart';

class AuthViewModel {
  final AuthRepository _repository;
  AuthViewModel(this._repository);

  bool get usuarioLogado => _repository.usuarioAtual != null;
  String? get uidAtual => _repository.usuarioAtual?.uid;

  Stream<UserModel?> streamUsuarioAtual() {
    final uid = _repository.usuarioAtual?.uid;
    if (uid == null) return Stream.value(null);
    return _repository.streamUsuario(uid);
  }

  Future<void> logout() => _repository.logout();

  /// Retorna null em caso de sucesso (ou cancelamento pelo usuario),
  /// ou uma mensagem de erro traduzida.
  Future<String?> loginComGoogle() async {
    try {
      await _repository.loginComGoogle();
      return null;
    } catch (e) {
      return mapearErroLoginGoogle(e);
    }
  }

  /// Retorna null em caso de sucesso (ou cancelamento pelo usuario),
  /// ou uma mensagem de erro traduzida.
  Future<String?> loginComApple() async {
    try {
      await _repository.loginComApple();
      return null;
    } catch (e) {
      return mapearErroLoginApple(e);
    }
  }

  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  Future<String?> excluirConta({required String senha}) async {
    try {
      await _repository.excluirConta(senha: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
    }
  }

  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  Future<String?> cadastrar({
    required String nickname,
    required String email,
    required String senha,
  }) async {
    try {
      await _repository.cadastrar(nickname: nickname, email: email, senha: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
    }
  }

  /// Aceita email ou nickname no campo de login.
  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  Future<String?> login({required String loginOuEmail, required String senha}) async {
    try {
      await _repository.login(loginOuEmail: loginOuEmail, senha: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
    }
  }
}

/// Traduz qualquer erro lancado pelo fluxo de login com Google para uma
/// mensagem de usuario, ou null se foi apenas um cancelamento.
///
/// Extraida como funcao (testavel sem depender do Firebase/plugins nativos)
/// porque antes so tratavamos [GoogleSignInException] e [FirebaseAuthException]:
/// qualquer outra excecao (ex.: PlatformException de uma falha de Play
/// Services/Credential Manager no Android) subia sem ser capturada e o
/// loading ficava preso pra sempre, dando a impressao de "nao acontece nada"
/// ao selecionar a conta.
String? mapearErroLoginGoogle(Object erro) {
  if (erro is GoogleSignInException) {
    if (erro.code == GoogleSignInExceptionCode.canceled) return null;
    return 'Não foi possível entrar com o Google. Tente novamente.';
  }
  if (erro is FirebaseAuthException) {
    // Usuario fechou o popup ou abriu outro antes de terminar: nao e erro,
    // e o mesmo fluxo de "cancelou" do GoogleSignInException acima.
    if (erro.code == 'popup-closed-by-user' || erro.code == 'cancelled-popup-request') return null;
    return traduzirErroDeAuth(erro.code);
  }
  return 'Não foi possível entrar com o Google. Tente novamente.';
}

/// Mesma ideia de [mapearErroLoginGoogle], mas pro fluxo de Sign in with Apple.
String? mapearErroLoginApple(Object erro) {
  if (erro is SignInWithAppleAuthorizationException) {
    if (erro.code == AuthorizationErrorCode.canceled) return null;
    return 'Não foi possível entrar com a Apple. Tente novamente.';
  }
  if (erro is FirebaseAuthException) {
    return traduzirErroDeAuth(erro.code);
  }
  return 'Não foi possível entrar com a Apple. Tente novamente.';
}
