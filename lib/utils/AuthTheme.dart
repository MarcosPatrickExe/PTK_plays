import 'package:flutter/material.dart';

/// Tokens de cor/gradiente das telas de autenticacao (Login/Cadastro),
/// traduzidos do design fornecido (Login PTK Plays - source.html).
/// Ficam separados do AppThemes porque tem uma identidade visual propria,
/// diferente do resto do app.
class AuthTheme {
  static const backgroundDark = LinearGradient(
    begin: Alignment(-0.3, -1.0),
    end: Alignment(0.3, 1.0),
    stops: [0.0, 0.42, 0.72, 1.0],
    colors: [Color(0xFF3A1670), Color(0xFF6A1FB0), Color(0xFF9B2FD6), Color(0xFFC23BD8)],
  );

  static const backgroundLight = LinearGradient(
    begin: Alignment(-0.3, -1.0),
    end: Alignment(0.3, 1.0),
    stops: [0.0, 0.40, 0.72, 1.0],
    colors: [Color(0xFFF6ECFF), Color(0xFFEFD9FF), Color(0xFFFFE1F2), Color(0xFFFFD3EA)],
  );

  static const blob1Dark = Color(0x8CD278FF);
  static const blob2Dark = Color(0x805A3CFF);
  static const blob3Dark = Color(0x59FF78DC);

  static const blob1Light = Color(0x59C45AF0);
  static const blob2Light = Color(0x47786EFF);
  static const blob3Light = Color(0x4DFF78BE);

  static const symMainDark = Color(0x21FFFFFF);
  static const symCyanDark = Color(0x8C2DD4F0);
  static const symMagDark = Color(0x8CFF5AC8);

  static const symMainLight = Color(0x6B5F1EA5);
  static const symCyanLight = Color(0xCC0A82C3);
  static const symMagLight = Color(0xBFC823A0);

  static const titleDark = Colors.white;
  static const titleLight = Color(0xFF3A1560);

  static const subDark = Color(0xB8FFFFFF);
  static const subLight = Color(0xB85A288C);

  static const cardBgDark = Color(0x1FFFFFFF);
  static const cardBorderDark = Color(0x47FFFFFF);
  static const cardBgLight = Color(0xB8FFFFFF);
  static const cardBorderLight = Color(0x38A046DC);

  static const labelDark = Color(0xD9FFFFFF);
  static const labelLight = Color(0xFF6A2FA0);

  static const registerDark = Color(0xD1FFFFFF);
  static const registerLight = Color(0xCC46236E);

  static const linkDark = Color(0xFFFFD24A);
  static const linkLight = Color(0xFFC23BD8);

  static const dividerDark = Color(0x47FFFFFF);
  static const dividerLight = Color(0x478C46C8);

  static const ouDark = Color(0x99FFFFFF);
  static const ouLight = Color(0x995A288C);

  static const themeBtnBgDark = Color(0x26FFFFFF);
  static const themeBtnBorderDark = Color(0x4DFFFFFF);
  static const themeBtnBgLight = Color(0x24A046DC);
  static const themeBtnBorderLight = Color(0x47A046DC);

  static const themeIconDark = Color(0xFFFFD24A);
  static const themeIconLight = Color(0xFFFF8A3D);

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5AA8), Color(0xFFA12EE0)],
  );

  static const inputBgDark = Color(0xF2FFFFFF);
  static const inputBgLight = Colors.white;
  static const placeholderColor = Color(0xFF9AA0AD);
  static const pwdIconDark = Color(0xFF9AA0AD);
  static const pwdIconLight = Color(0xFF8A7F95);
  static const inputTextColor = Color(0xFF3C4043);

  static const googleBg = Colors.white;
  static const googleBorderDark = Colors.transparent;
  static const googleBorderLight = Color(0x2E783CB4);
  static const googleText = Color(0xFF3C4043);
}
