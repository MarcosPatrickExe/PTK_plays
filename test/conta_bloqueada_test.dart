import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/view/ContaBloqueada.dart';

UserModel _usuario({required String estado, DateTime? suspensoAte, String? motivo}) => UserModel(
      uid: 'u1',
      nickname: 'Fulano',
      email: 'fulano@teste.com',
      fotoUrl: '',
      cargo: 'inscrito',
      categorias: const [],
      status: 'online',
      criadoEm: DateTime(2026, 1, 1),
      ultimoAcesso: null,
      badges: const [],
      contadores: const {},
      estadoModeracao: estado,
      suspensoAte: suspensoAte,
      motivoModeracao: motivo,
    );

Widget _tela(UserModel usuario, {VoidCallback? onSair}) {
  return MaterialApp(
    home: ContaBloqueadaView(isDark: false, usuario: usuario, onSair: onSair ?? () {}),
  );
}

void main() {
  group('ContaBloqueadaView', () {
    testWidgets('conta banida mostra a mensagem de banimento, sem data', (tester) async {
      await tester.pumpWidget(_tela(_usuario(estado: 'banido')));

      expect(find.text('Sua conta foi banida'), findsOneWidget);
      expect(find.text('Você não pode mais usar o PTK Plays.'), findsOneWidget);
    });

    testWidgets('conta suspensa mostra até quando dura', (tester) async {
      await tester.pumpWidget(_tela(_usuario(estado: 'suspenso', suspensoAte: DateTime(2026, 9, 10, 18, 30))));

      expect(find.text('Sua conta está suspensa'), findsOneWidget);
      expect(find.textContaining('10/09/2026 às 18:30'), findsOneWidget);
    });

    testWidgets('mostra o motivo quando o admin informou um', (tester) async {
      await tester.pumpWidget(_tela(_usuario(estado: 'banido', motivo: 'Xingou outro usuário')));

      expect(find.text('Motivo: Xingou outro usuário'), findsOneWidget);
    });

    testWidgets('sem motivo, não mostra a caixa de motivo', (tester) async {
      await tester.pumpWidget(_tela(_usuario(estado: 'banido')));

      expect(find.textContaining('Motivo:'), findsNothing);
    });

    testWidgets('tocar em Sair chama o callback', (tester) async {
      var chamado = false;
      await tester.pumpWidget(_tela(_usuario(estado: 'banido'), onSair: () => chamado = true));

      await tester.tap(find.text('Sair'));
      await tester.pump();

      expect(chamado, isTrue);
    });
  });
}
