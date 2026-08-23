import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/AuthBackground.dart';
import '../components/AuthWidgets.dart';
import '../components/Responsive.dart';
import '../utils/AuthTheme.dart';
import '../utils/ThemeController.dart';

/// Tela de configurações do app, acessada pelo menu lateral. Ainda sem
/// opções reais - placeholder visual ate definirmos o que entra aqui
/// (notificações, idioma, etc.).
class Configuracoes extends StatelessWidget {
  const Configuracoes({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight),
        child: Stack(
          children: [
            Positioned.fill(child: AuthBackground(isDark: isDark)),
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
                              'Configurações',
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
                                'As opções de configuração do app ainda estão a caminho. Em breve você vai poder ajustar suas preferências por aqui.',
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
