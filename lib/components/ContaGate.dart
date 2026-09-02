import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/view/ContaBloqueada.dart';
import 'package:ptk_plays/view/Login.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';

/// Cobre [child] com [ContaBloqueadaView] quando [usuario] está banido ou
/// suspenso (ver [UserModel.estaBloqueado]).
///
/// [child] continua montado por baixo, só coberto — não é trocado por
/// outra rota. Isso é o que faz uma suspensão vencer com o app aberto
/// devolver a pessoa pro exato lugar onde estava, sem perder navegação: o
/// [Stack] só para de desenhar [ContaBloqueadaView] por cima.
///
/// Widget puro (sem Firebase), pra dar pra testar isolado — ver
/// `conta_gate_test.dart`. Quem alimenta [usuario] de verdade é
/// [ContaGate], logo abaixo.
class GateDeConta extends StatelessWidget {
  final UserModel? usuario;
  final bool isDark;
  final VoidCallback onSair;
  final Widget child;

  const GateDeConta({
    super.key,
    required this.usuario,
    required this.isDark,
    required this.onSair,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final conta = usuario;
    final bloqueado = conta != null && conta.estaBloqueado();

    return Stack(
      children: [
        child,
        if (bloqueado) ContaBloqueadaView(isDark: isDark, usuario: conta, onSair: onSair),
      ],
    );
  }
}

/// Envolve o app inteiro (ver `builder` do `MaterialApp`, em `main.dart`)
/// com [GateDeConta], alimentado por [AuthViewModel.streamUsuarioReativo].
///
/// Antes deste gate, só o Feed (`Home`) checava o bloqueio — banir alguém
/// enquanto estava em Vídeos/Perfil/Conquistas só surtia efeito quando a
/// pessoa voltasse pro Feed. Como este widget vive acima da navegação
/// inteira (nunca é desmontado por uma troca de tela), o bloqueio passa a
/// valer em qualquer tela, em tempo real — o Firestore empurra a mudança
/// sozinho via `.snapshots()`, sem precisar reabrir o app.
///
/// Usa `streamUsuarioReativo` (não o `streamUsuarioAtual` das telas comuns)
/// porque este widget nunca é recriado a cada login: precisa trocar de uid
/// sozinho quando a pessoa entra ou sai da conta.
class ContaGate extends StatefulWidget {
  final AuthViewModel authViewModel;
  final YoutubeViewModel viewmodelYT;
  final String apiKey;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const ContaGate({
    super.key,
    required this.authViewModel,
    required this.viewmodelYT,
    required this.apiKey,
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<ContaGate> createState() => _ContaGateState();
}

class _ContaGateState extends State<ContaGate> {
  late final Stream<UserModel?> _usuario = widget.authViewModel.streamUsuarioReativo();

  Future<void> _sair() async {
    await widget.authViewModel.logout();

    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Login(
          viewmodelYT: widget.viewmodelYT,
          apiKey: widget.apiKey,
          authViewModel: widget.authViewModel,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _usuario,
      builder: (context, snapshot) {
        return GateDeConta(
          usuario: snapshot.data,
          isDark: context.watch<ThemeController>().isDark,
          onSair: _sair,
          child: widget.child,
        );
      },
    );
  }
}
