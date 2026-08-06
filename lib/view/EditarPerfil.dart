import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/components/Responsive.dart';
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
  late final _telefoneController = TextEditingController(
    text: MascaraTelefoneWhatsapp.aplicarEm(widget.usuario.telefoneWhatsapp),
  );
  bool _carregando = false;

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

    setState(() => _carregando = true);

    final erro = await widget.authViewModel.atualizarPerfil(
      nicknameAtual: widget.usuario.nickname,
      novoNickname: novoNickname,
      telefoneWhatsapp: MascaraTelefoneWhatsapp.paraSalvar(telefoneWhatsapp),
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erro);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _telefoneController.dispose();
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
                            const SizedBox(height: 30),
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
                                    label: 'WhatsApp (opcional)',
                                    controller: _telefoneController,
                                    icone: iconTelefone,
                                    hint: MascaraTelefoneWhatsapp.mascaraVazia,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [MascaraTelefoneWhatsapp()],
                                  ),
                                  const SizedBox(height: 22),
                                  BotaoPrimario(label: 'Salvar alterações', carregando: _carregando, onTap: _salvar),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: GestureDetector(
                        onTap: _carregando ? null : () => Navigator.of(context).pop(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? AuthTheme.themeBtnBgDark : AuthTheme.themeBtnBgLight,
                            border: Border.all(color: isDark ? AuthTheme.themeBtnBorderDark : AuthTheme.themeBtnBorderLight),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: isDark ? AuthTheme.themeIconDark : AuthTheme.themeIconLight,
                            size: 23,
                          ),
                        ),
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
