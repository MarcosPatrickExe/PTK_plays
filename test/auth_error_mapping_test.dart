// Testa o mapeamento de erros do login social (Google e Apple).
//
// Cobre especificamente a regressao relatada: ao selecionar a conta Google
// (ou concluir o fluxo Apple), qualquer excecao que nao fosse
// GoogleSignInException/SignInWithAppleAuthorizationException/
// FirebaseAuthException subia sem tratamento e o botao ficava preso em
// "carregando" pra sempre (o usuario via isso como "nao acontece nada").

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
        'Esse domínio não está autorizado a fazer login com Google. Avise o administrador do app.',
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
      expect(mapearErroLoginApple(erro), 'Login ou senha incorretos.');
    });

    test('excecao inesperada nao fica sem tratamento', () {
      final erroInesperado = Exception('erro nativo qualquer nao mapeado');
      expect(mapearErroLoginApple(erroInesperado), isNotNull);
    });
  });
}
