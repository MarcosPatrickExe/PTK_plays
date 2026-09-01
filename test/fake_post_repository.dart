import 'dart:typed_data';

import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/repositories/PostRepository.dart';

/// Substitui o Firestore: guarda o que teria sido gravado, pra o teste
/// conferir o que o formulário manda (tipo, cargo do autor, opções).
class FakePostRepository implements PostRepository {
  final List<Map<String, dynamic>> publicados = [];
  final List<String> apagados = [];
  final List<Map<String, dynamic>> enviados = [];

  /// Avisos de live no formato antigo que a limpeza do Painel ADM deve
  /// encontrar.
  List<PostModel> antigos = const [];

  @override
  Stream<List<PostModel>> streamPostagens() => Stream.value(const []);

  @override
  Future<void> votar({required String postId, required int indiceOpcao, required String uid}) async {}

  @override
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
  }) async {
    publicados.add({
      'tipo': tipo,
      'autorUid': autorUid,
      'autorCargo': autorCargo,
      'texto': texto,
      'titulo': titulo,
      'opcoes': opcoes,
      'fotoUrl': fotoUrl,
      'videoUrl': videoUrl,
    });
  }

  @override
  Future<void> excluirPost(String postId) async => apagados.add(postId);

  @override
  Future<String> enviarMidiaDePost({
    required String uid,
    required Uint8List bytes,
    required String contentType,
    required String extensao,
  }) async {
    enviados.add({'uid': uid, 'bytes': bytes.length, 'contentType': contentType, 'extensao': extensao});
    return 'https://exemplo/$uid/${enviados.length}.$extensao';
  }

  @override
  Future<List<PostModel>> buscarAvisosDeLiveFormatoAntigo() async => antigos;

  @override
  Future<void> excluirPosts(List<String> postIds) async => apagados.addAll(postIds);
}
