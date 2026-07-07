import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/UserModel.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }) async {
    final nicknameChave = nickname.trim().toLowerCase();

    final mapeamentoExistente = await _firestore.collection('nicknamesParaEmail').doc(nicknameChave).get();
    if (mapeamentoExistente.exists) {
      throw FirebaseAuthException(code: 'nickname-em-uso', message: 'Esse nickname já está em uso.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    await credential.user!.updateDisplayName(nickname);

    final novoUsuario = UserModel.novoInscrito(uid: uid, nickname: nickname, email: email);
    await _firestore.collection('users').doc(uid).set(novoUsuario.toFirestore());

    await _firestore.collection('nicknamesParaEmail').doc(nicknameChave).set({
      'uid': uid,
      'email': email,
    });
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

    final user = credential.user!;
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      final novoUsuario = UserModel.novoInscrito(
        uid: user.uid,
        nickname: user.displayName ?? user.email?.split('@').first ?? 'Jogador',
        email: user.email ?? '',
        fotoUrl: user.photoURL ?? '',
      );
      await _firestore.collection('users').doc(user.uid).set(novoUsuario.toFirestore());
    } else {
      await _firestore.collection('users').doc(user.uid).set(
        UserModel.touchUltimoAcesso(),
        SetOptions(merge: true),
      );
    }
  }

  Stream<UserModel?> streamUsuario(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? UserModel.fromFirestore(doc.data()!) : null,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> excluirConta({required String senha}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(email: user.email!, password: senha);
    await user.reauthenticateWithCredential(credential);

    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }
}
