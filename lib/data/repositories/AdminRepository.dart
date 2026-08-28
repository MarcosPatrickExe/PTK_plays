import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/UserModel.dart';

/// Acesso à coleção `users` a partir do Painel ADM.
///
/// Todas as escritas daqui dependem de `ehAdmin()` no `firestore.rules` —
/// um usuário comum que chamasse esses métodos levaria
/// `permission-denied` do próprio Firestore, não é a UI que protege.
class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Todos os usuários do app, mais recentes primeiro. Sem paginação por
  /// enquanto: a base é pequena (dezenas de contas). Quando crescer, virar
  /// `.limit()` + carregamento incremental (anotado no ROADMAP.md).
  Stream<List<UserModel>> streamUsuarios() {
    return _firestore
        .collection('users')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc.data())).toList());
  }

  Future<void> banirUsuario(String uid, {String? motivo}) {
    return _firestore.collection('users').doc(uid).update({
      'estadoModeracao': 'banido',
      'suspensoAte': null,
      if (motivo != null && motivo.isNotEmpty) 'motivoModeracao': motivo,
    });
  }

  Future<void> suspenderUsuario(String uid, {required Duration duracao, String? motivo}) {
    return _firestore.collection('users').doc(uid).update({
      'estadoModeracao': 'suspenso',
      'suspensoAte': Timestamp.fromDate(DateTime.now().add(duracao)),
      if (motivo != null && motivo.isNotEmpty) 'motivoModeracao': motivo,
    });
  }

  Future<void> reativarUsuario(String uid) {
    return _firestore.collection('users').doc(uid).update({
      'estadoModeracao': 'ativo',
      'suspensoAte': null,
      'motivoModeracao': FieldValue.delete(),
    });
  }
}
