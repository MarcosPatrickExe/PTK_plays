import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/AvatarPreset.dart';
import '../utils/AuthTheme.dart';

/// Diametro maximo de cada avatar. Existe por causa de tela larga (iPad,
/// cartao desktop do cadastro): a grade e de 3 colunas e divide a largura
/// disponivel, entao sem teto os avatares crescem junto com a coluna.
const double _diametroMaximo = 84;

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
                // Center + AspectRatio(1) e o que garante o circulo: a
                // celula da grade nao e quadrada (childAspectRatio 0.82,
                // menos o rotulo), entao um BoxShape.circle solto viraria
                // uma elipse. O AspectRatio pega o menor lado disponivel.
                //
                // O teto de _diametroMaximo e por causa do iPad: ali a
                // coluna do formulario e larga, e sem limite cada avatar
                // esticava ate virar um bloco enorme (o print de 12/set).
                // No celular a celula ja e menor que isso, entao o teto nao
                // muda nada.
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _diametroMaximo,
                      maxHeight: _diametroMaximo,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: escolhido ? corDestaque : Colors.transparent, width: 3),
                          boxShadow: escolhido
                              ? const [BoxShadow(color: Color(0x66C828B4), blurRadius: 16, offset: Offset(0, 6))]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipOval(child: Image.asset(preset.asset, fit: BoxFit.cover)),
                            ),
                            if (escolhido)
                              // No canto inferior direito, e nao no de cima:
                              // num circulo os cantos do quadrado ficam de
                              // fora, e aqui o selo encosta na borda em vez
                              // de flutuar solto fora do desenho.
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(Icons.check_circle, color: corDestaque, size: 18),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
