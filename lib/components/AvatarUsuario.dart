import 'package:flutter/material.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/data/models/AvatarPreset.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

/// Foto de perfil circular de um usuário, na mesma prioridade usada em
/// Profile.dart e EditarPerfil.dart: **preset escolhido > fotoUrl (upload
/// próprio ou login social) > avatar padrão** — ver
/// [chavePresetParaExibir].
///
/// Existe pra lista de usuários do Painel ADM não repetir esse encadeamento
/// de três casos em cada lugar que precisa desenhar um avatar.
class AvatarUsuario extends StatelessWidget {
  final UserModel usuario;
  final double tamanho;

  const AvatarUsuario({super.key, required this.usuario, this.tamanho = 44});

  @override
  Widget build(BuildContext context) {
    final chavePreset = chavePresetParaExibir(
      avatarPreset: usuario.avatarPreset,
      fotoUrl: usuario.fotoUrl,
    );
    final assetPreset = assetDoAvatarPreset(chavePreset);

    return Container(
      width: tamanho,
      height: tamanho,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AuthTheme.buttonGradient),
      child: ClipOval(
        child: assetPreset != null
            ? Image.asset(assetPreset, fit: BoxFit.cover)
            : usuario.fotoUrl.isNotEmpty
                // A foto do login com Google só aparece na Web por causa do
                // fallback pra <img> que o FotoPerfilRede faz.
                ? FotoPerfilRede(url: usuario.fotoUrl, iconeErroSize: tamanho * .5)
                : Image.asset(assetDoAvatarPreset(avatarPresetPadrao)!, fit: BoxFit.cover),
      ),
    );
  }
}
