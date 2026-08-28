import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:ptk_plays/utils/AuthTheme.dart";
import "package:ptk_plays/utils/ThemeController.dart";
import 'package:provider/provider.dart';


/// Cabecalho das telas autenticadas: titulo a esquerda, botoes de acao a
/// direita. Nao tem mais painel de vidro proprio (o `ClipRRect` +
/// `BackdropFilter` + `Container` com cor/borda que existia aqui) - esse
/// painel era uma faixa fixa que ficava aparecendo por baixo/atras do
/// conteudo. Quem faz esse papel agora e o [DegradeTopo], o scrim em
/// degrade desenhado no Stack de cada tela: o titulo e os botoes flutuam
/// direto sobre ele, no mesmo padrao do app do ChatGPT que serviu de
/// referencia.
Widget buildHeader({ required String title, required BuildContext widgetContext, VoidCallback? onEditar, Widget? menu }) {

  final bool isDark = widgetContext.watch<ThemeController>().isDark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
          ),
        ),
        Row(
          children: [
            if (onEditar != null) ...[
              GestureDetector(
                onTap: onEditar,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? AuthTheme.themeBtnBgDark : AuthTheme.themeBtnBgLight,
                    border: Border.all(color: isDark ? AuthTheme.themeBtnBorderDark : AuthTheme.themeBtnBorderLight),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: isDark ? AuthTheme.themeIconDark : AuthTheme.themeIconLight,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            GestureDetector(
              onTap: () => widgetContext.read<ThemeController>().toggleTheme(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? AuthTheme.themeBtnBgDark : AuthTheme.themeBtnBgLight,
                  border: Border.all(color: isDark ? AuthTheme.themeBtnBorderDark : AuthTheme.themeBtnBorderLight),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? AuthTheme.themeIconDark : AuthTheme.themeIconLight,
                  size: 20,
                ),
              ),
            ),
            if (menu != null) ...[
              const SizedBox(width: 10),
              menu,
            ],
          ],
        ),
      ],
    ),
  );

}
