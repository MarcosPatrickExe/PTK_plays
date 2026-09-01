import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';

import 'fake_post_repository.dart';

UserModel _admin() => UserModel(
      uid: 'uid-admin',
      nickname: 'PTKzin',
      email: 'ptk@exemplo.com',
      fotoUrl: '',
      cargo: 'admin',
      categorias: const [],
      status: 'online',
      criadoEm: DateTime(2026, 7, 5),
      ultimoAcesso: null,
      badges: const [],
      contadores: const {},
    );

PostModel _liveVazia(String id) => PostModel(
      id: id,
      tipo: PostModel.tipoAoVivo,
      autorUid: 'sistema',
      autorNickname: 'PTK Plays',
      criadoEm: DateTime(2026, 7, 20),
    );

void main() {
  late FakePostRepository repo;
  late PostViewModel vm;

  setUp(() {
    repo = FakePostRepository();
    vm = PostViewModel(repo);
  });

  group('publicarMidia', () {
    test('grava o tipo avisoMidia com as duas URLs', () async {
      final erro = await vm.publicarMidia(
        texto: '  Setup novo  ',
        autor: _admin(),
        fotoUrl: 'https://exemplo/foto.jpg',
        videoUrl: 'https://exemplo/clipe.mp4',
      );

      expect(erro, isNull);
      expect(repo.publicados.single['tipo'], PostModel.tipoAvisoMidia);
      expect(repo.publicados.single['texto'], 'Setup novo');
      expect(repo.publicados.single['fotoUrl'], 'https://exemplo/foto.jpg');
      expect(repo.publicados.single['videoUrl'], 'https://exemplo/clipe.mp4');
    });

    test('post só de mídia vai sem texto, em vez de string vazia', () async {
      await vm.publicarMidia(texto: '   ', autor: _admin(), fotoUrl: 'https://exemplo/foto.jpg');

      expect(repo.publicados.single['texto'], isNull);
    });
  });

  group('enviarMidia', () {
    test('devolve a URL do arquivo enviado', () async {
      final resultado = await vm.enviarMidia(
        uid: 'uid-admin',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
        extensao: 'jpg',
      );

      expect(resultado.erro, isNull);
      expect(resultado.url, isNotNull);
      expect(repo.enviados.single['contentType'], 'image/jpeg');
      expect(repo.enviados.single['uid'], 'uid-admin');
    });
  });

  group('limparAvisosDeLiveAntigos', () {
    test('apaga todos os avisos de live no formato antigo', () async {
      repo.antigos = [_liveVazia('v1'), _liveVazia('v2')];

      final resultado = await vm.limparAvisosDeLiveAntigos();

      expect(resultado.erro, isNull);
      expect(resultado.apagados, 2);
      expect(repo.apagados, ['v1', 'v2']);
    });

    test('sem nada pra limpar, não apaga nada e não dá erro', () async {
      final resultado = await vm.limparAvisosDeLiveAntigos();

      expect(resultado.erro, isNull);
      expect(resultado.apagados, 0);
      expect(repo.apagados, isEmpty);
    });
  });
}
