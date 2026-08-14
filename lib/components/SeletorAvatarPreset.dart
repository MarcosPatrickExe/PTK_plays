import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/AvatarPreset.dart';
import '../utils/AuthTheme.dart';

/// Grade de escolha unica dos 6 avatares pre-definidos (Cadastro e a secao
/// de foto de perfil do EditarPerfil). [selecionado] e a chave atualmente
/// escolhida (ou null se nenhuma ainda).
class SeletorAvatarPreset extends StatelessWidget {
  final bool isDark;
  final String? selecionado;
  final ValueChanged<String> onSelecionar;

  const SeletorAvatarPreset({
    super.key,
    required this.isDark,
    required this.selecionado,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: catalogoAvataresPreset.map((preset) {
        final escolhido = preset.chave == selecionado;
        final corDestaque = isDark ? AuthTheme.linkDark : AuthTheme.linkLight;

        return GestureDetector(
          onTap: () => onSelecionar(preset.chave),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: escolhido ? corDestaque : Colors.transparent, width: 3),
                    boxShadow: escolhido
                        ? const [BoxShadow(color: Color(0x66C828B4), blurRadius: 16, offset: Offset(0, 6))]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(preset.asset, fit: BoxFit.cover),
                        ),
                      ),
                      if (escolhido)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(Icons.check_circle, color: corDestaque, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                preset.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: escolhido ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
