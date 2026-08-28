import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/DegradeTopo.dart';
import 'package:ptk_plays/components/ModalCropFoto.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/components/SeletorAvatarPreset.dart';
import 'package:ptk_plays/components/Toast.dart';
import 'package:ptk_plays/data/models/AvatarPreset.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/MascaraTelefoneWhatsapp.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';

class EditarPerfil extends StatefulWidget {
  final UserModel usuario;
  final AuthViewModel authViewModel;

  const EditarPerfil({super.key, required this.usuario, required this.authViewModel});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  late final _nicknameController = TextEditingController(text: widget.usuario.nickname);
  late final _emailController = TextEditingController(text: widget.usuario.email);
  late final _telefoneController = TextEditingController(
    text: MascaraTelefoneWhatsapp.aplicarEm(widget.usuario.telefoneWhatsapp),
  );
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();
  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;

  late String? _avatarPresetSelecionado = () {
    final chave = chavePresetParaExibir(avatarPreset: widget.usuario.avatarPreset, fotoUrl: widget.usuario.fotoUrl);
    return chave.isEmpty ? null : chave;
  }();
  late String _fotoUrl = widget.usuario.fotoUrl;
  bool _enviandoFoto = false;
  bool _enviandoEmailSenha = false;
  bool _carregando = false;

  Future<void> _escolherEEditarFoto() async {
    final arquivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);
    if (arquivo == null || !mounted) return;

    final bytesOriginais = await arquivo.readAsBytes();
    if (!mounted) return;

    final bytesRecortados = await ModalCropFoto.abrir(context, bytesOriginais);
    if (bytesRecortados == null || !mounted) return;

    setState(() => _enviandoFoto = true);

    final resultado = await widget.authViewModel.atualizarFotoPerfil(bytes: bytesRecortados);

    if (!mounted) return;
    setState(() => _enviandoFoto = false);

    if (resultado.erro != null) {
      mostrarToast(context, mensagem: resultado.erro!, erro: true);
      return;
    }

    // A foto enviada passa a ser o avatar ativo (ver
    // AvatarPreset.chavePresetParaExibir: preset tem prioridade sobre
    // fotoUrl), entao limpa a selecao do grid de presets junto.
    setState(() {
      _fotoUrl = resultado.url!;
      _avatarPresetSelecionado = null;
    });
    mostrarToast(context, mensagem: 'Foto de perfil atualizada!');
  }

  Future<void> _enviarEmailRedefinicaoSenha() async {
    setState(() => _enviandoEmailSenha = true);

    final erro = await widget.authViewModel.enviarEmailRedefinicaoSenha(email: widget.usuario.email);

    if (!mounted) return;
    setState(() => _enviandoEmailSenha = false);

    mostrarToast(
      context,
      mensagem: erro ?? 'Enviamos um link pro seu e-mail (${widget.usuario.email}) pra redefinir a senha.',
      erro: erro != null,
    );
  }

  Future<void> _salvar() async {
    final novoNickname = _nicknameController.text.trim();
    final telefoneWhatsapp = _telefoneController.text.trim();

    final erroNickname = validarNickname(novoNickname);
    if (erroNickname != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erroNickname);
      return;
    }

    final erroTelefone = validarTelefoneWhatsapp(telefoneWhatsapp);
    if (erroTelefone != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erroTelefone);
      return;
    }

    final erroSenha = validarTrocaSenha(
      senhaAtual: _senhaAtualController.text,
      novaSenha: _novaSenhaController.text,
      confirmarNovaSenha: _confirmarNovaSenhaController.text,
    );
    if (erroSenha != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erroSenha);
      return;
    }

    setState(() => _carregando = true);

    if (_senhaAtualController.text.isNotEmpty) {
      final erroTrocaSenha = await widget.authViewModel.alterarSenha(
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
      );

      if (!mounted) return;
      if (erroTrocaSenha != null) {
        setState(() => _carregando = false);
        mostrarToast(context, mensagem: erroTrocaSenha, erro: true);
        return;
      }
    }

    final erro = await widget.authViewModel.atualizarPerfil(
      nicknameAtual: widget.usuario.nickname,
      novoNickname: novoNickname,
      telefoneWhatsapp: MascaraTelefoneWhatsapp.paraSalvar(telefoneWhatsapp),
      avatarPreset: _avatarPresetSelecionado ?? '',
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      mostrarToast(context, mensagem: erro, erro: true);
      return;
    }

    mostrarToast(context, mensagem: 'Perfil salvo com sucesso!');
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight),
        child: Stack(
          children: [
            Positioned.fill(child: AuthBackground(isDark: isDark)),
            const DegradeTopo(),
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      child: ResponsiveMaxWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 44),
                            Text(
                              'Editar perfil',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .3,
                                color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _FotoPerfilEditavel(
                              fotoUrl: _fotoUrl,
                              avatarPreset: _avatarPresetSelecionado,
                              enviando: _enviandoFoto,
                              onTap: _carregando || _enviandoFoto ? null : _escolherEEditarFoto,
                            ),
                            const SizedBox(height: 24),
                            CardVidro(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CampoTexto(
                                    isDark: isDark,
                                    label: 'Nickname',
                                    controller: _nicknameController,
                                    icone: iconPessoa,
                                    hint: 'Como quer ser chamado',
                                  ),
                                  const SizedBox(height: 16),
                                  CampoTexto(
                                    isDark: isDark,
                                    label: 'Email',
                                    controller: _emailController,
                                    icone: iconEmail,
                                    hint: '',
                                    readOnly: true,
                                  ),
                                  const SizedBox(height: 16),
                                  CampoTexto(
                                    isDark: isDark,
                                    label: 'WhatsApp (opcional)',
                                    controller: _telefoneController,
                                    icone: iconTelefone,
                                    hint: MascaraTelefoneWhatsapp.mascaraVazia,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [MascaraTelefoneWhatsapp()],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Secao separada da acima (dados da conta): foto
                            // de perfil e uma categoria de dado diferente,
                            // por pedido explicito de manter a organizacao
                            // visual entre os tipos de informacao na tela.
                            CardVidro(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                                    child: Text(
                                      'Foto de perfil',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: .5,
                                        color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
                                      ),
                                    ),
                                  ),
                                  SeletorAvatarPreset(
                                    isDark: isDark,
                                    selecionado: _avatarPresetSelecionado,
                                    onSelecionar: (chave) => setState(() => _avatarPresetSelecionado = chave),
                                  ),
                                ],
                              ),
                            ),
                            // So mostra a troca de senha pra contas com
                            // provider de email/senha: contas so-Google/
                            // so-Apple nao tem senha do PTK Plays pra trocar
                            // por aqui.
                            if (widget.authViewModel.temSenhaEmail) ...[
                              const SizedBox(height: 16),
                              CardVidro(
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                                      child: Text(
                                        'Alterar senha (opcional)',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: .5,
                                          color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
                                        ),
                                      ),
                                    ),
                                    CampoTexto(
                                      isDark: isDark,
                                      label: 'Senha atual',
                                      controller: _senhaAtualController,
                                      icone: iconSenha,
                                      hint: '••••••••',
                                      obscure: !_senhaAtualVisivel,
                                      iconeFinal: GestureDetector(
                                        onTap: () => setState(() => _senhaAtualVisivel = !_senhaAtualVisivel),
                                        child: SvgPicture.string(_senhaAtualVisivel ? iconOlho : iconOlhoFechado, width: 20, height: 20),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CampoTexto(
                                      isDark: isDark,
                                      label: 'Nova senha',
                                      controller: _novaSenhaController,
                                      icone: iconSenha,
                                      hint: '••••••••',
                                      obscure: !_novaSenhaVisivel,
                                      iconeFinal: GestureDetector(
                                        onTap: () => setState(() => _novaSenhaVisivel = !_novaSenhaVisivel),
                                        child: SvgPicture.string(_novaSenhaVisivel ? iconOlho : iconOlhoFechado, width: 20, height: 20),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CampoTexto(
                                      isDark: isDark,
                                      label: 'Confirmar nova senha',
                                      controller: _confirmarNovaSenhaController,
                                      icone: iconSenha,
                                      hint: '••••••••',
                                      obscure: !_novaSenhaVisivel,
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: GestureDetector(
                                        onTap: _enviandoEmailSenha ? null : _enviarEmailRedefinicaoSenha,
                                        child: _enviandoEmailSenha
                                            ? SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
                                                ),
                                              )
                                            : Text(
                                                'Esqueceu sua senha atual? Enviar link por e-mail',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            BotaoPrimario(label: 'Salvar alterações', carregando: _carregando, onTap: _salvar),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: BotaoVoltar(
                        isDark: isDark,
                        onTap: _carregando ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: BotaoTema(isDark: isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto de perfil no topo da tela, com um botao de lapis sobreposto pra
/// trocar por upload proprio (recorte/zoom em ModalCropFoto). Segue a mesma
/// prioridade de Profile.dart (preset escolhido > fotoUrl > avatar padrao —
/// ver AvatarPreset.chavePresetParaExibir), pra sempre bater com o que a
/// grade de presets logo abaixo mostra selecionado.
class _FotoPerfilEditavel extends StatelessWidget {
  final String fotoUrl;
  final String? avatarPreset;
  final bool enviando;
  final VoidCallback? onTap;

  const _FotoPerfilEditavel({
    required this.fotoUrl,
    required this.avatarPreset,
    required this.enviando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPreset = assetDoAvatarPreset(avatarPreset ?? '');

    return Center(
      child: SizedBox(
        width: 116,
        height: 116,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AuthTheme.buttonGradient),
              child: assetPreset != null
                  ? ClipOval(child: Image.asset(assetPreset, fit: BoxFit.cover))
                  : fotoUrl.isNotEmpty
                      ? ClipOval(child: FotoPerfilRede(url: fotoUrl, iconeErroSize: 40))
                      : ClipOval(child: Image.asset(assetDoAvatarPreset(avatarPresetPadrao)!, fit: BoxFit.cover)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AuthTheme.buttonGradient,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: enviando
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.edit, color: Colors.white, size: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
