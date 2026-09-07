import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/data/models/MensagemWhatsapp.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/data/repositories/AdminRepository.dart';
import 'package:ptk_plays/data/repositories/PostRepository.dart';
import 'package:ptk_plays/data/repositories/WhatsappRepository.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/view/PainelAdmin.dart';

MensagemWhatsapp _msg({
  required String id,
  String telefone = '5511999999999',
  String nome = '',
  bool recebida = true,
  String texto = 'oi',
  String tipo = 'text',
  String status = '',
  String erro = '',
  required DateTime quando,
}) {
  return MensagemWhatsapp(
    id: id,
    telefone: telefone,
    nomeDoContato: nome,
    recebida: recebida,
    tipo: tipo,
    texto: texto,
    status: status,
    erro: erro,
    criadaEm: quando,
    atualizadaEm: quando,
  );
}

class FakeWhatsappRepository implements WhatsappRepository {
  final List<ConversaWhatsapp> conversas;
  final bool falhar;

  FakeWhatsappRepository({this.conversas = const [], this.falhar = false});

  @override
  Stream<List<ConversaWhatsapp>> streamConversas({int limite = 300}) {
    if (falhar) return Stream.error(Exception('sem permissão'));
    return Stream.value(conversas);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeAdminRepository implements AdminRepository {
  @override
  Stream<List<UserModel>> streamUsuarios() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakePostRepository implements PostRepository {
  @override
  Stream<List<PostModel>> streamPostagens() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final _admin = UserModel(
  uid: 'admin-1',
  nickname: 'PTK',
  email: 'ptk@teste.com',
  fotoUrl: '',
  cargo: 'admin',
  categorias: const [],
  status: 'online',
  criadoEm: DateTime(2026, 1, 1),
  ultimoAcesso: null,
  badges: const ['novato'],
  contadores: const {},
);

Widget _painel(FakeWhatsappRepository whatsapp) {
  return ChangeNotifierProvider<ThemeController>(
    create: (_) => ThemeController(),
    child: MaterialApp(
      home: PainelAdmin(
        admin: _admin,
        repository: FakeAdminRepository(),
        postRepository: FakePostRepository(),
        whatsappRepository: whatsapp,
      ),
    ),
  );
}

Future<void> _abrirAbaWhatsapp(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.text('WhatsApp'));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  group('agruparEmConversas', () {
    test('junta as mensagens do mesmo número numa conversa só', () {
      final conversas = agruparEmConversas([
        _msg(id: 'a', quando: DateTime(2026, 9, 5, 10, 0)),
        _msg(id: 'b', quando: DateTime(2026, 9, 5, 10, 5), recebida: false, texto: 'oi de volta'),
        _msg(id: 'c', telefone: '5511888888888', quando: DateTime(2026, 9, 5, 9, 0)),
      ]);

      expect(conversas, hasLength(2));
      expect(conversas.first.telefone, '5511999999999');
      expect(conversas.first.mensagens, hasLength(2));
    });

    test('ordena as conversas pela atividade mais recente', () {
      final conversas = agruparEmConversas([
        _msg(id: 'antiga', telefone: '111', quando: DateTime(2026, 9, 1)),
        _msg(id: 'nova', telefone: '222', quando: DateTime(2026, 9, 5)),
      ]);

      expect(conversas.map((c) => c.telefone), ['222', '111']);
    });

    test('dentro da conversa, a ordem é da mais antiga pra mais nova', () {
      final conversa = agruparEmConversas([
        _msg(id: 'depois', quando: DateTime(2026, 9, 5, 12, 0), texto: 'segunda'),
        _msg(id: 'antes', quando: DateTime(2026, 9, 5, 11, 0), texto: 'primeira'),
      ]).single;

      expect(conversa.mensagens.map((m) => m.texto), ['primeira', 'segunda']);
      expect(conversa.ultima.texto, 'segunda');
    });

    test('usa o nome de perfil mais recente que a Meta mandou', () {
      final conversa = agruparEmConversas([
        _msg(id: 'a', nome: 'Marcos', quando: DateTime(2026, 9, 1)),
        _msg(id: 'b', nome: 'Marcos Patrick', quando: DateTime(2026, 9, 5)),
        // Status de entrega não traz contato: não pode apagar o nome.
        _msg(id: 'c', recebida: false, status: 'read', quando: DateTime(2026, 9, 6)),
      ]).single;

      expect(conversa.nomeDoContato, 'Marcos Patrick');
      expect(conversa.titulo, 'Marcos Patrick');
    });

    test('sem nome nenhum, o título é o próprio telefone', () {
      final conversa = agruparEmConversas([
        _msg(id: 'a', recebida: false, status: 'sent', quando: DateTime(2026, 9, 5)),
      ]).single;

      expect(conversa.titulo, '5511999999999');
    });

    test('mensagem sem telefone é descartada em vez de virar conversa fantasma', () {
      final conversas = agruparEmConversas([
        _msg(id: 'orfa', telefone: '', quando: DateTime(2026, 9, 5)),
      ]);

      expect(conversas, isEmpty);
    });
  });

  group('janelaAbertaEm', () {
    final agora = DateTime(2026, 9, 5, 12, 0);

    test('aberta quando a pessoa escreveu há menos de 24h', () {
      final conversa = agruparEmConversas([
        _msg(id: 'a', quando: agora.subtract(const Duration(hours: 3))),
      ]).single;

      expect(janelaAbertaEm(conversa, agora: agora), isTrue);
    });

    test('fechada quando a última mensagem da pessoa passou de 24h', () {
      final conversa = agruparEmConversas([
        _msg(id: 'a', quando: agora.subtract(const Duration(hours: 25))),
      ]).single;

      expect(janelaAbertaEm(conversa, agora: agora), isFalse);
    });

    test('só mensagem NOSSA não abre janela nenhuma', () {
      // O que abre a janela é a pessoa escrever. Uma conversa só de avisos
      // enviados continua limitada a template, por mais recente que seja.
      final conversa = agruparEmConversas([
        _msg(id: 'a', recebida: false, status: 'delivered', quando: agora.subtract(const Duration(minutes: 5))),
      ]).single;

      expect(janelaAbertaEm(conversa, agora: agora), isFalse);
    });

    test('uma resposta nossa depois não fecha a janela antes da hora', () {
      final conversa = agruparEmConversas([
        _msg(id: 'dela', quando: agora.subtract(const Duration(hours: 2))),
        _msg(id: 'nossa', recebida: false, status: 'sent', quando: agora.subtract(const Duration(hours: 1))),
      ]).single;

      expect(janelaAbertaEm(conversa, agora: agora), isTrue);
    });
  });

  group('MensagemWhatsapp', () {
    test('mídia sem legenda vira rótulo, não texto inventado', () {
      expect(_msg(id: 'a', tipo: 'image', texto: '', quando: DateTime(2026, 9, 5)).resumo, '[imagem]');
      expect(_msg(id: 'b', tipo: 'audio', texto: '', quando: DateTime(2026, 9, 5)).resumo, '[áudio]');
      expect(_msg(id: 'c', tipo: 'image', texto: 'olha', quando: DateTime(2026, 9, 5)).resumo, 'olha');
    });

    test('status só descreve mensagem enviada', () {
      expect(_msg(id: 'a', quando: DateTime(2026, 9, 5)).rotuloDoStatus, '');
      expect(
        _msg(id: 'b', recebida: false, status: 'delivered', quando: DateTime(2026, 9, 5)).rotuloDoStatus,
        'Entregue',
      );
    });

    test('falha mostra o motivo que a Meta devolveu', () {
      final falha = _msg(
        id: 'a',
        recebida: false,
        status: 'failed',
        erro: '131047 - Re-engagement message',
        quando: DateTime(2026, 9, 5),
      );

      expect(falha.falhou, isTrue);
      expect(falha.rotuloDoStatus, 'Falhou: 131047 - Re-engagement message');
    });

    test('direcao ausente no Firestore é lida como recebida', () {
      final mensagem = MensagemWhatsapp.fromFirestore('wamid.X', const {'telefone': '5511', 'texto': 'oi'});
      expect(mensagem.recebida, isTrue);
      expect(mensagem.criadaEm, isNull);
    });
  });

  group('aba WhatsApp do Painel ADM', () {
    // O painel tem 6 abas: na viewport padrão de 800x600 elas não cabem e a
    // aba WhatsApp fica fora de alcance do toque.
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    testWidgets('lista as conversas com quem falou com o canal', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final conversa = agruparEmConversas([
        _msg(id: 'a', nome: 'Marcos', texto: 'esqueci minha senha', quando: DateTime.now()),
      ]).single;

      await tester.pumpWidget(_painel(FakeWhatsappRepository(conversas: [conversa])));
      await _abrirAbaWhatsapp(tester);

      expect(find.text('Marcos'), findsOneWidget);
      expect(find.textContaining('esqueci minha senha'), findsOneWidget);
      expect(find.textContaining('Resposta livre liberada'), findsOneWidget);
    });

    testWidgets('conversa fora da janela avisa que só template resolve', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final conversa = agruparEmConversas([
        _msg(id: 'a', nome: 'Antiga', quando: DateTime.now().subtract(const Duration(days: 3))),
      ]).single;

      await tester.pumpWidget(_painel(FakeWhatsappRepository(conversas: [conversa])));
      await _abrirAbaWhatsapp(tester);

      expect(find.textContaining('só template'), findsOneWidget);
    });

    testWidgets('sem mensagem nenhuma, explica o que vai aparecer ali', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_painel(FakeWhatsappRepository()));
      await _abrirAbaWhatsapp(tester);

      expect(find.textContaining('Nenhuma mensagem ainda'), findsOneWidget);
    });

    testWidgets('erro de leitura não deixa a aba em branco', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_painel(FakeWhatsappRepository(falhar: true)));
      await _abrirAbaWhatsapp(tester);

      expect(find.textContaining('Não foi possível carregar as conversas'), findsOneWidget);
    });

    testWidgets('tocar numa conversa abre os balões dela', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final conversa = agruparEmConversas([
        _msg(id: 'a', nome: 'Marcos', texto: 'esqueci minha senha', quando: DateTime.now()),
        _msg(id: 'b', recebida: false, status: 'read', texto: 'seu código é 123', quando: DateTime.now()),
      ]).single;

      await tester.pumpWidget(_painel(FakeWhatsappRepository(conversas: [conversa])));
      await _abrirAbaWhatsapp(tester);

      await tester.tap(find.text('Marcos'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }

      expect(find.text('seu código é 123'), findsOneWidget);
      expect(find.text('5511999999999'), findsOneWidget);
      expect(find.text('Lida'), findsOneWidget);
    });
  });
}
