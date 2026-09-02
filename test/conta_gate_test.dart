import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/components/ContaGate.dart';
import 'package:ptk_plays/data/models/UserModel.dart';

UserModel _usuario({required String estado, DateTime? suspensoAte}) => UserModel(
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
    );

Widget _tela({required UserModel? usuario, VoidCallback? onSair}) {
  return MaterialApp(
    home: GateDeConta(
      usuario: usuario,
      isDark: false,
      onSair: onSair ?? () {},
      child: const Text('conteúdo do app'),
    ),
  );
}

void main() {
  group('GateDeConta', () {
    testWidgets('sem usuario (deslogado), mostra so o conteudo', (tester) async {
      await tester.pumpWidget(_tela(usuario: null));

      expect(find.text('conteúdo do app'), findsOneWidget);
      expect(find.text('Sair'), findsNothing);
    });

    testWidgets('conta ativa mostra so o conteudo, sem cobrir com nada', (tester) async {
      await tester.pumpWidget(_tela(usuario: _usuario(estado: 'ativo')));

      expect(find.text('conteúdo do app'), findsOneWidget);
      expect(find.text('Sua conta foi banida'), findsNothing);
    });

    testWidgets('conta banida cobre com a tela de bloqueio', (tester) async {
      await tester.pumpWidget(_tela(usuario: _usuario(estado: 'banido')));

      expect(find.text('Sua conta foi banida'), findsOneWidget);
    });

    testWidgets('o conteudo continua montado por baixo do bloqueio, so coberto', (tester) async {
      // E o que garante que, se a suspensao vencer com o app aberto, a
      // pessoa volta a ver exatamente onde estava — o Stack so para de
      // desenhar a tela de bloqueio por cima, sem reconstruir nada embaixo.
      await tester.pumpWidget(_tela(usuario: _usuario(estado: 'banido')));

      expect(find.text('conteúdo do app'), findsOneWidget);
      expect(find.text('Sua conta foi banida'), findsOneWidget);
    });

    testWidgets('conta suspensa dentro do prazo tambem cobre', (tester) async {
      final futuro = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(_tela(usuario: _usuario(estado: 'suspenso', suspensoAte: futuro)));

      expect(find.text('Sua conta está suspensa'), findsOneWidget);
    });

    testWidgets('suspensao vencida nao cobre mais nada', (tester) async {
      final passado = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(_tela(usuario: _usuario(estado: 'suspenso', suspensoAte: passado)));

      expect(find.text('conteúdo do app'), findsOneWidget);
      expect(find.text('Sua conta está suspensa'), findsNothing);
    });

    testWidgets('tocar em Sair chama o callback', (tester) async {
      var chamado = false;
      await tester.pumpWidget(_tela(usuario: _usuario(estado: 'banido'), onSair: () => chamado = true));

      await tester.tap(find.text('Sair'));
      await tester.pump();

      expect(chamado, isTrue);
    });
  });
}
