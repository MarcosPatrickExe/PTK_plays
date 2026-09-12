// Testa o mapeamento de erros do login social (Google e Apple).
//
// Cobre especificamente a regressao relatada: ao selecionar a conta Google
// (ou concluir o fluxo Apple), qualquer excecao que nao fosse
// GoogleSignInException/SignInWithAppleAuthorizationException/
// FirebaseAuthException subia sem tratamento e o botao ficava preso em
// "carregando" pra sempre (o usuario via isso como "nao acontece nada").

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:ptk_plays/utils/AuthErrorTranslator.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';

void main() {
  group('mapearErroLoginGoogle', () {
    test('cancelamento pelo usuario retorna null (sem popup de erro)', () {
      final erro = GoogleSignInException(code: GoogleSignInExceptionCode.canceled);
      expect(mapearErroLoginGoogle(erro), isNull);
    });

    test('outros codigos de GoogleSignInException retornam mensagem', () {
      final erro = GoogleSignInException(code: GoogleSignInExceptionCode.interrupted);
      expect(mapearErroLoginGoogle(erro), isNotNull);
    });

    test('FirebaseAuthException de dominio nao autorizado e traduzida', () {
      final erro = FirebaseAuthException(code: 'unauthorized-domain');
      expect(
        mapearErroLoginGoogle(erro),
        contains('Esse domínio não está autorizado a fazer login com Google.'),
      );
    });

    test('fechar o popup web nao conta como erro', () {
      final erro = FirebaseAuthException(code: 'popup-closed-by-user');
      expect(mapearErroLoginGoogle(erro), isNull);
    });

    test('excecao nativa inesperada (ex: PlatformException) nao fica sem tratamento', () {
      // Antes da correcao, um erro deste tipo nao era capturado por nenhum
      // "on X catch" e o Future de loginComGoogle() explodia sem retornar
      // nada pra UI, deixando o loading preso.
      final erroInesperado = Exception('erro nativo qualquer nao mapeado');
      expect(mapearErroLoginGoogle(erroInesperado), isNotNull);
    });
  });

  group('mapearErroLoginApple', () {
    test('cancelamento pelo usuario retorna null', () {
      final erro = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'cancelado',
      );
      expect(mapearErroLoginApple(erro), isNull);
    });

    test('FirebaseAuthException e traduzida', () {
      final erro = FirebaseAuthException(code: 'invalid-credential');
      expect(mapearErroLoginApple(erro), contains('Login ou senha incorretos.'));
    });

    test('excecao inesperada nao fica sem tratamento', () {
      final erroInesperado = Exception('erro nativo qualquer nao mapeado');
      expect(mapearErroLoginApple(erroInesperado), isNotNull);
    });

    test('codigo "unknown" cita o aparelho de teste como hipotese, sem afirmar', () {
      // A Apple retorna AuthorizationErrorCode.unknown quando a autorizacao
      // falha antes de chegar a um motivo especifico — ou seja, ela NAO diz
      // qual foi a causa. Num simulador (o caso do Sauce Labs em 17/ago) a
      // causa costuma ser a falta de conta Apple/iCloud; num iPad de revisor
      // da App Store, logado com 2FA, nao e. Por isso a mensagem oferece a
      // hipotese em vez de afirmar que o aparelho esta errado — afirmar
      // soava como o app culpando quem testa.
      final erro = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.unknown,
        message: 'unknown',
      );
      final mensagem = mapearErroLoginApple(erro)!;
      expect(mensagem, contains('conta Apple'));
      expect(mensagem, contains('iCloud'));
      expect(mensagem, contains('Se este for um'), reason: 'precisa ser hipotese, nao afirmacao');
      expect(mensagem, isNot(contains('Verifique se este dispositivo')));
    });

    test('falha do Firestore nao e apresentada como falha da Apple', () {
      // A gravacao em users/{uid} faz parte do fluxo de loginComApple. Numa
      // conta nova ela passa pelo `allow create` mais restritivo do
      // firestore.rules, e uma recusa la chega como FirebaseException do
      // cloud_firestore — nao como FirebaseAuthException. Antes de
      // 11/set/2026 isso caia no texto generico "nao foi possivel entrar com
      // a Apple", indistinguivel de um erro do proprio provedor.
      final erro = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      final mensagem = mapearErroLoginApple(erro)!;
      expect(mensagem, contains('salvar o seu perfil'));
      expect(mensagem, isNot(contains('entrar com a Apple')));
    });

    test('FirebaseAuthException continua sendo tratada antes de FirebaseException', () {
      // FirebaseAuthException E uma FirebaseException. Se a ordem dos `is`
      // inverter, todo erro de Auth vira "nao deu pra salvar o perfil".
      final erro = FirebaseAuthException(code: 'invalid-credential');
      expect(mapearErroLoginApple(erro), contains('Login ou senha incorretos.'));
    });
  });

  group('codigoDeDiagnosticoDeLogin', () {
    // O codigo anexado a mensagem e o que transforma um print de popup
    // mandado por terceiro (revisor da Apple, inscrito no Discord) em
    // diagnostico — em release o debugPrint do try/catch nao vai a lugar
    // nenhum. Cada familia de erro precisa de um prefixo diferente, senao
    // ele nao separa nada.
    test('separa Apple, Auth, Firestore e plataforma em prefixos distintos', () {
      expect(
        codigoDeDiagnosticoDeLogin(SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.unknown,
          message: 'unknown',
        )),
        'apple/unknown',
      );
      expect(
        codigoDeDiagnosticoDeLogin(FirebaseAuthException(code: 'operation-not-allowed')),
        'auth/operation-not-allowed',
      );
      expect(
        codigoDeDiagnosticoDeLogin(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        ),
        'cloud_firestore/permission-denied',
      );
      expect(
        codigoDeDiagnosticoDeLogin(PlatformException(code: 'sign_in_failed')),
        'plataforma/sign_in_failed',
      );
    });

    test('erro fora de todas as familias ainda produz um codigo util', () {
      expect(codigoDeDiagnosticoDeLogin(StateError('oops')), 'inesperado/StateError');
    });

    test('o codigo aparece na mensagem que chega na tela', () {
      final mensagem = mapearErroLoginApple(FirebaseAuthException(code: 'operation-not-allowed'))!;
      expect(mensagem, contains('(código: auth/operation-not-allowed)'));
    });

    test('cancelar nao gera codigo nenhum, porque nao gera mensagem', () {
      final cancelou = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'cancelado',
      );
      expect(mapearErroLoginApple(cancelou), isNull);
    });
  });

  group('traduzirErroDeAuth', () {
    test('operation-not-allowed nao cita provedor nenhum', () {
      // O Firebase devolve esse codigo pra QUALQUER provedor desabilitado no
      // Console. O texto antigo dizia "o login com Google nao esta
      // habilitado" — inclusive quando quem tinha falhado era a Apple, o que
      // manda quem investiga pro painel errado. Era um dos suspeitos da
      // reprovacao de 27/ago/2026.
      final mensagem = traduzirErroDeAuth('operation-not-allowed');
      expect(mensagem, isNot(contains('Google')));
      expect(mensagem, isNot(contains('Apple')));
    });
  });
}
