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

/// Tela de configurações do app, acessada pelo menu lateral. Por enquanto
/// a única opção real é o idioma; o resto ainda é placeholder.
class Configuracoes extends StatelessWidget {
  const Configuracoes({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;
    // `watch` nos dois: trocar o idioma tem que redesenhar esta tela na
    // hora, senão a pessoa toca em "English" e continua lendo português.
    final idiomaController = context.watch<IdiomaController>();

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
                              textos.configuracoes,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    textos.configuracoesIdioma,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .5,
                                      color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    textos.configuracoesIdiomaTexto,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  for (final opcao in Idioma.values)
                                    _OpcaoDeIdioma(
                                      isDark: isDark,
                                      idioma: opcao,
                                      marcado: idiomaController.idioma == opcao,
                                      onTocar: () => idiomaController.trocar(opcao),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            CardVidro(
                              isDark: isDark,
                              child: Text(
                                textos.configuracoesEmBreve,
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

/// Uma linha da lista de idiomas, com o círculo marcado à esquerda.
///
/// Os nomes das línguas NÃO passam pelo catálogo: "Português (Brasil)" e
/// "English (US)" aparecem sempre no próprio idioma que nomeiam. Traduzir o
/// nome de uma língua é exatamente o jeito de esconder a opção de quem
/// precisa dela — quem abriu esta tela porque não entende o que está
/// escrito tem que conseguir achar a própria língua na lista.
class _OpcaoDeIdioma extends StatelessWidget {
  final bool isDark;
  final Idioma idioma;
  final bool marcado;
  final VoidCallback onTocar;

  const _OpcaoDeIdioma({
    required this.isDark,
    required this.idioma,
    required this.marcado,
    required this.onTocar,
  });

  static const Map<Idioma, String> _nomeNaPropriaLingua = {
    Idioma.ptBR: 'Português (Brasil)',
    Idioma.enUS: 'English (US)',
  };

  @override
  Widget build(BuildContext context) {
    final cor = isDark ? AuthTheme.titleDark : AuthTheme.titleLight;

    return InkWell(
      onTap: onTocar,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              marcado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: marcado ? (isDark ? AuthTheme.linkDark : AuthTheme.linkLight) : cor.withValues(alpha: .5),
            ),
            const SizedBox(width: 12),
            Text(
              _nomeNaPropriaLingua[idioma]!,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: marcado ? FontWeight.w700 : FontWeight.w500,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
