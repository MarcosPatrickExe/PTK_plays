/// Um dos 6 avatares pre-definidos que o usuario escolhe no cadastro (e pode
/// trocar depois na edicao de perfil). Ver UserModel.avatarPreset.
class AvatarPreset {
  final String chave;
  final String label;
  final String asset;
  const AvatarPreset({required this.chave, required this.label, required this.asset});
}

const List<AvatarPreset> catalogoAvataresPreset = [
  AvatarPreset(chave: 'gamer', label: 'Gamer', asset: 'assets/avatares/avatar_gamer.png'),
  AvatarPreset(chave: 'streamer', label: 'Streamer', asset: 'assets/avatares/avatar_streamer.png'),
  AvatarPreset(chave: 'inscrito', label: 'Inscrito do canal', asset: 'assets/avatares/avatar_inscrito.png'),
  AvatarPreset(chave: 'blogueiro', label: 'Blogueiro', asset: 'assets/avatares/avatar_blogueiro.png'),
  AvatarPreset(chave: 'maratonista', label: 'Maratonista', asset: 'assets/avatares/avatar_maratonista.png'),
  AvatarPreset(chave: 'otaku', label: 'Otaku', asset: 'assets/avatares/avatar_otaku.png'),
];

/// Retorna true se [chave] corresponde a um dos presets do catalogo.
bool avatarPresetValido(String chave) => catalogoAvataresPreset.any((preset) => preset.chave == chave);

/// Caminho do asset do preset identificado por [chave], ou null se a chave
/// estiver vazia ou nao corresponder a nenhum preset do catalogo (conta sem
/// avatar escolhido, ou dado desatualizado/corrompido).
String? assetDoAvatarPreset(String chave) {
  for (final preset in catalogoAvataresPreset) {
    if (preset.chave == chave) return preset.asset;
  }
  return null;
}

/// Avatar padrao aplicado a contas sem preset escolhido e sem fotoUrl (ex:
/// contas criadas antes desse recurso existir, ou login social sem foto do
/// provedor) — em vez de cair num icone generico.
const String avatarPresetPadrao = 'inscrito';

/// Resolve a chave de preset a usar na exibicao: o preset escolhido tem
/// prioridade (se existir); senao, se a conta ja tem uma fotoUrl (Google/
/// Apple Sign-In ou upload proprio), retorna vazio pra sinalizar "usar
/// fotoUrl"; senao, cai no [avatarPresetPadrao].
String chavePresetParaExibir({required String avatarPreset, required String fotoUrl}) {
  if (avatarPreset.isNotEmpty) return avatarPreset;
  if (fotoUrl.isNotEmpty) return '';
  return avatarPresetPadrao;
}
