import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

void main() {
  group('AuthTheme.themeBtnBg/Border', () {
    // Antes desses valores caiam pra 0x26/0x24 (~15%), o card do botao de
    // trocar de tema ficava quase invisivel contra o fundo gradiente. Depois
    // (18/ago/2026) o usuario pediu fundo totalmente opaco e branco, em vez
    // de so "mais opaco" — trava isso pra nao regredir de volta pro vidro
    // translucido.
    test('fundo do card em modo escuro e branco totalmente opaco', () {
      expect(AuthTheme.themeBtnBgDark, Colors.white);
    });

    test('fundo do card em modo claro e branco totalmente opaco', () {
      expect(AuthTheme.themeBtnBgLight, Colors.white);
    });

    test('borda do card continua visivel (nao totalmente transparente)', () {
      expect(AuthTheme.themeBtnBorderDark.a, greaterThan(0));
      expect(AuthTheme.themeBtnBorderLight.a, greaterThan(0));
    });
  });
}
