import 'package:flutter/material.dart';
import 'package:ptk_plays/utils/app_theme.dart';
import 'package:ptk_plays/view/Videos.dart';
import '../view/Home.dart';

Widget buildBottonNavBar({ 
   required int currentIndex, 
   required BuildContext widgetContext, 
   required bool isDark,  
   required HomePage ref,
 }) {
  
  //final accent = isDark ? AppThemes.darkAccent : AppThemes.lightAccent;
  print('\n \n \n \n========================> \n TEMA ATUAL É: ${ isDark ? "BLACK" : "LIGHT"} \n \n');

  return Container(
    decoration: BoxDecoration( gradient: isDark ? AppThemes.darkCard : AppThemes.lightCard ),
    child: BottomNavigationBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: isDark ? AppThemes.darkAccent : AppThemes.lightAccent,
      unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
      type: BottomNavigationBarType.fixed,
      onTap: (int value_selected) {
        if (value_selected == 1) {
          Navigator.of(widgetContext).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) => Videos(viewmodelYT: ref.getViewModelYT, apiKEY: ref.getAPIkey),
            ),
          );
        }
      },
      items: const [
        BottomNavigationBarItem( icon: Icon(Icons.home), label: 'Feed'),
        BottomNavigationBarItem( icon: Icon(Icons.video_library), label: 'Videos'),
        // BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
        BottomNavigationBarItem( icon: Icon(Icons.person), label: 'Perfil'),
      ],
    ),
  );
}
