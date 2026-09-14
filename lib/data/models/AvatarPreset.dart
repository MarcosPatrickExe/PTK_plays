import '../../i18n/Idioma.dart';

/// Um dos 6 avatares pre-definidos que o usuario escolhe no cadastro (e pode
/// trocar depois na edicao de perfil). Ver UserModel.avatarPreset.
class AvatarPreset {
  final String chave;
  final String asset;
  const AvatarPreset({required this.chave, required this.asset});

  /// O nome que aparece embaixo do avatar.
  ///
  /// E getter, e nao campo guardado, porque a lista abaixo e `const` e o
  /// texto muda com o idioma: um `const` congela a frase na compilacao, e o
  /// avatar ficaria em portugues dentro de um app em ingles. O que a chave
  /// identifica — o desenho — nao muda de lingua; so o rotulo muda.
  String get label => switch (chave) {
        'gamer' => textos.avatarGamer,
        'streamer' => textos.avatarStreamer,
        'inscrito' => textos.avatarInscrito,
        'blogueiro' => textos.avatarBlogueiro,
        'maratonista' => textos.avatarMaratonista,
        'otaku' => textos.avatarOtaku,
        _ => chave,
      };
}

const List<AvatarPreset> catalogoAvataresPreset = [
  AvatarPreset(chave: 'gamer', asset: 'assets/avatares/avatar_gamer.png'),
  AvatarPreset(chave: 'streamer', asset: 'assets/avatares/avatar_streamer.png'),
  AvatarPreset(chave: 'inscrito', asset: 'assets/avatares/avatar_inscrito.png'),
  AvatarPreset(chave: 'blogueiro', asset: 'assets/avatares/avatar_blogueiro.png'),
  AvatarPreset(chave: 'maratonista', asset: 'assets/avatares/avatar_maratonista.png'),
  AvatarPreset(chave: 'otaku', asset: 'assets/avatares/avatar_otaku.png'),
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
