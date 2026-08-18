// Testa o Toast de feedback nao-bloqueante (lib/components/Toast.dart),
// padrao definido no CLAUDE.md pro resultado de acoes de salvar/atualizar
// (ex: EditarPerfil.dart), em vez do modal bloqueante mostrarErroCustom.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/Toast.dart';

void main() {
  // O toast usa um Timer de auto-fechamento que so e cancelado quando ele
  // mesmo fecha (por toque ou pelo tempo passar) — como OverlayEntry nao e
  // descartado automaticamente junto com o resto da arvore de widgets, todo
  // teste precisa deixar o toast terminar o ciclo antes de acabar, senao o
  // framework de teste acusa um Timer pendente.
  Future<void> deixarToastFechar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('toast de sucesso mostra a mensagem informada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarToast(context, mensagem: 'Perfil salvo com sucesso!'),
              child: const Text('salvar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('salvar'));
    await tester.pump();

    expect(find.text('Perfil salvo com sucesso!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);

    await deixarToastFechar(tester);
  });

  testWidgets('toast de erro usa o icone de erro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarToast(context, mensagem: 'Não foi possível salvar.', erro: true),
              child: const Text('salvar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('salvar'));
    await tester.pump();

    expect(find.text('Não foi possível salvar.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await deixarToastFechar(tester);
  });

  testWidgets('toast some sozinho depois de alguns segundos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarToast(context, mensagem: 'Some sozinho'),
              child: const Text('salvar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('salvar'));
    await tester.pump();
    expect(find.text('Some sozinho'), findsOneWidget);

    // Passa do tempo de auto-fechamento (3s) + a animacao de saida.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Some sozinho'), findsNothing);
  });

  testWidgets('tocar no toast fecha ele antes do tempo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarToast(context, mensagem: 'Toque pra fechar'),
              child: const Text('salvar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('salvar'));
    await tester.pump();
    expect(find.text('Toque pra fechar'), findsOneWidget);

    // Espera a animacao de entrada terminar antes de tocar: com o toast
    // ainda deslizando pra dentro da tela, a posicao real dele na tela nao
    // bate com onde o finder tentaria tocar.
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Toque pra fechar'));
    await tester.pumpAndSettle();

    expect(find.text('Toque pra fechar'), findsNothing);
  });
}
