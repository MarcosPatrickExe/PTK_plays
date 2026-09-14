import 'UserModel.dart';

/// O que a tela de login precisa saber pra explicar por que a entrada foi
/// recusada.
///
/// **Por que isto existe como objeto próprio, e não é só o [UserModel].**
/// Quem vê esta informação está **deslogado** — o app acabou de expulsar a
/// pessoa. O `UserModel` inteiro não sobreviveria a isso com sentido: ele é
/// o perfil de alguém logado, e carregá-lo até a tela de login sugeriria
/// que ainda há sessão. Aqui só viajam as três coisas que a mensagem usa.
class BloqueioDaConta {
  /// true para banimento (sem prazo), false para suspensão.
  final bool banido;

  /// Até quando a suspensão vale. Sempre nulo em banimento.
  final DateTime? ate;

  /// Motivo que o admin escreveu, se escreveu algum.
  final String? motivo;

  const BloqueioDaConta({required this.banido, this.ate, this.motivo});

  static BloqueioDaConta de(UserModel usuario) => BloqueioDaConta(
        banido: usuario.estadoModeracao == 'banido',
        ate: usuario.suspensoAte,
        motivo: usuario.motivoModeracao,
      );
}

/// O bloqueio de [usuario], ou null se a conta está liberada.
///
/// Função pura de propósito: é a decisão inteira de "esta pessoa pode ficar
/// dentro do app?", e ela precisa ser testável sem Firebase e sem widget.
///
/// Uma **suspensão vencida conta como liberada** mesmo que o admin não tenha
/// clicado em "Reativar conta" — quem decide é [UserModel.estaBloqueado],
/// não o selo que o Painel ADM mostra.
BloqueioDaConta? bloqueioDe(UserModel? usuario, [DateTime? agora]) {
  if (usuario == null) return null;
  if (!usuario.estaBloqueado(agora)) return null;
  return BloqueioDaConta.de(usuario);
}
