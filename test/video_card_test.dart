import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/VideoCard.dart';
import 'package:ptk_plays/data/models/VideoNotification.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

const _video = VideoNotification(
  videoID: 'abc123',
  videoTitle: 'Noite de Aventuras em Elden Ring',
  channelTittle: 'PTK_Joga',
  publishedAt: '2026-09-01T20:00:00Z',
  thumbnailUrl: 'https://i.ytimg.com/vi/abc123/hqdefault.jpg',
  avatarUrl: 'https://exemplo/avatar.jpg',
);

/// O card é quadrado (miniatura 1:1) mais a faixa de texto: numa largura
/// cheia ele não caberia na altura da tela de teste. Numa largura de
/// celular, dentro de uma lista rolável, é como ele vive de verdade.
Widget _tela({required bool isDark}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: ListView(children: [VideoCard(notification: _video, isDark: isDark, onTap: () {})]),
        ),
      ),
    ),
  );
}

/// O fundo do card é o Container mais externo do VideoCard.
Color? _corDoFundo(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(VideoCard), matching: find.byType(Container)).first,
  );
  return (container.decoration as BoxDecoration?)?.color;
}

void main() {
  group('VideoCard', () {
    testWidgets('no escuro o card tem fundo próprio, pra miniatura não parecer solta', (tester) async {
      await tester.pumpWidget(_tela(isDark: true));
      await tester.pump();

      expect(_corDoFundo(tester), AuthTheme.cardVideoBgDark);
      // Mais opaco que o vidro padrão dos outros cards: era esse o problema.
      expect(AuthTheme.cardVideoBgDark.a, greaterThan(AuthTheme.cardBgDark.a));
    });

    testWidgets('no claro segue o mesmo fundo dos outros cards', (tester) async {
      await tester.pumpWidget(_tela(isDark: false));
      await tester.pump();

      expect(_corDoFundo(tester), AuthTheme.cardBgLight);
    });
  });
}
