import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/BloqueioDaConta.dart';
import 'package:ptk_plays/i18n/Idioma.dart';
import 'package:ptk_plays/view/ContaBloqueada.dart';

/// O aviso de conta banida/suspensa deixou de ser uma TELA desenhada por
/// cima do app (com a pessoa ainda logada por baixo) e virou um **modal na
/// tela de login**, depois da expulsão. Estes testes acompanham a troca: o
/// que era `ContaBloqueadaView` agora é `mostrarModalContaBloqueada`.
void main() {
  tearDown(() => IdiomaApp.definir(Idioma.ptBR));

  group('o modal de conta bloqueada', () {
    Future<void> abrir(WidgetTester tester, BloqueioDaConta bloqueio) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarModalContaBloqueada(context, bloqueio),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('banimento diz que a conta não entra mais, e cita as regras', (tester) async {
      await abrir(tester, const BloqueioDaConta(banido: true));

      expect(find.text('Sua conta foi banida'), findsOneWidget);
      expect(find.textContaining('violar as regras de uso'), findsOneWidget);
      // Sem data: banimento não tem prazo, e insinuar um seria mentir.
      expect(find.textContaining('a partir de'), findsNothing);
    });

    testWidgets('suspensão diz até quando', (tester) async {
      await abrir(
        tester,
        BloqueioDaConta(banido: false, ate: DateTime(2026, 9, 20, 14, 30)),
      );

      expect(find.text('Sua conta está suspensa'), findsOneWidget);
      expect(find.textContaining('20/09/2026'), findsOneWidget);
    });

    testWidgets('mostra o motivo quando o admin escreveu um', (tester) async {
      await abrir(tester, const BloqueioDaConta(banido: true, motivo: 'spam no feed'));

      expect(find.textContaining('spam no feed'), findsOneWidget);
    });

    testWidgets('sem motivo, não sobra um "Motivo:" vazio na tela', (tester) async {
      await abrir(tester, const BloqueioDaConta(banido: true));

      expect(find.textContaining('Motivo:'), findsNothing);
    });

    testWidgets('em inglês, o aviso inteiro troca de língua', (tester) async {
      // É o ponto que o usuário fez questão de registrar: um app que expulsa
      // alguém tem que conseguir explicar por quê na língua dela.
      IdiomaApp.definir(Idioma.enUS);
      await abrir(tester, const BloqueioDaConta(banido: true));

      expect(find.text('Your account was banned'), findsOneWidget);
      expect(find.textContaining('rules of use'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('a data da suspensão inverte dia/mês em inglês', (tester) async {
      IdiomaApp.definir(Idioma.enUS);
      await abrir(tester, BloqueioDaConta(banido: false, ate: DateTime(2026, 9, 20, 14, 30)));

      expect(find.textContaining('09/20/2026'), findsOneWidget);
    });

    testWidgets('não fecha ao tocar fora — a pessoa tem que ler', (tester) async {
      await abrir(tester, const BloqueioDaConta(banido: true));

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Sua conta foi banida'), findsOneWidget);
    });

    testWidgets('fecha no botão', (tester) async {
      await abrir(tester, const BloqueioDaConta(banido: true));

      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(find.text('Sua conta foi banida'), findsNothing);
    });
  });

}
