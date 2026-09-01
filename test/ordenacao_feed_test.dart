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

  group('PostModel.formatoAntigo', () {
    PostModel live({required String id, Map<String, PostPlataformaAoVivo> plataformas = const {}}) {
      return PostModel(
        id: id,
        tipo: PostModel.tipoAoVivo,
        autorUid: 'sistema',
        autorNickname: 'PTK Plays',
        criadoEm: DateTime(2026, 8, 1),
        plataformasAoVivo: plataformas,
      );
    }

    test('aviso de live sem plataforma nenhuma é o formato antigo', () {
      expect(live(id: 'velho').formatoAntigo, isTrue);
    });

    test('aviso de live com plataforma continua valendo', () {
      final novo = live(
        id: 'novo',
        plataformas: const {'twitch': PostPlataformaAoVivo(link: 'https://twitch.tv/ptk')},
      );
      expect(novo.formatoAntigo, isFalse);
    });

    test('post que não é de live nunca conta como formato antigo', () {
      final aviso = _post(id: 'a', prioridade: 0, criadoEm: DateTime(2026, 8, 1));
      expect(aviso.formatoAntigo, isFalse);
    });

    test('semFormatoAntigo tira só os avisos de live vazios', () {
      final lista = [
        live(id: 'velho'),
        live(id: 'novo', plataformas: const {'kick': PostPlataformaAoVivo(link: 'https://kick.com/ptk')}),
        _post(id: 'aviso', prioridade: 0, criadoEm: DateTime(2026, 8, 1)),
      ];

      expect(PostModel.semFormatoAntigo(lista).map((p) => p.id), ['novo', 'aviso']);
    });
  });

  group('PostModel.paginarParaFeed', () {
    final agora = DateTime(2026, 9, 1, 12);

    // 12 recentes (1 a 12 dias atrás) e 4 com mais de 30 dias, já na ordem
    // que ordenarParaFeed devolveria.
    List<PostModel> lista() => [
          for (var i = 1; i <= 12; i++)
            _post(id: 'r$i', prioridade: 0, criadoEm: agora.subtract(Duration(days: i))),
          for (var i = 1; i <= 4; i++)
            _post(id: 'a$i', prioridade: 0, criadoEm: agora.subtract(Duration(days: 30 + i))),
        ];

    test('a primeira página traz 10 posts e nenhum com mais de 30 dias', () {
      final visiveis = PostModel.paginarParaFeed(lista(), limite: PostModel.postsPorPagina, agora: agora);

      expect(visiveis, hasLength(10));
      expect(visiveis.every((post) => !post.ehAntigo(agora)), isTrue);
    });

    test('post antigo fica escondido mesmo quando sobra espaço na primeira página', () {
      // Só 3 recentes: ainda assim os antigos não entram pra completar 10.
      final poucos = [
        for (var i = 1; i <= 3; i++)
          _post(id: 'r$i', prioridade: 0, criadoEm: agora.subtract(Duration(days: i))),
        for (var i = 1; i <= 4; i++)
          _post(id: 'a$i', prioridade: 0, criadoEm: agora.subtract(Duration(days: 30 + i))),
      ];

      final visiveis = PostModel.paginarParaFeed(poucos, limite: PostModel.postsPorPagina, agora: agora);

      expect(visiveis.map((p) => p.id), ['r1', 'r2', 'r3']);
    });

    test('rolando além da primeira página os antigos aparecem, no fim', () {
      final visiveis = PostModel.paginarParaFeed(lista(), limite: 20, agora: agora);

      expect(visiveis, hasLength(16));
      expect(visiveis.last.id, 'a4');
      // Os recentes continuam vindo antes de qualquer antigo.
      final primeiroAntigo = visiveis.indexWhere((post) => post.ehAntigo(agora));
      expect(primeiroAntigo, 12);
    });

    test('temMaisParaMostrar indica quando ainda sobrou post escondido', () {
      expect(
        PostModel.temMaisParaMostrar(lista(), limite: PostModel.postsPorPagina, agora: agora),
        isTrue,
      );
      expect(PostModel.temMaisParaMostrar(lista(), limite: 100, agora: agora), isFalse);
    });
  });
}
