import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

void main() {
  group('AuthTheme.themeBtnBg/Border', () {
    // Antes desses valores caiam pra 0x26/0x24 (~15%), o card do botao de
    // trocar de tema ficava quase invisivel contra o fundo gradiente. Trava
    // um piso de opacidade pra nao regredir.
    const opacidadeMinima = 0x40 / 255.0;

    test('fundo do card em modo escuro esta acima do piso de opacidade', () {
      expect(AuthTheme.themeBtnBgDark.a, greaterThanOrEqualTo(opacidadeMinima));
    });

    test('fundo do card em modo claro esta acima do piso de opacidade', () {
      expect(AuthTheme.themeBtnBgLight.a, greaterThanOrEqualTo(opacidadeMinima));
    });

    test('borda do card em modo escuro e mais opaca que o fundo', () {
      expect(AuthTheme.themeBtnBorderDark.a, greaterThan(AuthTheme.themeBtnBgDark.a));
    });

    test('borda do card em modo claro e mais opaca que o fundo', () {
      expect(AuthTheme.themeBtnBorderLight.a, greaterThan(AuthTheme.themeBtnBgLight.a));
    });
  });
}
