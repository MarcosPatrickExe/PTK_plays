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

  /// `publishedAt` vem em ISO-8601 do YouTube. Formata pra dd/MM/aaaa, ou
  /// devolve null quando o campo vier vazio/invalido (o card so nao mostra
  /// essa linha nesse caso, em vez de exibir lixo).
  String? _dataPublicacao() {
    final data = DateTime.tryParse(notification.publishedAt);
    if (data == null) return null;
    final local = data.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year}';
  }

  Widget _badgeYoutube() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFFF0000), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'YouTube',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.play_arrow, size: 13, color: Colors.white),
          ],
        ),
      ),
    );
  }

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

                // Thumbnail (quadrado, pra o card nao esticar em telas largas)
                AspectRatio(
                  aspectRatio: 1,
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
                                // Mesmos detalhes dos cards de live no Feed:
                                // data de publicacao e uma badge clicavel da
                                // plataforma, que leva pro video.
                                if (_dataPublicacao() != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_outlined,
                                        size: 15,
                                        color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Publicado em ${_dataPublicacao()}',
                                        style: GoogleFonts.outfit(
                                          color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                _badgeYoutube(),
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
