import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/data/models/Conquista.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';

class Conquistas extends StatelessWidget {
  final AuthViewModel authViewModel;
  const Conquistas({super.key, required this.authViewModel});

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
                    child: StreamBuilder<UserModel?>(
                      stream: authViewModel.streamUsuarioAtual(),
                      builder: (context, snapshot) {
                        if (snapshot.data == null) {
                          return const CircularProgressIndicator();
                        }
                        final usuario = snapshot.data!;
                        final conquistadas = catalogoConquistas.where((c) => usuario.badges.contains(c.chave)).toList();
                        final emProgresso = catalogoConquistas
                            .where((c) => c.contadorChave != null && !usuario.badges.contains(c.chave))
                            .toList();

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                          child: ResponsiveMaxWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 44),
                                Text(
                                  'Conquistas',
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
                                      _TituloSecao(isDark: isDark, texto: 'Badges conquistadas'),
                                      const SizedBox(height: 10),
                                      conquistadas.isEmpty
                                          ? Text(
                                              'Nenhuma badge conquistada ainda',
                                              style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: conquistadas.map((c) => _ChipConquista(texto: c.titulo)).toList(),
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CardVidro(
                                  isDark: isDark,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _TituloSecao(isDark: isDark, texto: 'Progresso'),
                                      const SizedBox(height: 16),
                                      for (final conquista in emProgresso) ...[
                                        _BarraDeProgresso(
                                          isDark: isDark,
                                          titulo: conquista.titulo,
                                          descricao: conquista.descricao,
                                          progresso: progressoDaConquista(usuario, conquista),
                                        ),
                                        if (conquista != emProgresso.last) const SizedBox(height: 20),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? AuthTheme.themeBtnBgDark : AuthTheme.themeBtnBgLight,
                            border: Border.all(color: isDark ? AuthTheme.themeBtnBorderDark : AuthTheme.themeBtnBorderLight),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: isDark ? AuthTheme.themeIconDark : AuthTheme.themeIconLight,
                            size: 23,
                          ),
                        ),
                      ),
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

class _TituloSecao extends StatelessWidget {
  final bool isDark;
  final String texto;
  const _TituloSecao({required this.isDark, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: .5,
        color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
      ),
    );
  }
}

class _ChipConquista extends StatelessWidget {
  final String texto;
  const _ChipConquista({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(gradient: AuthTheme.buttonGradient, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _BarraDeProgresso extends StatelessWidget {
  final bool isDark;
  final String titulo;
  final String descricao;
  final double progresso;

  const _BarraDeProgresso({
    required this.isDark,
    required this.titulo,
    required this.descricao,
    required this.progresso,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
            ),
            Text(
              '${(progresso * 100).round()}%',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 10,
            backgroundColor: isDark ? AuthTheme.themeBtnBgDark : AuthTheme.themeBtnBgLight,
            valueColor: AlwaysStoppedAnimation(AuthTheme.buttonGradient.colors.last),
          ),
        ),
        const SizedBox(height: 6),
        // Label explicativo discreto (nao muito destacado, conforme pedido):
        // fonte pequena e cor apagada, abaixo da barra.
        Text(descricao, style: GoogleFonts.outfit(fontSize: 11.5, color: isDark ? AuthTheme.subDark : AuthTheme.subLight)),
      ],
    );
  }
}
