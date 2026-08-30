import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/PostModel.dart';

PostModel _post({
  required String id,
  required int prioridade,
  required DateTime criadoEm,
}) {
  return PostModel(
    id: id,
    tipo: PostModel.tipoAvisoTexto,
    autorUid: 'uid-$id',
    autorNickname: id,
    criadoEm: criadoEm,
    prioridade: prioridade,
  );
}

void main() {
  group('prioridade por cargo', () {
    test('só o admin ganha destaque', () {
      expect(PostModel.prioridadeDoCargo('admin'), PostModel.prioridadeDestaque);
      expect(PostModel.prioridadeDoCargo('vip'), PostModel.prioridadeComum);
      expect(PostModel.prioridadeDoCargo('inscrito'), PostModel.prioridadeComum);
    });

    test('aviso de live e post legado (sem autorCargo) contam como destaque', () {
      // Avisos de live vêm das Cloud Functions; posts sem autorCargo são os
      // criados no Console antes de o painel existir. Os dois são do canal.
      expect(PostModel.prioridadePadrao(tipo: PostModel.tipoAoVivo), PostModel.prioridadeDestaque);
      expect(PostModel.prioridadePadrao(tipo: PostModel.tipoAvisoTexto), PostModel.prioridadeDestaque);
      expect(
        PostModel.prioridadePadrao(tipo: PostModel.tipoAvisoTexto, autorCargo: 'inscrito'),
        PostModel.prioridadeComum,
      );
    });
  });

  group('PostModel.ordenarParaFeed', () {
    test('post de admin fica acima do post mais novo de um inscrito', () {
      final ordenados = PostModel.ordenarParaFeed([
        _post(id: 'inscrito-agora', prioridade: 0, criadoEm: DateTime(2026, 8, 30, 12)),
        _post(id: 'admin-ontem', prioridade: 100, criadoEm: DateTime(2026, 8, 29, 12)),
      ]);

      expect(ordenados.map((p) => p.id), ['admin-ontem', 'inscrito-agora']);
    });

    test('dentro da mesma prioridade, vale o mais recente', () {
      final ordenados = PostModel.ordenarParaFeed([
        _post(id: 'velho', prioridade: 0, criadoEm: DateTime(2026, 8, 28)),
        _post(id: 'novo', prioridade: 0, criadoEm: DateTime(2026, 8, 30)),
        _post(id: 'meio', prioridade: 0, criadoEm: DateTime(2026, 8, 29)),
      ]);

      expect(ordenados.map((p) => p.id), ['novo', 'meio', 'velho']);
    });

    test('não mexe na lista recebida', () {
      final original = [
        _post(id: 'a', prioridade: 0, criadoEm: DateTime(2026, 8, 28)),
        _post(id: 'b', prioridade: 100, criadoEm: DateTime(2026, 8, 27)),
      ];
      PostModel.ordenarParaFeed(original);

      expect(original.map((p) => p.id), ['a', 'b']);
    });
  });

  group('PostModel.fromFirestore', () {
    test('lê autorCargo e prioridade gravados', () {
      final post = PostModel.fromFirestore('p1', {
        'tipo': PostModel.tipoAvisoTexto,
        'autorUid': 'uid-1',
        'autorNickname': 'PTKzin',
        'autorCargo': 'admin',
        'prioridade': 100,
        'criadoEm': Timestamp.fromDate(DateTime(2026, 8, 30)),
        'texto': 'Live hoje!',
      });

      expect(post.autorCargo, 'admin');
      expect(post.prioridade, PostModel.prioridadeDestaque);
    });

    test('post antigo, sem os campos novos, continua no topo do feed', () {
      final post = PostModel.fromFirestore('p2', {
        'tipo': PostModel.tipoAvisoTexto,
        'autorUid': 'sistema',
        'autorNickname': 'PTK Plays',
        'texto': 'Aviso criado no Console',
      });

      expect(post.autorCargo, 'inscrito');
      expect(post.prioridade, PostModel.prioridadeDestaque);
    });

    test('post de inscrito fica com prioridade comum', () {
      final post = PostModel.fromFirestore('p3', {
        'tipo': PostModel.tipoAvisoTexto,
        'autorUid': 'uid-9',
        'autorNickname': 'Fulano',
        'autorCargo': 'inscrito',
        'texto': 'Oi galera',
      });

      expect(post.prioridade, PostModel.prioridadeComum);
    });
  });
}
