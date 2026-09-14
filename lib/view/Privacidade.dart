import 'package:flutter/material.dart';
import '../i18n/Idioma.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/AuthBackground.dart';
import '../components/AuthWidgets.dart';
import '../components/DegradeTopo.dart';
import '../components/Responsive.dart';
import '../utils/AuthTheme.dart';
import '../utils/ThemeController.dart';

/// Tela de politica de privacidade, acessada pelo menu lateral. Conteudo
/// ainda por definir - placeholder visual ate o texto real da politica ser
/// redigido.
class Privacidade extends StatelessWidget {
  const Privacidade({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight),
        child: Stack(
          children: [
            Positioned.fill(child: AuthBackground(isDark: isDark)),
            DegradeTopo(isDark: isDark),
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      child: ResponsiveMaxWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 44),
                            Text(
                              textos.privacidade,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .3,
                                color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                              ),
                            ),
                            const SizedBox(height: 30),
                            CardVidro(
                              isDark: isDark,
                              child: Text(
                                textos.privacidadeEmBreve,
                                style: GoogleFonts.outfit(
                                  color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: BotaoVoltar(isDark: isDark, onTap: () => Navigator.of(context).pop()),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: BotaoTema(isDark: isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
