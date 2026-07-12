import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
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
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando = false;

  Future<void> _criarConta() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (nickname.isEmpty || email.isEmpty || senha.isEmpty) {
      mostrarErroCustom(context, title: "Ops!", msg: "Preencha todos os campos.");
      return;
    }

    if (nickname.contains('@')) {
      mostrarErroCustom(context, title: "Ops!", msg: "O nickname não pode conter @.");
      return;
    }

    if (senha.length < 6) {
      mostrarErroCustom(context, title: "Ops!", msg: "A senha precisa ter pelo menos 6 caracteres.");
      return;
    }

    if (senha != confirmarSenha) {
      mostrarErroCustom(context, title: "Ops!", msg: "As senhas não coincidem.");
      return;
    }

    setState(() => _carregando = true);

    final erro = await widget.authViewModel.cadastrar(nickname: nickname, email: email, senha: senha);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erro);
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
                            'CRIE SUA CONTA',
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
                                  hint: 'Digite seu email',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                CampoTexto(
                                  isDark: isDark,
                                  label: 'Senha',
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
                                  label: 'Confirmar senha',
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
                                BotaoPrimario(label: 'Criar conta', carregando: _carregando, onTap: _criarConta),
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
                                          const TextSpan(text: 'Já tem uma conta? '),
                                          TextSpan(
                                            text: 'Fazer login',
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
