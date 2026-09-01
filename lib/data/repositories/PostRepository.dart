import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/PostModel.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<PostModel>> streamPostagens() {
    return _firestore
        .collection('posts')
        .orderBy('criadoEm', descending: true)
        // Maior que a primeira pagina do feed de proposito: o que passa de
        // PostModel.postsPorPagina e justamente o que vai aparecendo
        // conforme o usuario rola (ver PostModel.paginarParaFeed).
        .limit(60)
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
    String? fotoUrl,
    String? videoUrl,
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
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
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

  /// Envia uma foto ou um video de post pro Storage e devolve a URL
  /// publica. O caminho e por uid porque e assim que o `storage.rules`
  /// consegue amarrar a escrita a quem esta logado — quem pode de fato
  /// PUBLICAR essa midia e o `firestore.rules` que decide (so admin).
  Future<String> enviarMidiaDePost({
    required String uid,
    required Uint8List bytes,
    required String contentType,
    required String extensao,
  }) async {
    final nome = '${DateTime.now().millisecondsSinceEpoch}.$extensao';
    final ref = _storage.ref('posts_midia/$uid/$nome');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Todos os avisos de live no formato antigo (ver
  /// [PostModel.formatoAntigo]), pra acao de limpeza do Painel ADM.
  ///
  /// A consulta filtra so por `tipo`, um campo so — filtro de campo unico
  /// nao precisa de indice composto no Console. O resto do recorte e feito
  /// aqui, na memoria.
  Future<List<PostModel>> buscarAvisosDeLiveFormatoAntigo() async {
    final snapshot = await _firestore
        .collection('posts')
        .where('tipo', isEqualTo: PostModel.tipoAoVivo)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
        .where((post) => post.formatoAntigo)
        .toList();
  }

  /// Apaga varios posts de uma vez. Um lote do Firestore aceita ate 500
  /// operacoes, entao a lista e quebrada nesse tamanho.
  Future<void> excluirPosts(List<String> postIds) async {
    const tamanhoDoLote = 500;

    for (var inicio = 0; inicio < postIds.length; inicio += tamanhoDoLote) {
      final fim = (inicio + tamanhoDoLote).clamp(0, postIds.length);
      final lote = _firestore.batch();
      for (final id in postIds.sublist(inicio, fim)) {
        lote.delete(_firestore.collection('posts').doc(id));
      }
      await lote.commit();
    }
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
