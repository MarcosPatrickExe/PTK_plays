import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/UserModel.dart';
import '../data/repositories/AuthRepository.dart';
import '../utils/AuthErrorTranslator.dart';

class AuthViewModel {
  final AuthRepository _repository;
  AuthViewModel(this._repository);

  bool get usuarioLogado => _repository.usuarioAtual != null;

  Stream<UserModel?> streamUsuarioAtual() {
    final uid = _repository.usuarioAtual?.uid;
    if (uid == null) return Stream.value(null);
    return _repository.streamUsuario(uid);
  }

  Future<void> logout() => _repository.logout();

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

  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  Future<String?> login({required String email, required String senha}) async {
    try {
      await _repository.login(email: email, senha: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
    }
  }
}
