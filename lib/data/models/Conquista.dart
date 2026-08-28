import 'UserModel.dart';

/// Definicao de uma conquista (badge) do sistema de gamificacao.
///
/// Conquistas baseadas em contador (contadorChave != null) mostram uma barra
/// de progresso na tela de Conquistas. O cliente NAO tem permissao de
/// escrever em 'badges' (ver firestore.rules) alem da badge 'novato'
/// concedida no cadastro -- conceder as demais automaticamente quando o
/// contador atinge a meta depende de um backend de confianca que ainda nao
/// existe (ver ROADMAP.md). Por enquanto essa tela so exibe o progresso.
class Conquista {
  final String chave;
  final String titulo;
  final String descricao;
  final String? contadorChave;
  final int meta;

  const Conquista({
    required this.chave,
    required this.titulo,
    required this.descricao,
    this.contadorChave,
    this.meta = 0,
  });
}

const List<Conquista> catalogoConquistas = [
  Conquista(
    chave: 'admin',
    titulo: 'Administrador',
    descricao: 'Cuida do PTK Plays por dentro: modera a comunidade e publica os avisos do canal.',
  ),
  Conquista(
    chave: 'novato',
    titulo: 'Novato',
    descricao: 'Toda conta criada no PTK Plays já começa com essa conquista.',
  ),
  Conquista(
    chave: 'comentarista',
    titulo: 'Comentarista',
    descricao: 'Comente em 10 posts ou vídeos.',
    contadorChave: 'comentarios',
    meta: 10,
  ),
  Conquista(
    chave: 'popular',
    titulo: 'Popular',
    descricao: 'Receba 50 curtidas nos seus comentários.',
    contadorChave: 'curtidas',
    meta: 50,
  ),
  Conquista(
    chave: 'presencaVip',
    titulo: 'Presença VIP',
    descricao: 'Clique pra assistir 5 lives.',
    contadorChave: 'cliquesLive',
    meta: 5,
  ),
];

/// Rotulo de exibicao de uma badge salva em UserModel.badges. Cai de volta
/// pra chave crua se ela nao estiver no catalogo (ex: badge futura concedida
/// por um backend que essa versao do app ainda nao conhece).
String labelConquista(String chave) {
  for (final conquista in catalogoConquistas) {
    if (conquista.chave == chave) return conquista.titulo;
  }
  return chave;
}

/// Progresso (0.0 a 1.0) do usuario em direcao a uma conquista baseada em
/// contador. Conquistas sem contadorChave (ex: 'novato') nao tem progresso
/// gradual: ou ja foi conquistada, ou nao.
double progressoDaConquista(UserModel usuario, Conquista conquista) {
  final chaveContador = conquista.contadorChave;
  if (chaveContador == null || conquista.meta <= 0) {
    return usuario.badges.contains(conquista.chave) ? 1.0 : 0.0;
  }

  final atual = usuario.contadores[chaveContador] ?? 0;
  return (atual / conquista.meta).clamp(0.0, 1.0);
}
