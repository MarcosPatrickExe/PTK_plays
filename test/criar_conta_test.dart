import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/components/FundoPTK.dart';
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

Widget _tela({bool contaSocial = false, String? nicknameSugerido}) {
  return MaterialApp(
    home: CriarConta(
      viewmodelYT: FakeYoutubeViewModel(),
      apiKey: 'chave-de-teste',
      authViewModel: FakeAuthViewModel(),
      contaSocial: contaSocial,
      nicknameSugerido: nicknameSugerido,
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
      expect(assetDaEtapa(EtapaCadastro.nickname), 'assets/ptk/ptk_nickname.webp');
      expect(assetDaEtapa(EtapaCadastro.email), 'assets/ptk/ptk_email.webp');
      expect(assetDaEtapa(EtapaCadastro.senha), 'assets/ptk/ptk_senha.webp');
      expect(assetDaEtapa(EtapaCadastro.foto), 'assets/ptk/ptk_foto.webp');
      expect(assetDaEtapa(EtapaCadastro.whatsapp), 'assets/ptk/ptk_whatsapp.webp');
    });

    test('boas-vindas ainda não tem arte, e isso não quebra a tela', () {
      expect(assetDaEtapa(EtapaCadastro.boasVindas), isNull);
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
      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);

      // Nick vazio: tocar em avançar não sai do lugar.
      await _tocarEmAvancar(tester);
      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
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
      expect(find.text('Agora crie\numa senha'), findsOneWidget);
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

      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(find.text('PTKzin'), findsOneWidget);
    });

    testWidgets('nick vem preenchido com o nome da conta Google/Apple', (tester) async {
      await tester.pumpWidget(_tela(contaSocial: true, nicknameSugerido: 'Marcos Patrick'));
      await tester.pump();
      await _tocarEmAvancar(tester);

      expect(find.text('Marcos Patrick'), findsOneWidget);
      // Já vindo válido, a etapa libera sem a pessoa digitar nada.
      await _tocarEmAvancar(tester);
      expect(find.text('Sua foto de perfil'), findsOneWidget);
    });

    testWidgets('o subtítulo some quando o teclado abre, mas o título fica', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();
      await _tocarEmAvancar(tester);

      const subtitulo = 'Esse é o nick que vai aparecer nos seus posts e comentários dentro do app.';
      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(find.text(subtitulo), findsOneWidget);

      // O teclado aparece como viewInsets no rodapé.
      final view = tester.view;
      view.viewInsets = const FakeViewPadding(bottom: 600);
      addTearDown(view.resetViewInsets);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // O título continua: é ele que diz o que está sendo preenchido.
      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(find.text(subtitulo), findsNothing);
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

    testWidgets('a etapa de boas-vindas centraliza o texto na faixa branca', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();

      final rolagem = tester.getRect(find.byType(SingleChildScrollView).first);
      final titulo = tester.getRect(find.textContaining('Bem-vindo'));
      final subtitulo = tester.getRect(find.textContaining('Avisos de live'));

      // Sem campos pra preencher, o texto é tudo que existe na parte branca:
      // fica no meio dela em vez de encostado na onda com um vazio embaixo.
      final centroDoTexto = (titulo.top + subtitulo.bottom) / 2;
      expect((centroDoTexto - rolagem.center.dy).abs(), lessThan(rolagem.height * .12));
      expect(titulo.top, greaterThan(rolagem.top + rolagem.height * .15));
    });

    testWidgets('as etapas com campos mantêm o texto no alto, logo abaixo da onda', (tester) async {
      await tester.pumpWidget(_tela());
      await tester.pump();
      await _tocarEmAvancar(tester);

      final rolagem = tester.getRect(find.byType(SingleChildScrollView).first);
      final titulo = tester.getRect(find.text('Como a gente\nte chama?'));

      // Aqui centralizar empurraria o título pra cima do campo — o texto
      // continua ancorado no topo da faixa branca.
      expect(titulo.top, lessThan(rolagem.top + rolagem.height * .15));
    });

    testWidgets('com o cume à esquerda o título quebra a linha e o subtítulo vem inteiro', (tester) async {
      // A etapa do nick é a segunda, e a onda dela sobe à esquerda.
      expect(ondaDaEtapa(1).cumeEhAEsquerda, isTrue);

      await tester.pumpWidget(_tela());
      await tester.pump();
      await _tocarEmAvancar(tester);

      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(
        find.text('Esse é o nick que vai aparecer nos seus posts e comentários dentro do app.'),
        findsOneWidget,
      );
    });

    testWidgets('com o cume à direita o título fica em uma linha só e o subtítulo é o resumido', (tester) async {
      // A etapa do e-mail é a terceira, e a onda dela sobe à direita: sobra
      // menos altura à esquerda, onde o texto fica.
      expect(ondaDaEtapa(2).cumeEhAEsquerda, isFalse);

      await tester.pumpWidget(_tela());
      await tester.pump();
      await _tocarEmAvancar(tester);
      await tester.enterText(find.byType(TextField), 'PTKzin');
      await tester.pump();
      await _tocarEmAvancar(tester);

      expect(find.text('Qual é o seu e-mail?'), findsOneWidget);
      expect(find.text('Serve pra entrar e recuperar a senha.'), findsOneWidget);
      expect(
        find.text('É por ele que você entra na conta e recupera a senha se esquecer.'),
        findsNothing,
      );

      // Fonte menor, pra tudo caber na faixa mais baixa que sobra.
      final titulo = tester.widget<Text>(find.text('Qual é o seu e-mail?'));
      expect(titulo.style!.fontSize, lessThan(26));
    });
  });

  group('CriarConta no desktop', () {
    // Abaixo de larguraDoCadastroDesktop é o layout de celular (onda); a
    // largura da viewport de teste decide qual dos dois entra em cena —
    // não tem toggle explícito, é a mesma leitura de largura que a tela
    // real faz.
    Future<void> comLargura(WidgetTester tester, double largura, double altura) async {
      tester.view.physicalSize = Size(largura, altura);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('largura abaixo do ponto de corte continua com a onda', (tester) async {
      await comLargura(tester, 800, 900);
      await tester.pumpWidget(_tela());
      await tester.pump();

      // "PASSO 1 DE 6" só existe no cartão desktop — no celular quem marca
      // o progresso são as bolinhas sobre a arte.
      expect(find.textContaining('PASSO'), findsNothing);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('largura no ponto de corte mostra o cartão de duas colunas', (tester) async {
      await comLargura(tester, larguraDoCadastroDesktop, 800);
      await tester.pumpWidget(_tela());
      await tester.pump();

      expect(find.text('PASSO 1 DE 6'), findsOneWidget);
      // O título flui numa linha só — sem a quebra pensada pro celular
      // estreito, que aqui deixaria uma segunda linha capenga sobrando de
      // espaço à toa.
      expect(find.text('Bem-vindo(a) à comunidade PTK Plays!'), findsOneWidget);
    });

    testWidgets('avançar no desktop atualiza o selo e o título, sem PageView', (tester) async {
      await comLargura(tester, 1200, 800);
      await tester.pumpWidget(_tela());
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.text('PASSO 1 DE 6'), findsOneWidget);

      await _tocarEmAvancar(tester);

      expect(find.text('PASSO 2 DE 6'), findsOneWidget);
      // Flui numa linha, igual ao título das boas-vindas — sem a quebra
      // que só faz sentido na coluna estreita do celular.
      expect(find.text('Como a gente te chama?'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);

      // Subtítulo sempre por inteiro — sobra altura de sobra num cartão,
      // ao contrário da faixa branca que a onda deixa no celular.
      expect(
        find.text('Esse é o nick que vai aparecer nos seus posts e comentários dentro do app.'),
        findsOneWidget,
      );
    });

    testWidgets('preenche o nick e cria a conta pelo cartão desktop', (tester) async {
      await comLargura(tester, 1200, 800);
      await tester.pumpWidget(_tela(contaSocial: true));
      await tester.pump();

      await _tocarEmAvancar(tester);
      await tester.enterText(find.byType(TextField), 'PTKzin');
      await tester.pump();
      await _tocarEmAvancar(tester);

      // Conta social pula e-mail/senha: nick -> foto direto, igual ao
      // celular — o desktop reaproveita a mesma lista de etapas.
      expect(find.text('Sua foto de perfil'), findsOneWidget);
    });

    testWidgets('estreitar a janela depois de avançar no desktop reabre o celular na etapa certa', (tester) async {
      await comLargura(tester, 1200, 800);
      await tester.pumpWidget(_tela());
      await tester.pump();

      await _tocarEmAvancar(tester); // -> nick, indice 1

      // A janela encolhe pra largura de celular: o PageView remonta do
      // zero. Sem a sincronização em _buildMobile, ele reabriria travado
      // na primeira página mesmo com `_indice` já em 1.
      await comLargura(tester, 390, 844);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(find.textContaining('Bem-vindo'), findsNothing);
    });
  });

  // O iPad Air 11" (M3) e o aparelho em que a Apple reprovou o app duas
  // vezes (ver CHECKPOINT.md, atencao 4). Ele tem 1180x820 pontos — ou
  // seja, ele cai dos DOIS lados do ponto de corte de 900, dependendo de
  // como a pessoa esta segurando o aparelho. Ninguem nunca olhou isso: o
  // cartao de duas colunas foi desenhado pra janela de navegador, e a
  // possibilidade de ele aparecer num tablet so foi percebida em 12/set,
  // conferindo as medidas do aparelho do revisor.
  group('CriarConta no iPad Air 11" (aparelho da reprovação)', () {
    Future<void> comLargura(WidgetTester tester, double largura, double altura) async {
      tester.view.physicalSize = Size(largura, altura);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('em paisagem (1180x820) entra o cartão de duas colunas', (tester) async {
      await comLargura(tester, 1180, 820);
      await tester.pumpWidget(_tela());
      await tester.pump();

      expect(find.text('PASSO 1 DE 6'), findsOneWidget);
    });

    testWidgets('em retrato (820x1180) entra o layout de celular, com a onda', (tester) async {
      await comLargura(tester, 820, 1180);
      await tester.pumpWidget(_tela());
      await tester.pump();

      expect(find.textContaining('PASSO'), findsNothing);
      expect(find.textContaining('Bem-vindo'), findsOneWidget);
    });

    testWidgets('girar o iPad no meio do cadastro preserva a etapa', (tester) async {
      // O caso real: a pessoa comeca em paisagem, avanca, e gira o aparelho.
      // E a mesma troca de layout que o teste de estreitar a janela cobre,
      // mas aqui ela acontece por rotacao — sem o usuario ter feito nada
      // parecido com "redimensionar". Se a sincronizacao do PageController
      // falhasse, girar o iPad jogaria a pessoa de volta pra tela de
      // boas-vindas no meio do cadastro.
      await comLargura(tester, 1180, 820);
      await tester.pumpWidget(_tela());
      await tester.pump();

      await _tocarEmAvancar(tester); // -> nick

      await comLargura(tester, 820, 1180);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Como a gente\nte chama?'), findsOneWidget);
      expect(find.textContaining('Bem-vindo'), findsNothing);
    });
  });
}
