import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/NovoPost.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';

import 'fake_post_repository.dart';

UserModel _usuario({required String cargo}) => UserModel(
      uid: 'uid-1',
      nickname: 'PTKzin',
      email: 'ptk@exemplo.com',
      fotoUrl: '',
      cargo: cargo,
      categorias: const [],
      status: 'online',
      criadoEm: DateTime(2026, 7, 5),
      ultimoAcesso: null,
      badges: const [],
      contadores: const {},
    );

/// Monta uma tela com um botão que abre o formulário, já que
/// `mostrarNovoPost` precisa de um contexto com Navigator e ThemeController.
Widget _telaComBotao({required UserModel autor, required PostViewModel vm}) {
  return ChangeNotifierProvider(
    create: (_) => ThemeController(),
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => mostrarNovoPost(context, autor: autor, postViewModel: vm),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late FakePostRepository repo;
  late PostViewModel vm;

  setUp(() {
    repo = FakePostRepository();
    vm = PostViewModel(repo);
  });

  Future<void> abrirFormulario(WidgetTester tester, UserModel autor) async {
    await tester.pumpWidget(_telaComBotao(autor: autor, vm: vm));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('inscrito só vê o campo de aviso — enquete é só do admin', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'inscrito'));

    expect(find.text('Nova publicação'), findsOneWidget);
    expect(find.text('Enquete'), findsNothing);
    expect(find.text('Aviso'), findsNothing);
  });

  testWidgets('admin escolhe entre aviso e enquete', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'admin'));

    expect(find.text('Aviso'), findsOneWidget);
    expect(find.text('Enquete'), findsOneWidget);

    await tester.tap(find.text('Enquete'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar opção'), findsOneWidget);
  });

  testWidgets('aviso vazio não publica nada', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'inscrito'));

    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(repo.publicados, isEmpty);
  });

  testWidgets('aviso preenchido é publicado com o cargo real do autor', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'inscrito'));

    await tester.enterText(find.byType(TextField).first, '  Bora de Elden Ring hoje!  ');
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(repo.publicados, hasLength(1));
    expect(repo.publicados.single['tipo'], PostModel.tipoAvisoTexto);
    expect(repo.publicados.single['autorCargo'], 'inscrito');
    expect(repo.publicados.single['texto'], 'Bora de Elden Ring hoje!');
    // O formulário fecha sozinho depois de publicar.
    expect(find.text('Nova publicação'), findsNothing);
  });

  testWidgets('inscrito não vê botão de anexar foto nem vídeo', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'inscrito'));

    expect(find.text('Foto'), findsNothing);
    expect(find.text('Vídeo'), findsNothing);
  });

  testWidgets('admin vê os botões de anexar foto e vídeo no aviso', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'admin'));

    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('Vídeo'), findsOneWidget);

    // Anexo é coisa de aviso: na enquete os botões saem de cena.
    await tester.tap(find.text('Enquete'));
    await tester.pumpAndSettle();

    expect(find.text('Foto'), findsNothing);
    expect(find.text('Vídeo'), findsNothing);
  });

  testWidgets('enquete do admin manda pergunta e opções preenchidas', (tester) async {
    await abrirFormulario(tester, _usuario(cargo: 'admin'));

    await tester.tap(find.text('Enquete'));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Qual jogo na sexta?');
    await tester.enterText(campos.at(1), 'Elden Ring');
    await tester.enterText(campos.at(2), 'Silksong');
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(repo.publicados, hasLength(1));
    expect(repo.publicados.single['tipo'], PostModel.tipoEnquete);
    expect(repo.publicados.single['titulo'], 'Qual jogo na sexta?');
    expect(repo.publicados.single['opcoes'], ['Elden Ring', 'Silksong']);
  });
}
