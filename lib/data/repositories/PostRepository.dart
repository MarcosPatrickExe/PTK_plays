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
        .map((snapshot) => PostModel.ordenarParaFeed(
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc.id, doc.data())).toList(),
            ));
  }

  /// Publica um aviso de texto ou uma enquete no feed. Quem pode publicar o
  /// que e a prioridade que o post recebe sao decididos pelo
  /// `firestore.rules` (regra de create em /posts) - os valores mandados
  /// aqui precisam bater com o que a regra espera, senao a escrita e
  /// recusada com permission-denied.
  Future<void> criarPost({
    required String tipo,
    required String autorUid,
    required String autorNickname,
    required String autorCargo,
    String? texto,
    String? titulo,
    List<String>? opcoes,
  }) {
    return _firestore.collection('posts').add({
      'tipo': tipo,
      'autorUid': autorUid,
      'autorNickname': autorNickname,
      'autorCargo': autorCargo,
      'prioridade': PostModel.prioridadeDoCargo(autorCargo),
      // A regra exige criadoEm == request.time: a data vem do servidor, o
      // relogio do aparelho nao decide a posicao do post no feed.
      'criadoEm': FieldValue.serverTimestamp(),
      'curtidas': 0,
      'comentariosCount': 0,
      if (texto != null) 'texto': texto,
      if (titulo != null) 'titulo': titulo,
      if (opcoes != null) 'opcoes': opcoes.map((o) => {'texto': o, 'votos': 0}).toList(),
      if (opcoes != null) 'votantes': <String>[],
      if (opcoes != null) 'votosPorUsuario': <String, int>{},
    });
  }

  /// Apaga um post. As regras so deixam passar se quem chamou for o admin
  /// ou o proprio autor do post.
  Future<void> excluirPost(String postId) {
    return _firestore.collection('posts').doc(postId).delete();
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

      final votosPorUsuario = Map<String, dynamic>.from(dados['votosPorUsuario'] ?? {});
      votosPorUsuario[uid] = indiceOpcao;

      transacao.update(ref, {'opcoes': opcoes, 'votantes': votantes, 'votosPorUsuario': votosPorUsuario});
    });
  }
}
