import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import '../data/models/VideoNotification.dart';

class VideoCard extends StatelessWidget {

  final VideoNotification notification;
  final bool isDark;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build( BuildContext context ) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AuthTheme.cardBorderDark : AuthTheme.cardBorderLight),
        boxShadow: const [
          BoxShadow(color: Color(0x331E0046), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: this.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Thumbnail
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network( notification.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.white54, size: 50),
                        ),
                      );
                    },
                  ),
                ),

                // Faixa de texto com efeito de vidro
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      color: isDark ? AuthTheme.cardBgDark : AuthTheme.cardBgLight,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(notification.avatarUrl),
                            backgroundColor: Colors.grey[800],
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.videoTitle,
                                  style: GoogleFonts.outfit(
                                    color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.channelTittle,
                                  style: GoogleFonts.outfit(
                                    color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
