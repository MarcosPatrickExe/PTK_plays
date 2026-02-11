import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ptk_plays/view/Videos.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../components/Header.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';
import "package:ptk_plays/utils/ThemeController.dart";



class HomePage extends StatelessWidget {
  final YoutubeViewModel _viewmodelYT;
  final String _apiKEY;

  HomePage({ super.key, required viewmodelYT, required apiKEY }) : this._viewmodelYT = viewmodelYT, this._apiKEY = apiKEY;

  @override
  Widget build( BuildContext context ) {
    
    bool isDark = context.watch<ThemeController>().isDark; 

    return Scaffold(
      body: Container(
        decoration: BoxDecoration( gradient: isDark ? AppThemes.darkBackground : AppThemes.lightBackground),
        child: SafeArea(
          child: Column(
            children: [
              buildHeader(title: "Feed", widgetContext: context, isDarkk: isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [ PostCard(isDark: isDark) ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GradientBottomNav( isDark: isDark, ref: this ),
    );
  }
    
}
  




class PostCard extends StatelessWidget {
  final bool isDark;
  const PostCard({ super.key, required this.isDark });

  @override
  Widget build( BuildContext context ) {
    final accent = isDark ? AppThemes.darkAccent : AppThemes.lightAccent;

    print('\n \n \n \n========================> \n TEMA ATUAL É: ${ isDark ? "BLACK" : "LIGHT"} \n \n');


    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppThemes.darkCard : AppThemes.lightCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent,
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'PTK Plays',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const Spacer(),
              Text('há 2h', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🔥 Novo vídeo hoje às 20h!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 8),
          Text('Gameplay intensa, muitos sustos e aquele caos que vocês gostam 😈🎮', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }
}


class GradientBottomNav extends StatelessWidget {
  final bool isDark;
  final HomePage ref;

  const GradientBottomNav({super.key, required this.isDark, required this.ref });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: isDark ? AppThemes.darkCard : AppThemes.lightCard),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: isDark ? AppThemes.darkAccent : AppThemes.lightAccent,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
        type: BottomNavigationBarType.fixed,
        onTap: (int value_selected) {
          
          if (value_selected == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => Videos(viewmodelYT: ref._viewmodelYT, apiKEY: ref._apiKEY ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
          // BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
