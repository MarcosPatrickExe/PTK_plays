import 'dart:typed_data' show Uint8List;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../data/models/AvatarPreset.dart';
import '../data/models/UserModel.dart';
import '../data/repositories/AuthRepository.dart';
import '../utils/AuthErrorTranslator.dart';

class AuthViewModel {
  final AuthRepository _repository;
  AuthViewModel(this._repository);

  bool get usuarioLogado => _repository.usuarioAtual != null;
  String? get uidAtual => _repository.usuarioAtual?.uid;

  /// Nome que veio do provedor social, usado pra sugerir o nick no cadastro
  /// de quem entrou pelo Google/Apple — melhor que abrir o campo em branco.
  String? get nomeDoProvedor => _repository.usuarioAtual?.displayName;

  /// Se a conta logada tem senha (email/senha), em vez de so login social
  /// (Google/Apple) — usado pra so mostrar a secao de trocar senha em
  /// EditarPerfil quando o usuario realmente tem uma senha pra trocar.
  bool get temSenhaEmail =>
      _repository.usuarioAtual?.providerData.any((p) => p.providerId == 'password') ?? false;

  Stream<UserModel?> streamUsuarioAtual() {
    final uid = _repository.usuarioAtual?.uid;
    if (uid == null) return Stream.value(null);
    return _repository.streamUsuario(uid);
  }

  /// Ver [AuthRepository.streamUsuarioReativo]. Usado pelo `ContaGate`, que
  /// precisa perceber login/logout em si, nao so mudanca em quem ja estava
  /// logado quando o stream foi criado.
  Stream<UserModel?> streamUsuarioReativo() => _repository.streamUsuarioReativo();

  Future<void> logout() => _repository.logout();

  /// [erro] vem null em caso de sucesso (ou de cancelamento pelo usuario),
  /// ou com a mensagem traduzida. [contaNova] diz se a conta acabou de ser
  /// criada — nesse caso o Login manda a pessoa completar o cadastro (nick,
  /// foto e WhatsApp) em vez de ir direto pro feed.
  Future<({String? erro, bool contaNova})> loginComGoogle() async {
    try {
      final contaNova = await _repository.loginComGoogle();
      return (erro: null, contaNova: contaNova);
    } catch (e, stack) {
      debugPrint('loginComGoogle falhou: $e\n$stack');
      return (erro: mapearErroLoginGoogle(e), contaNova: false);
    }
  }

  /// Ver [loginComGoogle] sobre o retorno.
  Future<({String? erro, bool contaNova})> loginComApple() async {
    try {
      final contaNova = await _repository.loginComApple();
      return (erro: null, contaNova: contaNova);
    } catch (e, stack) {
      debugPrint('loginComApple falhou: $e\n$stack');
      return (erro: mapearErroLoginApple(e), contaNova: false);
    }
  }

  /// Atualiza nickname e telefone de WhatsApp do usuario logado.
  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  ///
  /// Nao ha teste de ponta a ponta pra esse metodo (assim como cadastrar/
  /// login/excluirConta): ele depende do Firebase Auth/Firestore reais, que
  /// nao estao disponiveis neste ambiente de desenvolvimento. A validacao do
  /// nickname/telefone em si (ValidacaoCadastro.validarNickname e
  /// validarTelefoneWhatsapp) e
  /// testada isoladamente.
  Future<String?> atualizarPerfil({
    required String nicknameAtual,
    required String novoNickname,
    required String telefoneWhatsapp,
    required String avatarPreset,
  }) async {
    final uid = uidAtual;
    final email = _repository.usuarioAtual?.email;
    if (uid == null || email == null) return 'Você precisa estar logado.';

    try {
      await _repository.atualizarPerfil(
        uid: uid,
        nicknameAtual: nicknameAtual,
        novoNickname: novoNickname,
        email: email,
        telefoneWhatsapp: telefoneWhatsapp,
        avatarPreset: avatarPreset,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
    }
  }

  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  Future<String?> enviarEmailRedefinicaoSenha({required String email}) async {
    try {
      await _repository.enviarEmailRedefinicaoSenha(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
    }
  }

  /// Envia uma nova foto de perfil (bytes ja recortados por ModalCropFoto)
  /// pro Firebase Storage e atualiza o perfil. Retorna a URL em caso de
  /// sucesso, ou uma mensagem de erro traduzida.
  Future<({String? erro, String? url})> atualizarFotoPerfil({required Uint8List bytes}) async {
    final uid = uidAtual;
    if (uid == null) return (erro: 'Você precisa estar logado.', url: null);

    try {
      final url = await _repository.atualizarFotoPerfil(uid: uid, bytes: bytes);
      return (erro: null, url: url);
    } catch (e, stack) {
      debugPrint('atualizarFotoPerfil falhou: $e\n$stack');
      if (e is FirebaseException) return (erro: traduzirErroDeAuth(e.code), url: null);
      return (erro: 'Não foi possível enviar a foto. Tente novamente.', url: null);
    }
  }

  /// Retorna null em caso de sucesso, ou uma mensagem de erro traduzida.
  /// So chamar quando [temSenhaEmail] for true.
  Future<String?> alterarSenha({required String senhaAtual, required String novaSenha}) async {
    try {
      await _repository.alterarSenha(senhaAtual: senhaAtual, novaSenha: novaSenha);
      return null;
    } on FirebaseAuthException catch (e) {
      return traduzirErroDeAuth(e.code);
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
    String telefoneWhatsapp = '',
    String avatarPreset = '',
  }) async {
    try {
      await _repository.cadastrar(
        nickname: nickname,
        email: email,
        senha: senha,
        telefoneWhatsapp: telefoneWhatsapp,
        avatarPreset: avatarPreset,
      );
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

/// Valida o numero de WhatsApp opcional informado no cadastro, ja formatado
/// pela mascara "+55 (DD) NNNNN-NNNN" (ver MascaraTelefoneWhatsapp).
/// Retorna null se for valido (inclusive vazio/so a mascara, ja que o campo
/// e opcional), ou uma mensagem de erro se o DDD+numero estiver incompleto.
String? validarTelefoneWhatsapp(String telefone) {
  final todosDigitos = telefone.replaceAll(RegExp(r'[^0-9]'), '');
  // Os 2 primeiros digitos sao sempre o "55" fixo do prefixo do pais da
  // mascara, nao contam como informados pelo usuario.
  final digitos = todosDigitos.length > 2 ? todosDigitos.substring(2) : '';
  if (digitos.isEmpty) return null;
  if (digitos.length < 10 || digitos.length > 11) {
    return 'Número de WhatsApp incompleto. Preencha o DDD e o número, ou deixe em branco.';
  }
  return null;
}

/// Valida os 3 campos opcionais de troca de senha na edicao de perfil.
/// Deixar todos vazios (usuario nao quer trocar de senha) e valido. Se
/// qualquer um for preenchido, todos precisam estar corretos. Retorna null
/// se valido, ou uma mensagem de erro.
String? validarTrocaSenha({
  required String senhaAtual,
  required String novaSenha,
  required String confirmarNovaSenha,
}) {
  final algumPreenchido = senhaAtual.isNotEmpty || novaSenha.isNotEmpty || confirmarNovaSenha.isNotEmpty;
  if (!algumPreenchido) return null;

  if (senhaAtual.isEmpty) return 'Informe sua senha atual pra trocar de senha.';
  if (novaSenha.length < 6) return 'A nova senha precisa ter pelo menos 6 caracteres.';
  if (novaSenha != confirmarNovaSenha) return 'As senhas não coincidem.';
  return null;
}

/// Valida a escolha de avatar pre-definido no cadastro (obrigatoria: o
/// usuario precisa escolher um dos 6 personas). Retorna null se valido, ou
/// uma mensagem de erro.
String? validarAvatarPreset(String? chave) {
  if (chave == null || chave.isEmpty) return 'Escolha uma foto de perfil.';
  if (!avatarPresetValido(chave)) return 'Foto de perfil inválida.';
  return null;
}

/// Mesma ideia de [mapearErroLoginGoogle], mas pro fluxo de Sign in with Apple.
String? mapearErroLoginApple(Object erro) {
  if (erro is SignInWithAppleAuthorizationException) {
    if (erro.code == AuthorizationErrorCode.canceled) return null;
    // O sistema operacional retorna "unknown" (ASAuthorizationError 1000)
    // sempre que a autorizacao falha antes de chegar a um motivo especifico
    // (invalidResponse/notHandled/failed/etc.) — na pratica, isso acontece
    // quase sempre porque o dispositivo/simulador nao esta logado numa conta
    // Apple (iCloud) com autenticacao de dois fatores, o que o Sign in with
    // Apple exige no nivel do sistema. E o caso tipico de simuladores/nuvens
    // de teste (ex: Sauce Labs) sem Apple ID configurado — nao e algo que o
    // app consiga contornar em codigo.
    if (erro.code == AuthorizationErrorCode.unknown) {
      return 'Não foi possível entrar com a Apple. Verifique se este dispositivo está conectado a uma conta Apple (iCloud) com autenticação de dois fatores — dispositivos de teste/simuladores sem conta Apple configurada não conseguem usar esse login.';
    }
    return 'Não foi possível entrar com a Apple. Tente novamente.';
  }
  if (erro is FirebaseAuthException) {
    return traduzirErroDeAuth(erro.code);
  }
  return 'Não foi possível entrar com a Apple. Tente novamente.';
}
