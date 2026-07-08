import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/view/Profile.dart';
import 'package:ptk_plays/view/Videos.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../view/Home.dart';

Widget buildBottonNavBar({
   required int currentIndex,
   required BuildContext widgetContext,
   required bool isDark,
   required YoutubeViewModel ytViewModel,
   required String apiKey,
   required AuthViewModel authViewModel,
 }) {

  void navegar(int destino) {
    if (destino == currentIndex) return;

    late final Widget tela;
    if (destino == 0) {
      tela = HomePage(viewmodelYT: ytViewModel, apiKEY: apiKey, authViewModel: authViewModel);
    } else if (destino == 1) {
      tela = Videos(viewmodelYT: ytViewModel, apiKEY: apiKey, authViewModel: authViewModel);
    } else {
      tela = Profile(viewmodelYT: ytViewModel, apiKey: apiKey, authViewModel: authViewModel);
    }

    Navigator.of(widgetContext).pushReplacement(MaterialPageRoute(builder: (context) => tela));
  }

  // Rodape flutuante, tipo dock do macOS: nao encosta na borda inferior nem
  // nas laterais, com cantos arredondados em volta e sombra propria — por
  // isso a sombra fica num Container por fora do ClipRRect (senao o clip
  // corta a sombra, que se espalha alem dos limites do card).
  return ResponsiveCenter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x331E0046), blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AuthTheme.cardBgDark : AuthTheme.cardBgLight,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: isDark ? AuthTheme.cardBorderDark : AuthTheme.cardBorderLight),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
                unselectedItemColor: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                type: BottomNavigationBarType.fixed,
                currentIndex: currentIndex,
                onTap: navegar,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
                  BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
