import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/foundation.dart' show debugPrint;
import '../data/models/PostModel.dart';
import '../data/models/UserModel.dart';
import '../data/repositories/PostRepository.dart';
import '../utils/ValidacaoPost.dart';

class PostViewModel {
  final PostRepository _repository;
  PostViewModel(this._repository);

  Stream<List<PostModel>> streamPostagens() => _repository.streamPostagens();

  Future<void> votar({required String postId, required int indiceOpcao, required String uid}) =>
      _repository.votar(postId: postId, indiceOpcao: indiceOpcao, uid: uid);

  /// Publica um aviso de texto. A validacao do conteudo (vazio, tamanho) e
  /// feita na tela antes de chegar aqui, porque erro de formulario vai pro
  /// modal bloqueante e erro de escrita vai pro toast (regra do CLAUDE.md).
  /// Retorna null em caso de sucesso, ou a mensagem pro toast.
  Future<String?> publicarAviso({required String texto, required UserModel autor}) {
    return _publicar(() => _repository.criarPost(
          tipo: PostModel.tipoAvisoTexto,
          autorUid: autor.uid,
          autorNickname: autor.nickname,
          autorCargo: autor.cargo,
          texto: texto.trim(),
        ));
  }

  /// Enquete. So o admin consegue publicar: o `firestore.rules` recusa esse
  /// tipo pra qualquer outro cargo (a UI tambem nao oferece a opcao).
  Future<String?> publicarEnquete({
    required String pergunta,
    required List<String> opcoes,
    required UserModel autor,
  }) {
    return _publicar(() => _repository.criarPost(
          tipo: PostModel.tipoEnquete,
          autorUid: autor.uid,
          autorNickname: autor.nickname,
          autorCargo: autor.cargo,
          titulo: pergunta.trim(),
          opcoes: opcoesPreenchidas(opcoes),
        ));
  }

  /// Aviso do admin com foto e/ou video. O `firestore.rules` recusa o tipo
  /// avisoMidia pra qualquer cargo que nao seja admin, entao um inscrito nao
  /// consegue publicar imagem nem contornando a UI.
  Future<String?> publicarMidia({
    required String texto,
    required UserModel autor,
    String? fotoUrl,
    String? videoUrl,
  }) {
    return _publicar(() => _repository.criarPost(
          tipo: PostModel.tipoAvisoMidia,
          autorUid: autor.uid,
          autorNickname: autor.nickname,
          autorCargo: autor.cargo,
          texto: texto.trim().isEmpty ? null : texto.trim(),
          fotoUrl: fotoUrl,
          videoUrl: videoUrl,
        ));
  }

  /// Envia a midia pro Storage antes de publicar o post. Devolve a URL, ou
  /// a mensagem de erro pro toast quando o envio falha.
  Future<({String? url, String? erro})> enviarMidia({
    required String uid,
    required Uint8List bytes,
    required String contentType,
    required String extensao,
  }) async {
    try {
      final url = await _repository.enviarMidiaDePost(
        uid: uid,
        bytes: bytes,
        contentType: contentType,
        extensao: extensao,
      );
      return (url: url, erro: null);
    } catch (e, stack) {
      debugPrint('envio de midia falhou: $e\n$stack');
      return (url: null, erro: 'Não foi possível enviar o arquivo. Tente de novo.');
    }
  }

  Future<String?> excluirPost(String postId) {
    return _publicar(() => _repository.excluirPost(postId));
  }

  /// Apaga de vez os avisos de live no formato antigo (ver
  /// [PostModel.formatoAntigo]). Devolve quantos sumiram, ou a mensagem de
  /// erro pro toast.
  Future<({int apagados, String? erro})> limparAvisosDeLiveAntigos() async {
    try {
      final antigos = await _repository.buscarAvisosDeLiveFormatoAntigo();
      if (antigos.isEmpty) return (apagados: 0, erro: null);

      await _repository.excluirPosts(antigos.map((post) => post.id).toList());
      return (apagados: antigos.length, erro: null);
    } on FirebaseException catch (e, stack) {
      debugPrint('limpeza de posts antigos falhou: ${e.code}\n$stack');
      if (e.code == 'permission-denied') {
        return (apagados: 0, erro: 'Só o admin pode fazer essa limpeza.');
      }
      return (apagados: 0, erro: 'Não foi possível concluir. Tente de novo.');
    } catch (e, stack) {
      debugPrint('limpeza de posts antigos falhou: $e\n$stack');
      return (apagados: 0, erro: 'Não foi possível concluir. Tente de novo.');
    }
  }

  Future<String?> _publicar(Future<void> Function() escrita) async {
    try {
      await escrita();
      return null;
    } on FirebaseException catch (e, stack) {
      debugPrint('escrita no feed falhou: ${e.code}\n$stack');
      // permission-denied aqui quase sempre quer dizer que a regra nova de
      // /posts ainda nao foi publicada (firebase deploy --only
      // firestore:rules) — vale dizer isso em vez de um erro generico.
      if (e.code == 'permission-denied') {
        return 'Você não tem permissão pra isso. Se acabou de virar admin, saia e entre de novo.';
      }
      return 'Não foi possível concluir. Tente de novo.';
    } catch (e, stack) {
      debugPrint('escrita no feed falhou: $e\n$stack');
      return 'Não foi possível concluir. Tente de novo.';
    }
  }
}
