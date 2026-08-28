import 'package:flutter/material.dart';

/// Scrim (sombreamento em degrade, preto->transparente) fixado no topo da
/// tela, por tras da status bar e dos controles do cabecalho (menu lateral,
/// titulo, botao de tema/voltar) - mesmo efeito visto em apps como o
/// ChatGPT, usado pra manter esses controles legiveis independente do que
/// estiver desenhado atras deles.
///
/// So deve entrar nas telas autenticadas (Home/Feed, Videos, Profile,
/// EditarPerfil, Configuracoes, Privacidade, Conquistas) - Login.dart e
/// Cadastro.dart ficam de fora por enquanto, junto com o resto do padrao
/// visual delas.
///
/// Fica no Stack ANTES do SafeArea/conteudo (mesma posicao de
/// `Positioned.fill(child: AuthBackground(...))`), como uma camada
/// puramente visual: [IgnorePointer] garante que ela nunca intercepta
/// toques que deveriam ir pros controles reais desenhados por cima.
class DegradeTopo extends StatelessWidget {
  const DegradeTopo({super.key});

  @override
  Widget build(BuildContext context) {
    final alturaStatusBar = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: alturaStatusBar + 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.32), Colors.black.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
