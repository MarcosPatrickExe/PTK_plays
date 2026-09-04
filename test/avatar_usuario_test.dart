import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/AvatarUsuario.dart';
import 'package:ptk_plays/data/models/AvatarPreset.dart';
import 'package:ptk_plays/data/models/UserModel.dart';

UserModel _usuario({String avatarPreset = '', String fotoUrl = ''}) => UserModel(
      uid: 'u1',
      nickname: 'Fulano',
      email: 'fulano@teste.com',
      fotoUrl: fotoUrl,
      cargo: 'inscrito',
      categorias: const [],
      status: 'online',
      criadoEm: DateTime(2026, 1, 1),
      ultimoAcesso: null,
      badges: const [],
      contadores: const {},
      avatarPreset: avatarPreset,
    );

Widget _tela(UserModel usuario) => MaterialApp(
      home: Scaffold(body: Center(child: AvatarUsuario(usuario: usuario))),
    );

void main() {
  group('AvatarUsuario', () {
    testWidgets('preset escolhido tem prioridade sobre a foto', (tester) async {
      await tester.pumpWidget(_tela(_usuario(avatarPreset: 'otaku', fotoUrl: 'https://exemplo/foto.jpg')));

      final imagem = tester.widget<Image>(find.byType(Image));
      expect((imagem.image as AssetImage).assetName, assetDoAvatarPreset('otaku'));
      expect(find.byType(FotoPerfilRede), findsNothing);
    });

    testWidgets('sem preset, usa a foto da conta (login social ou upload)', (tester) async {
      await tester.pumpWidget(_tela(_usuario(fotoUrl: 'https://lh3.googleusercontent.com/foto')));
      await tester.pump();

      expect(find.byType(FotoPerfilRede), findsOneWidget);
    });

    testWidgets('sem preset e sem foto, cai no avatar padrao', (tester) async {
      await tester.pumpWidget(_tela(_usuario()));

      final imagem = tester.widget<Image>(find.byType(Image));
      expect((imagem.image as AssetImage).assetName, assetDoAvatarPreset(avatarPresetPadrao));
    });
  });

  group('FotoPerfilRede', () {
    testWidgets('carrega por <img> na Web quando o download de bytes falha', (tester) async {
      // A foto do login com Google (lh3.googleusercontent.com) sumia por
      // depender do caminho XHR+decode, que exige CORS — mesma causa das
      // miniaturas de vídeo. O fallback é o que faz o avatar aparecer.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FotoPerfilRede(url: 'https://lh3.googleusercontent.com/foto'))),
      );

      final imagem = tester.widget<Image>(find.byType(Image));
      expect((imagem.image as NetworkImage).webHtmlElementStrategy, WebHtmlElementStrategy.fallback);
    });
  });
}
