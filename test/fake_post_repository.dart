import 'dart:typed_data';

import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
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

  /// O que o stream do feed devolve. Vazio por padrão; os testes que
  /// precisam de posts na tela preenchem antes de montar o widget.
  List<PostModel> postagensDoStream = const [];

  /// Curtidas registradas, em ordem: (postId, uid, curtiu ou descurtiu).
  final List<({String postId, String uid, bool curtir})> curtidas = [];

  /// O que `perfisDeQuemCurtiu` devolve. Vazio por padrão — os testes que
  /// exercitam as miniaturas preenchem antes de montar o widget.
  List<UserModel> perfisParaMiniaturas = const [];

  @override
  Future<void> curtirPost({required String postId, required String uid, required bool curtir}) async {
    curtidas.add((postId: postId, uid: uid, curtir: curtir));
  }

  @override
  Future<List<UserModel>> perfisDeQuemCurtiu(List<String> uids, {int limite = 3}) async =>
      perfisParaMiniaturas.take(limite).toList();

  @override
  Stream<List<PostModel>> streamPostagens() => Stream.value(postagensDoStream);

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
