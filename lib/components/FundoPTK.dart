import 'package:flutter/material.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

/// Fundo das etapas do cadastro: a arte do PTK que corresponde à etapa
/// atual, trocando com transição quando a pessoa avança ou volta.
///
/// A troca é um cross-fade com um deslize leve, e não um corte seco, porque
/// as artes são todas do mesmo personagem no mesmo cenário — cortar seco
/// pareceria um glitch, enquanto o cross-fade lê como o PTK mudando de
/// pose junto com a pergunta.
///
/// [asset] pode ser nulo: etapas que ainda não têm arte definida caem só no
/// gradiente do app, sem quebrar o layout.
class FundoPTK extends StatelessWidget {
  final String? asset;

  /// Escurece a arte pra o texto e os campos por cima continuarem legíveis.
  /// 0 = arte crua, 1 = totalmente coberta.
  final double escurecimento;

  const FundoPTK({super.key, required this.asset, this.escurecimento = .55});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente do app por baixo: é o que aparece enquanto a arte
        // carrega, e nas etapas que não têm arte.
        const DecoratedBox(decoration: BoxDecoration(gradient: AuthTheme.backgroundDark)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (filho, animacao) {
            return FadeTransition(
              opacity: animacao,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(.06, 0), end: Offset.zero).animate(animacao),
                child: filho,
              ),
            );
          },
          child: asset == null
              ? const SizedBox.expand(key: ValueKey('sem-arte'))
              : Image.asset(
                  asset!,
                  key: ValueKey(asset),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
        // Escurece de baixo pra cima: o rosto do PTK (no topo da arte) fica
        // mais visível, e os campos, que ficam na metade de baixo, ganham
        // contraste.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: escurecimento * .55),
                Colors.black.withValues(alpha: escurecimento),
                Colors.black.withValues(alpha: escurecimento + .2 > 1 ? 1 : escurecimento + .2),
              ],
              stops: const [0, .45, 1],
            ),
          ),
        ),
      ],
    );
  }
}
