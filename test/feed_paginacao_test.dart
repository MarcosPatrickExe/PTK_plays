import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/view/Home.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';

import 'fake_post_repository.dart';

PostModel _aviso({required String id, required int diasAtras}) {
  return PostModel(
    id: id,
    tipo: PostModel.tipoAvisoTexto,
    autorUid: 'uid-$id',
    autorNickname: 'PTKzin',
    criadoEm: DateTime.now().subtract(Duration(days: diasAtras)),
    texto: 'aviso $id',
  );
}

Widget _tela(List<PostModel> postagens) {
  return MaterialApp(
    home: Scaffold(
      body: ListaDoFeed(
        isDark: false,
        postagens: postagens,
        ehAdmin: false,
        postViewModel: PostViewModel(FakePostRepository()),
      ),
    ),
  );
}

void main() {
  group('ListaDoFeed', () {
    // A tela padrão do teste (800x600) só constrói 3 ou 4 cards, e o que
    // não é construído também não é encontrado. Uma janela alta deixa a
    // primeira página inteira caber e a asserção medir a paginação, não o
    // tamanho do viewport.
    setUp(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
      view.physicalSize = const Size(800, 2600);
      view.devicePixelRatio = 1;
      addTearDown(() {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });
    });

    testWidgets('mostra só a primeira página e esconde os posts de mais de 30 dias', (tester) async {
      final postagens = [
        for (var i = 1; i <= 12; i++) _aviso(id: 'r$i', diasAtras: i),
        _aviso(id: 'velho', diasAtras: 45),
      ];

      await tester.pumpWidget(_tela(postagens));
      await tester.pump();

      // 10 na tela: o 11º recente e o de 45 dias ficam de fora.
      expect(find.text('aviso r1'), findsOneWidget);
      expect(find.text('aviso r10'), findsOneWidget);
      expect(find.text('aviso r11'), findsNothing);
      expect(find.text('aviso velho'), findsNothing);
    });

    testWidgets('carregar mais revela os antigos, depois dos recentes', (tester) async {
      final postagens = [
        for (var i = 1; i <= 12; i++) _aviso(id: 'r$i', diasAtras: i),
        _aviso(id: 'velho', diasAtras: 45),
      ];

      await tester.pumpWidget(_tela(postagens));
      await tester.pump();

      await tester.tap(find.text('Ver publicações mais antigas'));
      await tester.pump();

      expect(find.text('aviso r11'), findsOneWidget);
      expect(find.text('aviso r12'), findsOneWidget);
      expect(find.text('aviso velho'), findsOneWidget);
    });

    testWidgets('sem post escondido, o rodapé de "ver mais antigas" não aparece', (tester) async {
      await tester.pumpWidget(_tela([_aviso(id: 'r1', diasAtras: 1)]));
      await tester.pump();

      expect(find.text('aviso r1'), findsOneWidget);
      expect(find.text('Ver publicações mais antigas'), findsNothing);
    });
  });
}
