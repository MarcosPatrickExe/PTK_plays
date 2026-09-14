import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/data/models/BloqueioDaConta.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/i18n/Idioma.dart';

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

void main() {
  tearDown(() => IdiomaApp.definir(Idioma.ptBR));

  group('bloqueioDe', () {
    // A decisão inteira de "esta pessoa pode ficar dentro do app?" mora
    // numa função pura, e não mais num widget que desenha uma cortina por
    // cima. Foi o que permitiu trocar "cobrir" por "expulsar" sem perder
    // cobertura: o que muda é quem chama, não a regra.

    test('sem usuário (deslogado), não há bloqueio', () {
      expect(bloqueioDe(null), isNull);
    });

    test('conta ativa não é bloqueio', () {
      expect(bloqueioDe(_usuario(estado: 'ativo')), isNull);
    });

    test('conta banida é bloqueio sem prazo', () {
      final bloqueio = bloqueioDe(_usuario(estado: 'banido'));

      expect(bloqueio, isNotNull);
      expect(bloqueio!.banido, isTrue);
      expect(bloqueio.ate, isNull);
    });

    test('suspensão dentro do prazo é bloqueio, e carrega a data', () {
      final futuro = DateTime.now().add(const Duration(days: 1));
      final bloqueio = bloqueioDe(_usuario(estado: 'suspenso', suspensoAte: futuro));

      expect(bloqueio, isNotNull);
      expect(bloqueio!.banido, isFalse);
      expect(bloqueio.ate, futuro);
    });

    test('suspensão vencida libera, mesmo sem o admin reativar', () {
      // Quem decide é o prazo, não o selo que o Painel ADM mostra. Se
      // dependesse do clique em "Reativar conta", toda suspensão viraria
      // banimento na prática quando o admin esquecesse de voltar nela.
      final passado = DateTime.now().subtract(const Duration(days: 1));

      expect(bloqueioDe(_usuario(estado: 'suspenso', suspensoAte: passado)), isNull);
    });

    test('carrega o motivo escrito pelo admin', () {
      final bloqueio = bloqueioDe(_usuario(estado: 'banido', motivo: 'spam no feed'));

      expect(bloqueio!.motivo, 'spam no feed');
    });
  });

  // A MENSAGEM do bloqueio é testada em `conta_bloqueada_test.dart`:
  // aqui mora a decisão (quem é bloqueado), lá mora o que a pessoa lê.

  // O `ContaGate` em si não tem teste de widget: ele depende de
  // `AuthViewModel.streamUsuarioReativo`, que fala com o Firebase Auth e o
  // Firestore reais — não há onde injetar um falso sem refatorar o
  // AuthViewModel inteiro. O que dava pra extrair foi extraído: a decisão
  // está em `bloqueioDe` (testada acima) e a mensagem está no modal
  // (testada em `conta_bloqueada_test.dart`). O que sobra no gate é
  // encanamento — deslogar e navegar.
  //
  // O que precisa ser conferido à mão:
  //  1. banir a própria conta pelo Painel ADM em outro aparelho, com o app
  //     aberto: a pessoa tem que ser jogada pro login com o modal, e não
  //     ficar numa tela de bloqueio por cima do app;
  //  2. tentar entrar de novo com senha: o modal aparece e a pessoa
  //     continua no login;
  //  3. tentar entrar pelo Google/Apple: mesma coisa — é a porta dos
  //     fundos mais óbvia do banimento;
  //  4. suspender por 7 dias e conferir que o modal diz a data certa;
  //  5. reativar a conta e conferir que o login volta a funcionar.
}
