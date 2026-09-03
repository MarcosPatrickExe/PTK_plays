import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/view/CriarConta.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';

/// Só o suficiente pra montar a tela: o cadastro em si (Firebase Auth +
/// Firestore) não roda neste ambiente, então o que os testes cobrem aqui é
/// a navegação entre etapas e o bloqueio do "Avançar".
class FakeAuthViewModel implements AuthViewModel {
  final List<Map<String, String>> cadastros = [];

  @override
  Future<String?> cadastrar({
    required String nickname,
    required String email,
    required String senha,
    String telefoneWhatsapp = '',
    String avatarPreset = '',
  }) async {
    cadastros.add({
      'nickname': nickname,
      'email': email,
      'telefoneWhatsapp': telefoneWhatsapp,
      'avatarPreset': avatarPreset,
    });
    return null;
  }

  @override
  Future<({String? erro, String? url})> atualizarFotoPerfil({required Uint8List bytes}) async =>
      (erro: null, url: 'https://exemplo/foto.jpg');

  @override
  Stream<UserModel?> streamUsuarioAtual() => Stream.value(null);

  @override
  Stream<UserModel?> streamUsuarioReativo() => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeYoutubeViewModel implements YoutubeViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _tela({bool contaSocial = false}) {
  return MaterialApp(
    home: CriarConta(
      viewmodelYT: FakeYoutubeViewModel(),
      apiKey: 'chave-de-teste',
      authViewModel: FakeAuthViewModel(),
      contaSocial: contaSocial,
    ),
  );
}

/// A troca de etapa é animada; um pump com duração cobre a transição
/// inteira sem depender de pumpAndSettle (o fundo do PTK usa AnimatedSwitcher).
Future<void> _tocarEmAvancar(WidgetTester tester) async {
  await tester.tap(find.text('Avançar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('etapasDoCadastro', () {
    test('cadastro manual passa por e-mail e senha', () {
      expect(etapasDoCadastro(contaSocial: false), [
        EtapaCadastro.boasVindas,
        EtapaCadastro.nickname,
        EtapaCadastro.email,
        EtapaCadastro.senha,
        EtapaCadastro.foto,
        EtapaCadastro.whatsapp,
      ]);
    });

    test('conta social pula e-mail e senha, que o provedor já resolveu', () {
      final etapas = etapasDoCadastro(contaSocial: true);

      expect(etapas, isNot(contains(EtapaCadastro.email)));
      expect(etapas, isNot(contains(EtapaCadastro.senha)));
      expect(etapas, contains(EtapaCadastro.nickname));
      expect(etapas, contains(EtapaCadastro.foto));
      expect(etapas, contains(EtapaCadastro.whatsapp));
    });
  });

  group('assetDaEtapa', () {
    test('cada etapa com arte definida aponta pro arquivo dela', () {
      expect(assetDaEtapa(EtapaCadastro.nickname), 'assets/ptk/ptk_nickname.jpg');
      expect(assetDaEtapa(EtapaCadastro.email), 'assets/ptk/ptk_email.jpg');
      expect(assetDaEtapa(EtapaCadastro.senha), 'assets/ptk/ptk_senha.jpg');
    });

    test('etapa sem arte ainda não quebra — cai no gradiente do app', () {
      expect(assetDaEtapa(EtapaCadastro.boasVindas), isNull);
      expect(assetDaEtapa(EtapaCadastro.foto), isNull);
      expect(assetDaEtapa(EtapaCadastro.whatsapp), isNull);
    });
  });

  group('CriarConta', () {
    testWidgets('abre nas boas-vindas, que não pedem nada pra avançar', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();

      expect(find.textContaining('comunidade PTK Plays'), findsOneWidget);
      expect(find.text('Avançar'), findsOneWidget);
      // Primeira etapa: o botão da esquerda sai do cadastro em vez de voltar.
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('avançar leva ao nick, e ali o botão trava enquanto o campo está vazio', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();

      await _tocarEmAvancar(tester);
      expect(find.text('Como a gente te chama?'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);

      // Nick vazio: tocar em avançar não sai do lugar.
      await _tocarEmAvancar(tester);
      expect(find.text('Como a gente te chama?'), findsOneWidget);
    });

    testWidgets('nick curto avisa embaixo do campo enquanto a pessoa digita', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();
      await _tocarEmAvancar(tester);

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();

      expect(find.textContaining('pelo menos'), findsOneWidget);

      // Completando o nick, o aviso some e o avanço libera.
      await tester.enterText(find.byType(TextField), 'PTKzin');
      await tester.pump();
      expect(find.textContaining('pelo menos'), findsNothing);

      await _tocarEmAvancar(tester);
      expect(find.text('Qual é o seu e-mail?'), findsOneWidget);
    });

    testWidgets('e-mails que não coincidem travam a etapa', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();

      await _tocarEmAvancar(tester);
      await tester.enterText(find.byType(TextField), 'PTKzin');
      await tester.pump();
      await _tocarEmAvancar(tester);

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'fulano@teste.com');
      await tester.enterText(campos.at(1), 'outro@teste.com');
      await tester.pump();

      expect(find.text('Os e-mails não coincidem.'), findsOneWidget);

      await _tocarEmAvancar(tester);
      expect(find.text('Qual é o seu e-mail?'), findsOneWidget);

      // Corrigindo a confirmação, a etapa libera.
      await tester.enterText(campos.at(1), 'fulano@teste.com');
      await tester.pump();
      await _tocarEmAvancar(tester);
      expect(find.text('Agora crie uma senha'), findsOneWidget);
    });

    testWidgets('voltar desfaz a etapa sem perder o que já foi digitado', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();

      await _tocarEmAvancar(tester);
      await tester.enterText(find.byType(TextField), 'PTKzin');
      await tester.pump();
      await _tocarEmAvancar(tester);
      expect(find.text('Qual é o seu e-mail?'), findsOneWidget);

      await tester.tap(find.text('Voltar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Como a gente te chama?'), findsOneWidget);
      expect(find.text('PTKzin'), findsOneWidget);
    });

    testWidgets('conta social vai do nick direto pra foto', (tester) async {
      await tester.pumpWidget(_tela(contaSocial: true));
      await tester.pump();

      await _tocarEmAvancar(tester);
      await tester.enterText(find.byType(TextField), 'PTKzin');
      await tester.pump();
      await _tocarEmAvancar(tester);

      expect(find.text('Sua foto de perfil'), findsOneWidget);
    });
  });
}
