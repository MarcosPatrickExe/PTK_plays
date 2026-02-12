import "dart:ui";
import "package:flutter/material.dart";
import "package:ptk_plays/utils/ThemeController.dart";
import 'package:provider/provider.dart';


Widget buildHeader({ required String title, required BuildContext widgetContext, bool? isDarkk }) {
  
  final bool isDark = widgetContext.watch<ThemeController>().isDark;
  final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08);

// APPBAR
         // FILTRAR VIDEOS:
         //  IconButton( icon: const Icon( Icons.search, color: Colors.purple), onPressed: () {},  ),
          
         // NOTIFICACOES:
         //  IconButton( onPressed: null, icon: Icon( Icons.notification_important )),
        

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => widgetContext.read<ThemeController>().toggleTheme() 
              ),
            ],
          ),
        ),
      ),
    ),
  );
  
}
