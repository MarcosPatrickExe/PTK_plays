import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

final themeNotifier = ValueNotifier<bool>(true); // true = dark

class HomePage extends StatelessWidget {
  const HomePage({ super.key });

  @override
  Widget build( BuildContext context ) {
    
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppThemes.darkBackground
                  : AppThemes.lightBackground,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        PostCard(isDark: isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: GradientBottomNav(isDark: isDark),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PTK Plays',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => themeNotifier.value = !themeNotifier.value,
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final bool isDark;
  const PostCard({super.key, required this.isDark});

  @override
  Widget build( BuildContext context ) {
    
    final accent =  isDark ? AppThemes.darkAccent : AppThemes.lightAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppThemes.darkCard : AppThemes.lightCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                'há 2h',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🔥 Novo vídeo hoje às 20h!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gameplay intensa, muitos sustos e aquele caos que vocês gostam 😈🎮',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}


class GradientBottomNav extends StatelessWidget {
  
  final bool isDark;
  const GradientBottomNav({ super.key, required this.isDark });

  @override
  Widget build( BuildContext context ) {
    
    final accent = isDark ? AppThemes.darkAccent : AppThemes.lightAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppThemes.darkCard
            : AppThemes.lightCard,
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: accent,
        unselectedItemColor:
            isDark ? Colors.white54 : Colors.black45,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
