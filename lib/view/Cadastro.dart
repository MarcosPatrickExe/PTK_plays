import 'package:flutter/material.dart';
import '../i18n/Idioma.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/components/SeletorAvatarPreset.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/MascaraTelefoneWhatsapp.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'Home.dart';

class Cadastro extends StatefulWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKey;
  final AuthViewModel authViewModel;

  const Cadastro({
    super.key,
    required this.viewmodelYT,
    required this.apiKey,
    required this.authViewModel,
  });

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando = false;
  String? _avatarPresetSelecionado;

  @override
  void initState() {
    super.initState();
    _telefoneController.text = MascaraTelefoneWhatsapp.mascaraVazia;
  }

  Future<void> _criarConta() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final telefoneWhatsapp = _telefoneController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (nickname.isEmpty || email.isEmpty || senha.isEmpty) {
      mostrarErroCustom(context, title: textos.ops, msg: textos.validaPreenchaTudo);
      return;
    }

    if (nickname.contains('@')) {
      mostrarErroCustom(context, title: textos.ops, msg: textos.validaNickComArrobaAntigo);
      return;
    }

    final erroAvatar = validarAvatarPreset(_avatarPresetSelecionado);
    if (erroAvatar != null) {
      mostrarErroCustom(context, title: textos.ops, msg: erroAvatar);
      return;
    }

    final erroTelefone = validarTelefoneWhatsapp(telefoneWhatsapp);
    if (erroTelefone != null) {
      mostrarErroCustom(context, title: textos.ops, msg: erroTelefone);
      return;
    }

    if (senha.length < 6) {
      mostrarErroCustom(context, title: textos.ops, msg: textos.erroSenhaFraca);
      return;
    }

    if (senha != confirmarSenha) {
      mostrarErroCustom(context, title: textos.ops, msg: textos.validaSenhasDiferentes);
      return;
    }

    setState(() => _carregando = true);

    final erro = await widget.authViewModel.cadastrar(
      nickname: nickname,
      email: email,
      senha: senha,
      telefoneWhatsapp: MascaraTelefoneWhatsapp.paraSalvar(telefoneWhatsapp),
      avatarPreset: _avatarPresetSelecionado!,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      mostrarErroCustom(context, title: textos.ops, msg: erro);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(viewmodelYT: widget.viewmodelYT, apiKEY: widget.apiKey, authViewModel: widget.authViewModel),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
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
                          // Logo menor aqui, de proposito: sinaliza que o
                          // usuario saiu do Login e esta numa tela diferente.
                          const LogoPTK(size: 80),
                          const SizedBox(height: 16),
                          Text(
                            'PTK Plays',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .3,
                              color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            textos.cadastroAntigoTitulo,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                            ),
                          ),
                          const SizedBox(height: 30),
                          CardVidro(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                                  child: Text(
                                    textos.cadastroEscolhaAvatar,
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
                          const SizedBox(height: 16),
                          CardVidro(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CampoTexto(
                                  isDark: isDark,
                                  label: textos.nickname,
                                  controller: _nicknameController,
                                  icone: iconPessoa,
                                  hint: textos.perfilComoQuerSerChamado,
                                ),
                                const SizedBox(height: 16),
                                CampoTexto(
                                  isDark: isDark,
                                  label: textos.email,
                                  controller: _emailController,
                                  icone: iconEmail,
                                  hint: textos.cadastroDigiteEmail,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                CampoTexto(
                                  isDark: isDark,
                                  label: textos.perfilWhatsappOpcional,
                                  controller: _telefoneController,
                                  icone: iconTelefone,
                                  hint: MascaraTelefoneWhatsapp.mascaraVazia,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [MascaraTelefoneWhatsapp()],
                                ),
                                const SizedBox(height: 16),
                                CampoTexto(
                                  isDark: isDark,
                                  label: textos.senha,
                                  controller: _senhaController,
                                  icone: iconSenha,
                                  hint: '••••••••',
                                  obscure: !_senhaVisivel,
                                  iconeFinal: GestureDetector(
                                    onTap: () => setState(() => _senhaVisivel = !_senhaVisivel),
                                    child: SvgPicture.string(_senhaVisivel ? iconOlho : iconOlhoFechado, width: 20, height: 20),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CampoTexto(
                                  isDark: isDark,
                                  label: textos.perfilConfirmarNovaSenha,
                                  controller: _confirmarSenhaController,
                                  icone: iconSenha,
                                  hint: '••••••••',
                                  obscure: !_confirmarSenhaVisivel,
                                  iconeFinal: GestureDetector(
                                    onTap: () => setState(() => _confirmarSenhaVisivel = !_confirmarSenhaVisivel),
                                    child: SvgPicture.string(_confirmarSenhaVisivel ? iconOlho : iconOlhoFechado, width: 20, height: 20),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                BotaoPrimario(label: textos.criarConta, carregando: _carregando, onTap: _criarConta),
                                const SizedBox(height: 20),
                                Center(
                                  child: GestureDetector(
                                    onTap: _carregando ? null : () => Navigator.of(context).pop(),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AuthTheme.registerDark : AuthTheme.registerLight,
                                        ),
                                        children: [
                                          TextSpan(text: textos.cadastroJaTemConta),
                                          TextSpan(
                                            text: textos.cadastroFazerLogin,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
