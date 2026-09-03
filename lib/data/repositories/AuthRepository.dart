import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data' show Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/UserModel.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // "Web client" gerado automaticamente pelo Firebase ao ativar o Google
  // Sign-In (google-services.json / GoogleService-Info.plist). Nao e segredo,
  // e o identificador publico usado pra validar o idToken em qualquer plataforma.
  static const _webClientId = '696548413882-caba685okm8d002hvvq60k32ceim56bc.apps.googleusercontent.com';
  static const _iosClientId = '696548413882-0f1s66gkjohih26in5roq2jf1r4na18b.apps.googleusercontent.com';

  bool _googleSignInInicializado = false;

  User? get usuarioAtual => _auth.currentUser;

  Future<void> cadastrar({
    required String nickname,
    required String email,
    required String senha,
    String telefoneWhatsapp = '',
    String avatarPreset = '',
  }) async {
    final nicknameChave = nickname.trim().toLowerCase();

    final mapeamentoExistente = await _firestore.collection('nicknamesParaEmail').doc(nicknameChave).get();
    if (mapeamentoExistente.exists) {
      throw FirebaseAuthException(code: 'nickname-em-uso', message: 'Esse nickname já está em uso.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    await credential.user!.updateDisplayName(nickname);

    final novoUsuario = UserModel.novoInscrito(
      uid: uid,
      nickname: nickname,
      email: email,
      telefoneWhatsapp: telefoneWhatsapp,
      avatarPreset: avatarPreset,
    );
    await _firestore.collection('users').doc(uid).set(novoUsuario.toFirestore());

    await _firestore.collection('nicknamesParaEmail').doc(nicknameChave).set({
      'uid': uid,
      'email': email,
    });
  }

  /// Atualiza nickname e/ou telefone de WhatsApp do usuario logado.
  /// Se o nickname mudou, remapeia nicknamesParaEmail (usado pelo login por
  /// nickname) pra continuar resolvendo pro email correto.
  Future<void> atualizarPerfil({
    required String uid,
    required String nicknameAtual,
    required String novoNickname,
    required String email,
    required String telefoneWhatsapp,
    required String avatarPreset,
  }) async {
    final chaveAtual = nicknameAtual.trim().toLowerCase();
    final novaChave = novoNickname.trim().toLowerCase();

    if (novaChave != chaveAtual) {
      final mapeamentoExistente = await _firestore.collection('nicknamesParaEmail').doc(novaChave).get();
      if (mapeamentoExistente.exists) {
        throw FirebaseAuthException(code: 'nickname-em-uso', message: 'Esse nickname já está em uso.');
      }

      await _firestore.collection('nicknamesParaEmail').doc(chaveAtual).delete();
      await _firestore.collection('nicknamesParaEmail').doc(novaChave).set({'uid': uid, 'email': email});
      await _auth.currentUser?.updateDisplayName(novoNickname);
    }

    // ultimoAcesso precisa ser tocado em toda escrita: a regra de seguranca
    // do Firestore exige request.resource.data.ultimoAcesso == request.time
    // em qualquer update (ver firestore.rules), senao a escrita e recusada.
    await _firestore.collection('users').doc(uid).set(
      {
        'nickname': novoNickname,
        'telefoneWhatsapp': telefoneWhatsapp,
        'avatarPreset': avatarPreset,
        ...UserModel.touchUltimoAcesso(),
      },
      SetOptions(merge: true),
    );
  }

  /// Aceita tanto email quanto nickname no campo de login: se tiver "@",
  /// trata como email direto; senao, resolve o email pelo mapeamento
  /// nicknamesParaEmail antes de autenticar.
  Future<String> _resolverEmailParaLogin(String loginOuEmail) async {
    final valor = loginOuEmail.trim();
    if (valor.contains('@')) return valor;

    final doc = await _firestore.collection('nicknamesParaEmail').doc(valor.toLowerCase()).get();
    if (!doc.exists) {
      throw FirebaseAuthException(code: 'user-not-found', message: 'Usuário não encontrado.');
    }

    return doc.data()!['email'] as String;
  }

  Future<void> login({required String loginOuEmail, required String senha}) async {
    final email = await _resolverEmailParaLogin(loginOuEmail);
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set(
      UserModel.touchUltimoAcesso(),
      SetOptions(merge: true),
    );
  }

  Future<void> _garantirGoogleSignInInicializado() async {
    if (_googleSignInInicializado) return;

    await GoogleSignIn.instance.initialize(
      clientId: (!kIsWeb && Platform.isIOS) ? _iosClientId : null,
      serverClientId: kIsWeb ? null : _webClientId,
    );

    _googleSignInInicializado = true;
  }

  Future<void> loginComGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _garantirGoogleSignInInicializado();
      final conta = await GoogleSignIn.instance.authenticate();
      final idToken = conta.authentication.idToken;

      credential = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    }

    await _sincronizarUsuarioNoFirestore(credential.user!);
  }

  /// Fluxo exigido pela Apple (guideline 4.8) como alternativa equivalente
  /// ao Google Sign-In. So funciona em iOS/macOS: nao ha configuracao de
  /// Service ID/return URL feita pro fluxo web do pacote em Android/Web.
  Future<void> loginComApple() async {
    final rawNonce = _gerarNonce();
    final nonce = _sha256DoNonce(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);
    final user = credential.user!;

    // A Apple so retorna nome na primeira autorizacao; usa aqui pra
    // preencher o profile do Firebase Auth caso ainda esteja vazio.
    if (user.displayName == null || user.displayName!.isEmpty) {
      final nomeCompleto = [appleCredential.givenName, appleCredential.familyName]
          .where((parte) => parte != null && parte.isNotEmpty)
          .join(' ');
      if (nomeCompleto.isNotEmpty) await user.updateDisplayName(nomeCompleto);
    }

    await _sincronizarUsuarioNoFirestore(user, nicknameSugerido: appleCredential.givenName);
  }

  Future<void> _sincronizarUsuarioNoFirestore(User user, {String? nicknameSugerido}) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      final novoUsuario = UserModel.novoInscrito(
        uid: user.uid,
        nickname: user.displayName ?? nicknameSugerido ?? user.email?.split('@').first ?? 'Jogador',
        email: user.email ?? '',
        fotoUrl: user.photoURL ?? '',
      );
      await _firestore.collection('users').doc(user.uid).set(novoUsuario.toFirestore());
    } else {
      // Conta que ja existia: so toca o ultimoAcesso, MENOS quando ela esta
      // sem foto nenhuma e o provedor social traz uma. E o caso de quem se
      // cadastrou por email/senha e so depois entrou pelo Google/Apple — o
      // avatar do provedor nunca chegava ao Firestore porque este ramo so
      // era escrito com o ultimoAcesso. Foto propria ja enviada e preset
      // escolhido continuam intocados: a condicao exige os dois vazios.
      final dados = doc.data() ?? {};
      final semFotoPropria = (dados['fotoUrl'] as String? ?? '').isEmpty;
      final semPreset = (dados['avatarPreset'] as String? ?? '').isEmpty;
      final fotoDoProvedor = user.photoURL ?? '';

      await _firestore.collection('users').doc(user.uid).set(
        {
          if (semFotoPropria && semPreset && fotoDoProvedor.isNotEmpty) 'fotoUrl': fotoDoProvedor,
          ...UserModel.touchUltimoAcesso(),
        },
        SetOptions(merge: true),
      );
    }
  }

  /// String aleatoria criptograficamente segura usada como nonce anti-replay
  /// no fluxo OpenID Connect da Apple.
  String _gerarNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256DoNonce(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Stream<UserModel?> streamUsuario(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? UserModel.fromFirestore(doc.data()!) : null,
    );
  }

  /// Como [streamUsuario], mas acompanha login/logout em si — troca de
  /// assinatura sozinho quando o uid muda, em vez de ficar preso ao uid
  /// que estava logado no instante em que o stream foi criado (que e como
  /// [streamUsuario] se comporta quando chamado uma vez soh).
  ///
  /// Existe pro `ContaGate` (`lib/components/ContaGate.dart`), o unico
  /// lugar que precisa disso: ele envolve o app inteiro e nunca e
  /// desmontado por uma troca de tela, entao nao pode depender de ser
  /// recriado a cada login pra saber de quem e a vez de ouvir.
  Stream<UserModel?> streamUsuarioReativo() {
    final controlador = StreamController<UserModel?>.broadcast();
    StreamSubscription<UserModel?>? assinaturaDoDocumento;

    final assinaturaDoAuth = _auth.authStateChanges().listen((user) {
      assinaturaDoDocumento?.cancel();
      if (user == null) {
        controlador.add(null);
        return;
      }
      assinaturaDoDocumento = streamUsuario(user.uid).listen(controlador.add, onError: controlador.addError);
    });

    controlador.onCancel = () {
      assinaturaDoDocumento?.cancel();
      assinaturaDoAuth.cancel();
    };

    return controlador.stream;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Envia o email de redefinicao de senha do Firebase Auth (link que leva
  /// a uma pagina hospedada pelo proprio Firebase pra escolher uma senha
  /// nova, sem precisar saber a senha atual). Uso: usuario logado que
  /// esqueceu a senha atual em EditarPerfil, ou (futuramente) a tela de
  /// login pra quem nao consegue entrar.
  Future<void> enviarEmailRedefinicaoSenha({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> excluirConta({required String senha}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(email: user.email!, password: senha);
    await user.reauthenticateWithCredential(credential);

    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  /// Envia os bytes (ja recortados/redimensionados por ModalCropFoto) pro
  /// Firebase Storage e grava a fotoUrl resultante no perfil, limpando o
  /// avatarPreset — a foto enviada passa a ser o avatar ativo, ja que
  /// chavePresetParaExibir da prioridade ao preset sobre fotoUrl quando os
  /// dois estao preenchidos.
  Future<String> atualizarFotoPerfil({required String uid, required Uint8List bytes}) async {
    final ref = _storage.ref('fotos_perfil/$uid/foto.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).set(
      {'fotoUrl': url, 'avatarPreset': '', ...UserModel.touchUltimoAcesso()},
      SetOptions(merge: true),
    );

    return url;
  }

  /// So funciona pra contas com provider de email/senha (ver
  /// AuthViewModel.temSenhaEmail) — Firebase exige reautenticacao recente
  /// pra operacoes sensiveis como troca de senha.
  Future<void> alterarSenha({required String senhaAtual, required String novaSenha}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(email: user.email!, password: senhaAtual);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(novaSenha);
  }
}
