import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptk_plays/data/models/BloqueioDaConta.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/view/Login.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';

/// Vigia a conta logada e **expulsa** pro login quem for banido ou suspenso
/// enquanto está usando o app.
///
/// Envolve o app inteiro (ver `builder` do `MaterialApp`, em `main.dart`).
/// Vive acima da navegação — nunca é desmontado por uma troca de tela —,
/// então o bloqueio vale em qualquer tela e em tempo real: o Firestore
/// empurra a mudança sozinho via `.snapshots()`, sem reabrir o app.
///
/// **Até 14/set ele COBRIA o app com uma tela de bloqueio**, deixando a
/// pessoa logada por baixo. Isso comprava uma coisa boa — uma suspensão
/// vencendo com o app aberto devolvia a pessoa exatamente onde estava — e
/// pagava caro por ela: quem foi banido continuava com sessão válida, só
/// com uma cortina na frente. Qualquer caminho que escapasse da cortina
/// devolvia o app inteiro a quem tinha acabado de ser banido.
///
/// Agora o bloqueio **desloga e manda pro login**, com o aviso chegando
/// como modal lá (ver `mostrarModalContaBloqueada`). O que se perde é a
/// navegação preservada; quem está banido não tem pra onde navegar mesmo.
///
/// **A conta do Firebase Auth não é apagada, e é isso que faz o mecanismo
/// funcionar**: é ela que carrega o `uid` que aponta pro `users/{uid}` com o
/// `estadoModeracao`. Sem o login, o banimento não teria onde ficar — a
/// pessoa criaria outra conta com o mesmo e-mail e entraria limpa.
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
  StreamSubscription<UserModel?>? _assinatura;

  /// Impede duas expulsões seguidas. O stream pode emitir de novo enquanto
  /// o logout está em curso, e a segunda empilharia outro Login por cima do
  /// primeiro — com dois modais.
  bool _expulsando = false;

  @override
  void initState() {
    super.initState();
    // `listen`, e não `StreamBuilder`: expulsar é efeito colateral, e efeito
    // colateral não pode morar no `build` — ele roda a cada reconstrução, e
    // navegar de dentro dele é justamente o que produz "setState during
    // build".
    _assinatura = widget.authViewModel.streamUsuarioReativo().listen(_avaliar);
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _avaliar(UserModel? usuario) async {
    final bloqueio = bloqueioDe(usuario);
    if (bloqueio == null || _expulsando) return;

    // Quem já saiu não precisa ser expulso de novo. Cobre a corrida com o
    // login: o repositório desloga sozinho ao ver a conta bloqueada, e o
    // stream ainda pode entregar o documento antigo depois disso.
    if (!widget.authViewModel.usuarioLogado) return;

    _expulsando = true;
    await widget.authViewModel.logout();

    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Login(
          viewmodelYT: widget.viewmodelYT,
          apiKey: widget.apiKey,
          authViewModel: widget.authViewModel,
          bloqueioParaAvisar: bloqueio,
        ),
      ),
      (route) => false,
    );

    _expulsando = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
