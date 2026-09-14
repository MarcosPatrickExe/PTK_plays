import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/i18n/Idioma.dart';
import 'package:ptk_plays/i18n/Textos.dart';
import 'package:ptk_plays/i18n/TextosEnUs.dart';
import 'package:ptk_plays/i18n/TextosPtBr.dart';
import 'package:ptk_plays/utils/AuthErrorTranslator.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/utils/ValidacaoCadastro.dart';
import 'package:ptk_plays/view/Configuracoes.dart';

void main() {
  // Toda troca de idioma tem que ser desfeita: o idioma e um global, e um
  // teste que o deixa em ingles derruba os outros 340 arquivos de teste,
  // que esperam portugues. O tearDown vale pro arquivo inteiro.
  tearDown(() => IdiomaApp.definir(Idioma.ptBR));

  group('idiomaPara', () {
    test('português em qualquer região cai no pt-BR', () {
      expect(idiomaPara([const Locale('pt', 'BR')]), Idioma.ptBR);
      expect(idiomaPara([const Locale('pt', 'PT')]), Idioma.ptBR);
      expect(idiomaPara([const Locale('pt')]), Idioma.ptBR);
    });

    test('inglês em qualquer região cai no en-US', () {
      expect(idiomaPara([const Locale('en', 'US')]), Idioma.enUS);
      expect(idiomaPara([const Locale('en', 'GB')]), Idioma.enUS);
    });

    test('olha a lista inteira, não só a primeira preferência', () {
      // É o caso que justifica receber a lista. Alguém com "espanhol,
      // português, inglês" configurado quer português muito mais que
      // inglês; olhando só o primeiro, o espanhol não bate com nada e a
      // pessoa cairia no inglês sem motivo nenhum.
      final preferencias = [const Locale('es', 'AR'), const Locale('pt', 'BR'), const Locale('en')];

      expect(idiomaPara(preferencias), Idioma.ptBR);
    });

    test('idioma que o app não fala cai no português', () {
      // O canal é brasileiro: quem chega sem preferência reconhecível tem
      // mais chance de ler português do que inglês.
      expect(idiomaPara([const Locale('ja', 'JP')]), Idioma.ptBR);
      expect(idiomaPara([]), Idioma.ptBR);
    });
  });

  group('o catálogo responde na língua da vez', () {
    test('o padrão é português, mesmo sem ninguém ter escolhido', () {
      // Essa é a linha que segura o resto da suíte de pé: o ambiente de
      // `flutter test` responde en-US, e se o global consultasse a
      // plataforma sozinho, centenas de asserts de texto virariam inglês
      // sem nada ter mudado no app.
      expect(IdiomaApp.atual, Idioma.ptBR);
      expect(textos.entrar, 'Entrar');
    });

    test('trocando o idioma, o mesmo getter muda de língua', () {
      IdiomaApp.definir(Idioma.enUS);

      expect(textos.entrar, 'Sign in');
      expect(textos.criarConta, 'Create account');
    });

    test('a validação, que não tem contexto nenhum, acompanha', () {
      // O motivo de o catálogo ser um global e não um Provider: aqui não
      // há BuildContext, e arrastar um até a regra de validação seria
      // empurrar UI pra dentro dela.
      IdiomaApp.definir(Idioma.enUS);

      expect(validarNickname(''), 'Pick a nickname so we can call you something.');
      expect(validarEmail('nada'), "That email doesn't look valid.");
    });

    test('a tradução de erro do Firebase acompanha', () {
      IdiomaApp.definir(Idioma.enUS);

      expect(traduzirErroDeAuth('invalid-email'), 'Invalid email.');
      expect(traduzirErroDeServico('permission-denied'), contains('permission'));
    });
  });

  group('formato de data', () {
    test('a ordem dia/mês inverte em inglês', () {
      // Não é só traduzir a palavra: 09/03 é setembro no Brasil e março
      // nos EUA. Deixar a ordem fixa faria a data mentir pra metade de
      // quem lê, sem nenhum sinal de que mentiu.
      expect(const TextosPtBr().dataDiaMes('09', '03'), '09/03');
      expect(const TextosEnUs().dataDiaMes('09', '03'), '03/09');
    });

    test('o "às" vira "at" junto com a inversão', () {
      expect(const TextosPtBr().dataDiaMesHora('09', '03', '14', '30'), '09/03 às 14:30');
      expect(const TextosEnUs().dataDiaMesHora('09', '03', '14', '30'), '03/09 at 14:30');
    });
  });

  group('frases com variável', () {
    test('o valor entra no lugar, e não o nome da variável', () {
      // Regressão: o gerador do catálogo deixou "\$mensagem" escapado, o
      // que em Dart é um cifrão literal. A mensagem chegava na tela como
      // "$mensagem (código: $codigo)" e o analyze não acusava — é String
      // válida. Só um teste que lê o resultado pega isso.
      final resultado = const TextosPtBr().codigoDoErro('Deu ruim', 'auth/x');

      expect(resultado, contains('Deu ruim'));
      expect(resultado, contains('(código: auth/x)'));
      expect(resultado, isNot(contains(r'$')));
    });

    test('nenhuma frase do catálogo carrega um cifrão sobrando', () {
      // Varre as duas línguas de uma vez: qualquer frase com "$" no
      // resultado é uma interpolação que não aconteceu.
      for (final textos in <Textos>[const TextosPtBr(), const TextosEnUs()]) {
        expect(textos.cadastroPasso(2, 6), isNot(contains(r'$')));
        expect(textos.validaNickCurto(3), isNot(contains(r'$')));
        expect(textos.feedOpcaoNumero(1), isNot(contains(r'$')));
        expect(textos.adminRemoverTitulo('PTKzin'), isNot(contains(r'$')));
        expect(textos.dataHaMinutos(5), isNot(contains(r'$')));
      }
    });
  });

  group('nenhum texto hard-coded sobrou em lib/', () {
    // A regra de 14/set: nenhuma frase pra pessoa nasce fora do catálogo.
    // Sem esta varredura ela vira boa intenção — a tela nova entra em
    // português, ninguém repara, e o app volta a ser meio bilíngue.
    //
    // A lista de exceções é deliberadamente curta e cada linha tem motivo.
    final permitidos = <String, String>{
      'lib/i18n/TextosPtBr.dart': 'é o catálogo',
      'lib/i18n/TextosEnUs.dart': 'é o catálogo',
      'lib/firebase_options.dart': 'gerado pelo FlutterFire, e as mensagens são pro desenvolvedor',
      'lib/main_screenshots.dart': 'conteúdo falso de canal pras capturas da loja, não é UI',
      'lib/view/Configuracoes.dart': 'os nomes das línguas ficam na própria língua, de propósito',
    };

    test('varredura', () {
      // Acento é o sinal mais barato e mais confiável de frase em
      // português: nome de campo do Firestore, chave de erro e caminho de
      // asset não têm nenhum. O que escapa são frases em inglês sem
      // acento — e essas o próprio contrato da classe abstrata pega, já
      // que só existem se alguém escreveu à mão.
      const acentos = 'áéíóúàâêôãõçÁÉÍÓÚÀÂÊÔÃÕÇ';
      final literal = RegExp('[\'"][^\'"\n]*[$acentos][^\'"\n]*[\'"]');

      final suspeitas = <String>[];

      for (final arquivo in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!arquivo.path.endsWith('.dart')) continue;
        if (permitidos.containsKey(arquivo.path)) continue;

        final linhas = arquivo.readAsLinesSync();
        for (var i = 0; i < linhas.length; i++) {
          // Comentário é texto pra quem programa, não pra quem usa.
          final linha = _semComentario(linhas[i]);
          if (linha.trim().isEmpty) continue;

          for (final achado in literal.allMatches(linha)) {
            suspeitas.add('${arquivo.path}:${i + 1}  ${achado.group(0)}');
          }
        }
      }

      expect(
        suspeitas,
        isEmpty,
        reason: 'Texto com acento fora do catálogo — passe pelo `textos.`:\n${suspeitas.join('\n')}',
      );
    });
  });

  group('o seletor de idioma na tela de configurações', () {
    Widget tela() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => IdiomaController()),
        ],
        child: const MaterialApp(home: Configuracoes()),
      );
    }

    testWidgets('lista as duas línguas escritas nelas mesmas', (tester) async {
      await tester.pumpWidget(tela());

      // Não traduzidos de propósito: quem abriu esta tela porque não
      // entende o que está escrito precisa achar a própria língua na
      // lista. "Inglês (EUA)" não ajuda quem só lê inglês.
      expect(find.text('Português (Brasil)'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);
    });

    testWidgets('tocar em English troca a tela na hora', (tester) async {
      await tester.pumpWidget(tela());
      expect(find.text('Configurações'), findsOneWidget);

      await tester.tap(find.text('English (US)'));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Configurações'), findsNothing);
      // E os nomes das línguas continuam iguais.
      expect(find.text('Português (Brasil)'), findsOneWidget);
    });
  });
}

/// Tira o comentário da linha, respeitando aspas: um `//` dentro de uma
/// string (uma URL, por exemplo) não começa comentário nenhum, e cortar ali
/// faria a varredura perder o resto da linha.
String _semComentario(String linha) {
  var dentroDeAspas = false;
  String? aspa;

  for (var i = 0; i < linha.length; i++) {
    final c = linha[i];
    if (dentroDeAspas) {
      if (c == r'\') {
        i++;
      } else if (c == aspa) {
        dentroDeAspas = false;
      }
      continue;
    }
    if (c == "'" || c == '"') {
      dentroDeAspas = true;
      aspa = c;
      continue;
    }
    if (c == '/' && i + 1 < linha.length && linha[i + 1] == '/') {
      return linha.substring(0, i);
    }
  }
  return linha;
}
