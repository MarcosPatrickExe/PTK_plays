// Testa o modelo de gamificacao (lib/data/models/Conquista.dart) usado pela
// tela de Conquistas: progresso de cada badge baseada em contador, e o
// rotulo de exibicao de uma badge salva.

import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/Conquista.dart';
import 'package:ptk_plays/data/models/UserModel.dart';

UserModel _usuarioCom({List<String> badges = const [], Map<String, int> contadores = const {}}) {
  return UserModel(
    uid: 'u1',
    nickname: 'Fulano',
    email: 'fulano@teste.com',
    fotoUrl: '',
    cargo: 'inscrito',
    categorias: const [],
    status: 'online',
    criadoEm: DateTime(2026, 1, 1),
    ultimoAcesso: null,
    badges: badges,
    contadores: contadores,
  );
}

void main() {
  group('progressoDaConquista', () {
    final comentarista = catalogoConquistas.firstWhere((c) => c.chave == 'comentarista');

    test('sem nenhum contador registrado, progresso e zero', () {
      final usuario = _usuarioCom();
      expect(progressoDaConquista(usuario, comentarista), 0.0);
    });

    test('progresso parcial e proporcional ao contador sobre a meta', () {
      final usuario = _usuarioCom(contadores: {'comentarios': 5});
      expect(progressoDaConquista(usuario, comentarista), 0.5);
    });

    test('contador igual a meta da progresso completo (1.0)', () {
      final usuario = _usuarioCom(contadores: {'comentarios': 10});
      expect(progressoDaConquista(usuario, comentarista), 1.0);
    });

    test('contador acima da meta fica limitado a 1.0 (nao passa de 100%)', () {
      final usuario = _usuarioCom(contadores: {'comentarios': 999});
      expect(progressoDaConquista(usuario, comentarista), 1.0);
    });

    test('conquista sem contador (novato) e 1.0 se ja esta em badges, senao 0.0', () {
      const novato = Conquista(chave: 'novato', titulo: 'Novato', descricao: 'x');
      expect(progressoDaConquista(_usuarioCom(badges: const ['novato']), novato), 1.0);
      expect(progressoDaConquista(_usuarioCom(), novato), 0.0);
    });
  });

  group('labelConquista', () {
    test('retorna o titulo cadastrado no catalogo', () {
      expect(labelConquista('novato'), 'Novato');
    });

    test('cai de volta pra chave crua se a badge nao estiver no catalogo', () {
      expect(labelConquista('badge-futura-desconhecida'), 'badge-futura-desconhecida');
    });
  });
}
