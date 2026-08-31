import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/ImagemRede.dart';

/// No `flutter test` nenhuma requisição de rede sai de verdade — o binding
/// devolve erro pra qualquer `Image.network`. Isso é justamente o que
/// interessa aqui: dá pra observar o comportamento de falha (tentar a
/// segunda URL, cair no placeholder) sem depender de internet.
Widget _tela(Widget filho) => MaterialApp(home: Scaffold(body: filho));

List<String> _urlsTentadas(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((i) => (i.image as NetworkImage).url)
    .toList();

void main() {
  testWidgets('quando a primeira URL falha, tenta a alternativa', (tester) async {
    await tester.pumpWidget(_tela(const ImagemRede(
      url: 'https://i.ytimg.com/vi/abc/hqdefault.jpg',
      urlAlternativa: 'https://img.youtube.com/vi/abc/hqdefault.jpg',
      isDark: false,
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(_urlsTentadas(tester), contains('https://img.youtube.com/vi/abc/hqdefault.jpg'));
  });

  testWidgets('sem alternativa, mostra o placeholder em vez de quadrado vazio', (tester) async {
    await tester.pumpWidget(_tela(const ImagemRede(
      url: 'https://kick.com/sem-imagem.jpg',
      isDark: false,
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(_urlsTentadas(tester), ['https://kick.com/sem-imagem.jpg']);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('as duas falhando, ainda assim sobra o placeholder', (tester) async {
    await tester.pumpWidget(_tela(const ImagemRede(
      url: 'https://i.ytimg.com/vi/abc/hqdefault.jpg',
      urlAlternativa: 'https://img.youtube.com/vi/abc/hqdefault.jpg',
      isDark: true,
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}
