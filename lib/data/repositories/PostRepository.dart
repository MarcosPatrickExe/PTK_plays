import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/PostModel.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PostModel>> streamPostagens() {
    return _firestore
        .collection('posts')
        .orderBy('criadoEm', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Vota numa opcao de enquete. Usa transacao pra ficar seguro mesmo com
  /// votos concorrentes, e nao faz nada se o usuario ja tiver votado.
  Future<void> votar({
    required String postId,
    required int indiceOpcao,
    required String uid,
  }) async {
    final ref = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transacao) async {
      final snapshot = await transacao.get(ref);
      final dados = snapshot.data();
      if (dados == null) return;

      final votantes = List<String>.from(dados['votantes'] ?? []);
      if (votantes.contains(uid)) return;

      final opcoes = (dados['opcoes'] as List)
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();

      if (indiceOpcao < 0 || indiceOpcao >= opcoes.length) return;

      opcoes[indiceOpcao]['votos'] = (opcoes[indiceOpcao]['votos'] ?? 0) + 1;
      votantes.add(uid);

      transacao.update(ref, {'opcoes': opcoes, 'votantes': votantes});
    });
  }
}
