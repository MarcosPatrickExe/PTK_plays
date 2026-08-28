import 'package:flutter/material.dart';

/// Cor base do scrim. No tema claro e um roxo escuro (combina com a
/// identidade do app em vez de um cinza morto); no escuro e preto de
/// verdade, pra sombra ficar bem mais forte que no claro.
Color _corScrim(bool isDark) => isDark ? Colors.black : const Color(0xFF3A1560);

/// Opacidade da ponta mais forte do degrade (a que encosta na borda da
/// tela). O modo escuro usa bem mais que o claro, como pedido.
double _opacidadeScrim(bool isDark) => isDark ? 0.62 : 0.40;

/// Scrim (sombreamento em degrade) fixado no topo da tela, por tras da
/// status bar e do cabecalho (titulo + botoes de tema/menu) - mesmo efeito
/// visto em apps como o ChatGPT, usado pra manter esses controles
/// legiveis e dar profundidade ao conteudo que rola por baixo deles.
///
/// So deve entrar nas telas autenticadas (Home/Feed, Videos, Profile,
/// EditarPerfil, Configuracoes, Privacidade, Conquistas) - Login.dart e
/// Cadastro.dart ficam de fora por enquanto.
///
/// Fica no Stack DEPOIS do conteudo rolavel (pra sombrear o que passa por
/// baixo) e ANTES do cabecalho. [IgnorePointer] garante que ele nunca
/// intercepta toques que deveriam ir pros controles reais.
class DegradeTopo extends StatelessWidget {
  final bool isDark;
  const DegradeTopo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final alturaStatusBar = MediaQuery.of(context).padding.top;
    final cor = _corScrim(isDark);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: alturaStatusBar + 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // A parada intermediaria segura a cor por mais tempo antes de
              // sumir: sem ela o degrade "morre" cedo demais e a sombra fica
              // fraca justamente na altura do cabecalho.
              stops: const [0.0, 0.55, 1.0],
              colors: [
                cor.withOpacity(_opacidadeScrim(isDark)),
                cor.withOpacity(_opacidadeScrim(isDark) * 0.45),
                cor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mesmo scrim do [DegradeTopo], espelhado no rodape: escurece o conteudo
/// que passa por baixo da barra de navegacao (Feed/Videos/Perfil), pelo
/// mesmo motivo - legibilidade dos controles e profundidade.
///
/// Vai no Stack logo ANTES da barra de navegacao, pra ficar entre o
/// conteudo rolavel e ela.
class DegradeRodape extends StatelessWidget {
  final bool isDark;
  const DegradeRodape({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final alturaBarraSistema = MediaQuery.of(context).padding.bottom;
    final cor = _corScrim(isDark);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: alturaBarraSistema + 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                cor.withOpacity(_opacidadeScrim(isDark)),
                cor.withOpacity(_opacidadeScrim(isDark) * 0.45),
                cor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
