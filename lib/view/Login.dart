import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'Cadastro.dart';
import 'Home.dart';

const String _iconLogin =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><circle cx="12" cy="8" r="4" fill="#8a2bd0"/><path d="M4 20c0-4 3.6-6 8-6s8 2 8 6" fill="#8a2bd0"/></svg>';
const String _iconSenha =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><rect x="5" y="10" width="14" height="10" rx="2.5" fill="#8a2bd0"/><path d="M8 10V7a4 4 0 018 0v3" stroke="#8a2bd0" stroke-width="2.2" fill="none"/></svg>';
const String _iconOlho =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><path d="M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5S2 12 2 12z" stroke="#b9bfc9" stroke-width="1.8" fill="none"/><circle cx="12" cy="12" r="2.6" fill="#b9bfc9"/></svg>';
const String _iconGoogle = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
<path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9 3.6l6.7-6.7C35.6 2.4 30.1 0 24 0 14.6 0 6.4 5.4 2.5 13.2l7.8 6.1C12.2 13.3 17.6 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.1 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.4c-.5 2.9-2.1 5.3-4.6 7l7.1 5.5c4.2-3.9 6.6-9.6 6.6-16.3z"/>
<path fill="#FBBC05" d="M10.3 28.7c-.5-1.4-.8-2.9-.8-4.7s.3-3.3.8-4.7l-7.8-6.1C.9 16.5 0 20.1 0 24s.9 7.5 2.5 10.8l7.8-6.1z"/>
<path fill="#34A853" d="M24 48c6.1 0 11.3-2 15-5.5l-7.1-5.5c-2 1.4-4.6 2.2-7.9 2.2-6.4 0-11.8-3.8-13.7-9.3l-7.8 6.1C6.4 42.6 14.6 48 24 48z"/>
</svg>
''';

class Login extends StatefulWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKey;
  final AuthViewModel authViewModel;

  const Login({
    super.key,
    required this.viewmodelYT,
    required this.apiKey,
    required this.authViewModel,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      mostrarErroCustom(context, title: "Ops!", msg: "Preencha login e senha.");
      return;
    }

    setState(() => _carregando = true);

    final erro = await widget.authViewModel.login(email: email, senha: senha);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erro);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(viewmodelYT: widget.viewmodelYT, apiKEY: widget.apiKey),
      ),
    );
  }

  void _irParaCadastro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Cadastro(
          viewmodelYT: widget.viewmodelYT,
          apiKey: widget.apiKey,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
  }

  void _entrarComGoogle() {
    mostrarErroCustom(context, title: "Em breve!", msg: "O login com Google ainda está a caminho.");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(34),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(.9), Colors.white.withOpacity(.25)],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x73280050), blurRadius: 50, offset: Offset(0, 22)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(29),
                              child: Image.asset('assets/login_logo.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'PTK Plays',
                            style: GoogleFonts.outfit(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .3,
                              color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'FAÇA SEU LOGIN',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _CardVidro(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CampoTexto(
                                  isDark: isDark,
                                  label: 'Login',
                                  controller: _emailController,
                                  icone: _iconLogin,
                                  hint: 'Digite seu login',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _CampoTexto(
                                  isDark: isDark,
                                  label: 'Senha',
                                  controller: _senhaController,
                                  icone: _iconSenha,
                                  hint: '••••••••',
                                  obscure: !_senhaVisivel,
                                  iconeFinal: GestureDetector(
                                    onTap: () => setState(() => _senhaVisivel = !_senhaVisivel),
                                    child: SvgPicture.string(_iconOlho, width: 20, height: 20),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _BotaoEntrar(carregando: _carregando, onTap: _entrar),
                                const SizedBox(height: 20),
                                Center(
                                  child: GestureDetector(
                                    onTap: _carregando ? null : _irParaCadastro,
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AuthTheme.registerDark : AuthTheme.registerLight,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Não tem uma conta? '),
                                          TextSpan(
                                            text: 'Clique aqui!',
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
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: isDark ? AuthTheme.dividerDark : AuthTheme.dividerLight),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        'OU',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1,
                                          color: isDark ? AuthTheme.ouDark : AuthTheme.ouLight,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: isDark ? AuthTheme.dividerDark : AuthTheme.dividerLight),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _BotaoGoogle(isDark: isDark, onTap: _carregando ? null : _entrarComGoogle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: _BotaoTema(isDark: isDark),
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

class _BotaoTema extends StatelessWidget {
  final bool isDark;
  const _BotaoTema({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ThemeController>().toggleTheme(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isDark ? AuthTheme.themeBtnBgDark : AuthTheme.themeBtnBgLight,
          border: Border.all(color: isDark ? AuthTheme.themeBtnBorderDark : AuthTheme.themeBtnBorderLight),
        ),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? AuthTheme.themeIconDark : AuthTheme.themeIconLight,
          size: 23,
        ),
      ),
    );
  }
}

class _CardVidro extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _CardVidro({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
          decoration: BoxDecoration(
            color: isDark ? AuthTheme.cardBgDark : AuthTheme.cardBgLight,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: isDark ? AuthTheme.cardBorderDark : AuthTheme.cardBorderLight),
            boxShadow: const [
              BoxShadow(color: Color(0x661E0046), blurRadius: 60, offset: Offset(0, 30)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final bool isDark;
  final String label;
  final TextEditingController controller;
  final String icone;
  final String hint;
  final bool obscure;
  final Widget? iconeFinal;
  final TextInputType? keyboardType;

  const _CampoTexto({
    required this.isDark,
    required this.label,
    required this.controller,
    required this.icone,
    required this.hint,
    this.obscure = false,
    this.iconeFinal,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .5,
              color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
            ),
          ),
        ),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AuthTheme.inputBgDark : AuthTheme.inputBgLight,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(color: Color(0x1F1E0046), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.string(icone, width: 19, height: 19),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  style: GoogleFonts.outfit(fontSize: 15, color: AuthTheme.inputTextColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: hint,
                    hintStyle: TextStyle(color: AuthTheme.placeholderColor),
                  ),
                ),
              ),
              if (iconeFinal != null) iconeFinal!,
            ],
          ),
        ),
      ],
    );
  }
}

class _BotaoEntrar extends StatelessWidget {
  final bool carregando;
  final VoidCallback onTap;
  const _BotaoEntrar({required this.carregando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: carregando ? null : onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AuthTheme.buttonGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Color(0x66C828B4), blurRadius: 30, offset: Offset(0, 14)),
          ],
        ),
        child: carregando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Entrar',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .5, color: Colors.white),
              ),
      ),
    );
  }
}

class _BotaoGoogle extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  const _BotaoGoogle({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AuthTheme.googleBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? AuthTheme.googleBorderDark : AuthTheme.googleBorderLight),
          boxShadow: const [
            BoxShadow(color: Color(0x2E1E0046), blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_iconGoogle, width: 20, height: 20),
            const SizedBox(width: 12),
            Text(
              'Entrar com o Google',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AuthTheme.googleText),
            ),
          ],
        ),
      ),
    );
  }
}
