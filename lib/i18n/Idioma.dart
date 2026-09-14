/// Qual lingua o app esta falando, e como ele decide isso.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'Textos.dart';
import 'TextosEnUs.dart';
import 'TextosPtBr.dart';

/// As linguas que o app fala. Nao ha uma terceira opcao "automatico": o
/// automatico e a ausencia de escolha, e quem guarda isso e o
/// [IdiomaController], nao este enum.
enum Idioma {
  ptBR(Locale('pt', 'BR')),
  enUS(Locale('en', 'US'));

  const Idioma(this.locale);

  final Locale locale;

  Textos get textos => switch (this) {
        Idioma.ptBR => const TextosPtBr(),
        Idioma.enUS => const TextosEnUs(),
      };
}

/// Traduz a lista de linguas do aparelho na lingua que o app vai falar.
///
/// Recebe a **lista**, e nao so a primeira, porque o aparelho entrega as
/// preferencias em ordem: alguem com "espanhol, portugues, ingles" quer
/// portugues muito mais do que ingles, e olhar so a primeira jogaria essa
/// pessoa no ingles sem motivo.
///
/// Cai no portugues quando nada na lista bate — o canal e brasileiro, e a
/// maior parte de quem chega sem preferencia reconhecivel vem daqui.
Idioma idiomaPara(List<Locale> preferencias) {
  for (final locale in preferencias) {
    switch (locale.languageCode.toLowerCase()) {
      case 'pt':
        return Idioma.ptBR;
      case 'en':
        return Idioma.enUS;
    }
  }
  return Idioma.ptBR;
}

/// Onde o app inteiro le o texto da vez.
///
/// **Por que um global, e nao so um `Provider`.** Metade das frases do app
/// nasce longe da arvore de widgets — `ValidacaoCadastro`, `AuthViewModel`,
/// `AuthErrorTranslator`, os repositorios. Nesses lugares nao ha
/// `BuildContext` pra consultar, e arrastar um ate la seria empurrar UI pra
/// dentro da regra de negocio.
///
/// O `Provider` continua existindo ([IdiomaController]) pra que as telas
/// **redesenhem** quando a lingua muda. Os dois nao competem: o controller
/// e quem escreve aqui, e este global e so a leitura.
///
/// **O padrao e portugues de proposito, e nao o idioma do aparelho.** Quem
/// chama [IdiomaApp.detectar] e o `main()`. Os testes nao passam por ele, e
/// por isso continuam lendo portugues — se este global consultasse a
/// plataforma sozinho, cada `flutter test` viraria ingles (o ambiente de
/// teste responde en-US) e as 350 asserts de texto quebrariam de uma vez,
/// sem que nada no app tivesse mudado.
class IdiomaApp {
  IdiomaApp._();

  static Idioma _atual = Idioma.ptBR;

  static Idioma get atual => _atual;

  static Textos get textos => _atual.textos;

  /// Define a lingua na mao. Usado pelo [IdiomaController] e pelos testes.
  static void definir(Idioma idioma) => _atual = idioma;

  /// Le a preferencia do aparelho.
  ///
  /// Vale tanto no celular quanto na web: no navegador o Flutter preenche
  /// `locales` a partir do `navigator.languages`, que e a lista de idiomas
  /// configurada no proprio navegador. **Nao tem nada a ver com
  /// localizacao geografica** e nao pede permissao nenhuma — idioma e uma
  /// preferencia declarada, nao uma medida de onde a pessoa esta.
  static void detectar([PlatformDispatcher? plataforma]) {
    final dispatcher = plataforma ?? WidgetsBinding.instance.platformDispatcher;
    final preferencias = dispatcher.locales.isNotEmpty ? dispatcher.locales : <Locale>[dispatcher.locale];
    definir(idiomaPara(preferencias));
  }
}

/// Atalho de leitura. O app inteiro escreve `textos.entrar` em vez de
/// `IdiomaApp.textos.entrar`.
Textos get textos => IdiomaApp.textos;

/// A lingua como estado observavel, pra que as telas se redesenhem quando
/// ela muda.
///
/// Anda junto do `ThemeController`: as telas que ja fazem
/// `context.watch<ThemeController>()` passam a observar este tambem, e e
/// isso que faz a troca de idioma aparecer sem sair da tela.
class IdiomaController extends ChangeNotifier {
  IdiomaController({Idioma? inicial}) {
    if (inicial != null) IdiomaApp.definir(inicial);
  }

  Idioma get idioma => IdiomaApp.atual;

  /// true quando a lingua veio do aparelho e ninguem escolheu na mao. Serve
  /// pra tela de configuracoes mostrar qual opcao esta marcada sem mentir
  /// que foi uma escolha.
  bool get seguindoOAparelho => _escolhaManual == null;
  Idioma? _escolhaManual;

  void trocar(Idioma novo) {
    if (novo == IdiomaApp.atual && _escolhaManual != null) return;
    _escolhaManual = novo;
    IdiomaApp.definir(novo);
    notifyListeners();
  }
}
