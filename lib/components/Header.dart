import "dart:ui";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:ptk_plays/utils/AuthTheme.dart";
import "package:ptk_plays/utils/ThemeController.dart";
import 'package:provider/provider.dart';


/// Altura total ocupada por [buildHeader] (margem de 10 + 14 de padding
/// interno + 40 do botao + 14 + 10). As telas usam isso como padding
/// superior da lista: o cabecalho flutua por cima do conteudo (nao ocupa
/// espaco numa Column), entao a lista precisa comecar abaixo dele.
const double alturaCabecalho = 88;

/// Cabecalho das telas autenticadas: painel de vidro com o titulo a
/// esquerda e os botoes de acao a direita.
///
/// **Importante**: nao deve ser colocado numa `Column` acima da lista. Ele
/// e uma camada flutuante no `Stack` da tela, desenhada por cima do
/// conteudo e do [DegradeTopo]. Quando ficava na Column, a area rolavel
/// comecava exatamente embaixo dele e o conteudo era **recortado numa
/// linha reta** ali - era isso que aparecia como uma "faixa" fixa logo
/// abaixo dos botoes ao rolar a lista. Como camada flutuante, o conteudo
/// passa por baixo do vidro (desfocado pelo `BackdropFilter`) em vez de
/// ser cortado.
Widget buildHeader({ required String title, required BuildContext widgetContext, VoidCallback? onEditar, Widget? menu }) {

  final bool isDark = widgetContext.watch<ThemeController>().isDark;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AuthTheme.cardBgDark : AuthTheme.cardBgLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AuthTheme.cardBorderDark : AuthTheme.cardBorderLight),
          ),
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
        ),
      ),
    ),
  );

}
