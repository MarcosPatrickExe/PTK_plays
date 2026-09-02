import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

/// Tela que substitui o Feed inteiro quando a conta logada está banida ou
/// suspensa (ver [UserModel.estaBloqueado]). Só existe pra impedir o uso do
/// app pela UI — quem barra de verdade a publicação e o voto é o
/// `firestore.rules` (`contaBloqueada()`), então mesmo alguém que
/// contornasse essa tela não conseguiria fazer nada no feed.
class ContaBloqueadaView extends StatelessWidget {
  final bool isDark;
  final UserModel usuario;
  final VoidCallback onSair;

  const ContaBloqueadaView({super.key, required this.isDark, required this.usuario, required this.onSair});

  bool get _banido => usuario.estadoModeracao == 'banido';

  @override
  Widget build(BuildContext context) {
    final corTitulo = isDark ? AuthTheme.titleDark : AuthTheme.titleLight;
    final corSub = isDark ? AuthTheme.subDark : AuthTheme.subLight;
    final motivo = usuario.motivoModeracao;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight)),
          Positioned.fill(child: AuthBackground(isDark: isDark)),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_banido ? Icons.block : Icons.pause_circle_outline, size: 64, color: const Color(0xFFE0264F)),
                    const SizedBox(height: 20),
                    Text(
                      _banido ? 'Sua conta foi banida' : 'Sua conta está suspensa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: corTitulo),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _banido
                          ? 'Você não pode mais usar o PTK Plays.'
                          : 'Você não pode usar o PTK Plays até ${_formatarData(usuario.suspensoAte)}.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 14, color: corSub),
                    ),
                    if (motivo != null && motivo.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Motivo: $motivo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 13, color: corSub),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 220,
                      child: BotaoPrimario(label: 'Sair', carregando: false, onTap: onSair),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatarData(DateTime? data) {
  if (data == null) return 'uma data futura';
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
}
