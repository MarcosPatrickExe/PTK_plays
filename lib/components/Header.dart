import "dart:ui";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:ptk_plays/utils/AuthTheme.dart";
import "package:ptk_plays/utils/ThemeController.dart";
import 'package:provider/provider.dart';


Widget buildHeader({ required String title, required BuildContext widgetContext }) {

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
            ],
          ),
        ),
      ),
    ),
  );

}
