import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/UserModel.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  Future<void> cadastrar({
    required String nickname,
    required String email,
    required String senha,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    await credential.user!.updateDisplayName(nickname);

    final novoUsuario = UserModel.novoInscrito(uid: uid, nickname: nickname, email: email);
    await _firestore.collection('users').doc(uid).set(novoUsuario.toFirestore());
  }

  Future<void> login({required String email, required String senha}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set(
      UserModel.touchUltimoAcesso(),
      SetOptions(merge: true),
    );
  }
}
