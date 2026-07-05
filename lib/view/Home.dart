import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../components/Header.dart';
import "package:ptk_plays/utils/ThemeController.dart";

class HomePage extends StatelessWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKEY;
  final AuthViewModel authViewModel;

  const HomePage({
    super.key,
    required this.viewmodelYT,
    required this.apiKEY,
    required this.authViewModel,
  });

  @override
  Widget build( BuildContext context ) {
    bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight)),
          Positioned.fill(child: AuthBackground(isDark: isDark)),
          SafeArea(
            child: Column(
              children: [
                buildHeader(title: "Feed", widgetContext: context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [PostCard(isDark: isDark)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottonNavBar(
        currentIndex: 0,
        widgetContext: context,
        isDark: isDark,
        apiKey: apiKEY,
        ytViewModel: viewmodelYT,
        authViewModel: authViewModel,
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final bool isDark;
  const PostCard({ super.key, required this.isDark });

  @override
  Widget build(BuildContext context) {
    return CardVidro(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AuthTheme.buttonGradient),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'PTK Plays',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
              ),
              const Spacer(),
              Text('há 2h', style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🔥 Novo vídeo hoje às 20h!',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
          ),
          const SizedBox(height: 8),
          Text(
            'Gameplay intensa, muitos sustos e aquele caos que vocês gostam 😈🎮',
            style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
          ),
        ],
      ),
    );
  }
}
