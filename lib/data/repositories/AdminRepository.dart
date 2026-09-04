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

  /// Apaga a conta e **tudo** que ela produziu, em cascata: os posts do
  /// feed, a reserva do nickname e por fim o proprio documento do usuario.
  /// Devolve quantos posts sumiram junto, pra o painel poder dizer o que
  /// aconteceu.
  ///
  /// O documento do usuario e o **ultimo** a cair de proposito: as regras
  /// do Firestore leem o cargo de quem chama a partir de `users/{uid}` (ver
  /// `cargoDoUsuario()`), e apagar o documento no meio do caminho poderia
  /// derrubar a permissao do proprio admin no meio da limpeza — se ele
  /// estivesse removendo a si mesmo.
  ///
  /// **O que isso NAO faz**: apagar a conta do Firebase Auth (so o Admin
  /// SDK, numa Cloud Function, consegue) nem os arquivos do Storage (as
  /// regras de Storage nao leem o Firestore, entao nao ha como autorizar o
  /// admin la). Ver ROADMAP.md.
  Future<int> removerUsuario(String uid) async {
    final posts = await _firestore.collection('posts').where('autorUid', isEqualTo: uid).get();
    await _apagarEmLote(posts.docs.map((doc) => doc.reference));

    // A reserva do nickname e indexada pelo nickname, nao pelo uid — por
    // isso vem por consulta, e nao por caminho direto. Sem apagar, o nick
    // fica preso pra sempre a uma conta que nao existe mais.
    final nicknames = await _firestore.collection('nicknamesParaEmail').where('uid', isEqualTo: uid).get();
    await _apagarEmLote(nicknames.docs.map((doc) => doc.reference));

    // Quando existirem mensagens do grupo e conversas privadas (Etapa 3 do
    // ROADMAP), elas entram aqui, antes do documento do usuario.

    await _firestore.collection('users').doc(uid).delete();

    return posts.docs.length;
  }

  /// Um lote do Firestore aceita ate 500 operacoes.
  Future<void> _apagarEmLote(Iterable<DocumentReference> referencias) async {
    const tamanhoDoLote = 500;
    final todas = referencias.toList();

    for (var inicio = 0; inicio < todas.length; inicio += tamanhoDoLote) {
      final fim = (inicio + tamanhoDoLote).clamp(0, todas.length);
      final lote = _firestore.batch();
      for (final referencia in todas.sublist(inicio, fim)) {
        lote.delete(referencia);
      }
      await lote.commit();
    }
  }
}
