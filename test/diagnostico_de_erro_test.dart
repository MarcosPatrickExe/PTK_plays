// O padrao de mensagem de erro do app: texto pra pessoa + codigo da causa
// pra quem investiga. Ver lib/utils/DiagnosticoDeErro.dart sobre o porque.
//
// A regra que estes testes protegem: NENHUMA mensagem de falha do app pode
// chegar na tela sem dizer de onde ela veio. Duas revisoes da App Store
// foram perdidas por causa disso.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/AuthErrorTranslator.dart';
import 'package:ptk_plays/utils/DiagnosticoDeErro.dart';

void main() {
  group('codigoDeErro separa as camadas', () {
    // A familia (o que vem antes da barra) e a parte util: ela diz em qual
    // camada parar de procurar. Um codigo que jogue tudo em "erro/..." nao
    // serviria pra nada.
    test('Auth, Firestore, Storage e nativo nao se confundem', () {
      expect(codigoDeErro(FirebaseAuthException(code: 'wrong-password')), 'auth/wrong-password');
      expect(
        codigoDeErro(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')),
        'cloud_firestore/permission-denied',
      );
      expect(
        codigoDeErro(FirebaseException(plugin: 'firebase_storage', code: 'unauthorized')),
        'firebase_storage/unauthorized',
      );
      expect(codigoDeErro(PlatformException(code: 'camera_access_denied')),
          'plataforma/camera_access_denied');
    });

    test('FirebaseAuthException nao e rotulada como FirebaseException', () {
      // Ela E subclasse de FirebaseException. Se a ordem dos `is` inverter,
      // todo erro de login vira "firebase_auth/..." em vez de "auth/...",
      // e pior: cai na traducao errada la em mensagemDeErro.
      final erro = FirebaseAuthException(code: 'user-not-found');
      expect(codigoDeErro(erro), startsWith('auth/'));
    });

    test('erro de tipo desconhecido ainda produz um codigo, nunca vazio', () {
      expect(codigoDeErro(StateError('oops')), 'inesperado/StateError');
      expect(codigoDeErro(Exception('qualquer')), startsWith('inesperado/'));
      expect(codigoDeErro('uma string solta'), 'inesperado/String');
    });
  });

  group('comCodigo monta a mensagem final', () {
    test('preserva a frase e anexa o codigo no fim', () {
      final erro = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      final mensagem = comCodigo('Não deu pra salvar.', erro);

      expect(mensagem, startsWith('Não deu pra salvar.'));
      expect(mensagem, endsWith('(código: cloud_firestore/unavailable)'));
    });

    test('comCodigoManual usa o mesmo formato pra falha sem exceção', () {
      // canLaunchUrl devolve false sem lancar nada. Inventar uma Exception
      // so pra ter o que passar pro comCodigo faria o codigo descrever a
      // excecao falsa em vez da condicao real.
      expect(
        comCodigoManual('Não foi possível abrir a live :/', 'link/sem-app-que-abra'),
        endsWith('(código: link/sem-app-que-abra)'),
      );
    });
  });

  group('mensagemDeErro escolhe a tradução certa por camada', () {
    test('erro de Auth usa o tradutor de Auth', () {
      expect(mensagemDeErro(FirebaseAuthException(code: 'invalid-email')), 'Email inválido.');
    });

    test('erro de Firestore/Storage NÃO cai mais no genérico', () {
      // Regressao real: ate 12/set estes codigos passavam por
      // traduzirErroDeAuth, que nao conhece nenhum deles — entao os dois
      // casos mais comuns (regra nao publicada, internet fora) viravam
      // "Algo deu errado".
      final regra = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      final rede = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');

      expect(mensagemDeErro(regra), contains('permissão'));
      expect(mensagemDeErro(rede), contains('conexão'));
      expect(mensagemDeErro(regra), isNot('Algo deu errado. Tente novamente.'));
    });

    test('storage e firestore compartilham o vocabulário', () {
      // 'unauthorized' (Storage) e 'permission-denied' (Firestore) sao a
      // mesma coisa pra quem esta usando o app.
      expect(traduzirErroDeServico('unauthorized'), traduzirErroDeServico('permission-denied'));
      expect(traduzirErroDeServico('object-not-found'), traduzirErroDeServico('not-found'));
    });

    test('código desconhecido ainda dá uma frase, e o código salva o resto', () {
      final exotico = FirebaseException(plugin: 'cloud_firestore', code: 'codigo-que-nao-existe');
      expect(mensagemDeErro(exotico), 'Algo deu errado. Tente novamente.');
      // A frase e generica, mas a mensagem final NAO e — e esse o ponto.
      expect(mensagemComCodigo(exotico), contains('cloud_firestore/codigo-que-nao-existe'));
    });
  });

  group('mensagemComCodigo é o caminho normal', () {
    test('junta tradução e código numa chamada só', () {
      final erro = FirebaseAuthException(code: 'network-request-failed');
      expect(mensagemComCodigo(erro), 'Sem conexão com a internet.\n\n(código: auth/network-request-failed)');
    });
  });
}
