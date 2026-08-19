import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/AuthTheme.dart';
import '../utils/ThemeController.dart';

/// Widgets e icones compartilhados entre as telas de auth (Login/Cadastro),
/// pra manter o mesmo padrao visual sem duplicar codigo.

const String iconPessoa =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><circle cx="12" cy="8" r="4" fill="#8a2bd0"/><path d="M4 20c0-4 3.6-6 8-6s8 2 8 6" fill="#8a2bd0"/></svg>';
const String iconSenha =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><rect x="5" y="10" width="14" height="10" rx="2.5" fill="#8a2bd0"/><path d="M8 10V7a4 4 0 018 0v3" stroke="#8a2bd0" stroke-width="2.2" fill="none"/></svg>';
const String iconOlho =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><path d="M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5S2 12 2 12z" stroke="#b9bfc9" stroke-width="1.8" fill="none"/><circle cx="12" cy="12" r="2.6" fill="#b9bfc9"/></svg>';
/// Variante "riscada" do [iconOlho], usada quando a senha esta oculta.
const String iconOlhoFechado =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><path d="M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5S2 12 2 12z" stroke="#b9bfc9" stroke-width="1.8" fill="none"/><circle cx="12" cy="12" r="2.6" fill="#b9bfc9"/><line x1="3.5" y1="20.5" x2="20.5" y2="3.5" stroke="#b9bfc9" stroke-width="1.8" stroke-linecap="round"/></svg>';
const String iconEmail =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><rect x="3" y="5" width="18" height="14" rx="2.5" stroke="#8a2bd0" stroke-width="2"/><path d="M4 6.5l8 6 8-6" stroke="#8a2bd0" stroke-width="2" fill="none"/></svg>';
const String iconTelefone =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><path d="M6.6 3.5c.6-.2 1.2 0 1.5.5l1.6 2.7c.3.5.2 1.1-.2 1.5L8 9.7c.8 2 2.3 3.5 4.3 4.3l1.5-1.5c.4-.4 1-.5 1.5-.2l2.7 1.6c.5.3.7.9.5 1.5l-.7 2c-.2.6-.8 1-1.5 1-7 0-12.7-5.7-12.7-12.7 0-.7.4-1.3 1-1.5l2-.7z" fill="#8a2bd0"/></svg>';

class LogoPTK extends StatelessWidget {
  final double size;
  const LogoPTK({super.key, this.size = 132});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.038),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.257),
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
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset('assets/login_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

class BotaoTema extends StatelessWidget {
  final bool isDark;
  const BotaoTema({super.key, required this.isDark});

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

/// Botao circular de voltar, no mesmo padrao visual do BotaoTema (fundo
/// opaco branco + icone colorido). Extraido daqui em vez de duplicado em
/// cada tela (EditarPerfil.dart, Conquistas.dart), pra qualquer ajuste
/// visual futuro valer pra todas de uma vez. onTap e obrigatorio (passe
/// `() => Navigator.of(context).pop()` pro caso comum, ou null pra
/// desabilitar o botao enquanto uma acao esta carregando).
class BotaoVoltar extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  const BotaoVoltar({super.key, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class CardVidro extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const CardVidro({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      // A sombra precisa ficar fora do ClipRRect: se estivesse na decoration
      // clipada, o proprio clip corta o BoxShadow (que se espalha alem dos
      // limites do card) e a sombra nunca aparece.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x661E0046), blurRadius: 60, offset: Offset(0, 30)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
            decoration: BoxDecoration(
              color: isDark ? AuthTheme.cardBgDark : AuthTheme.cardBgLight,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: isDark ? AuthTheme.cardBorderDark : AuthTheme.cardBorderLight),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  final bool isDark;
  final String label;
  final TextEditingController controller;
  final String icone;
  final String hint;
  final bool obscure;
  final bool readOnly;
  final Widget? iconeFinal;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CampoTexto({
    super.key,
    required this.isDark,
    required this.label,
    required this.controller,
    required this.icone,
    required this.hint,
    this.obscure = false,
    this.readOnly = false,
    this.iconeFinal,
    this.keyboardType,
    this.inputFormatters,
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
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: readOnly ? AuthTheme.placeholderColor : AuthTheme.inputTextColor,
                  ),
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

/// Image.network com feedback de carregamento (spinner) e de erro (icone de
/// pessoa), usado nas fotos de perfil (Profile.dart, EditarPerfil.dart).
/// Sem isso, uma foto que ainda esta carregando ou que falha em carregar
/// (ex: bucket do Firebase Storage sem CORS liberado pra Web) fica um
/// circulo em branco, sem nenhuma pista do que aconteceu.
class FotoPerfilRede extends StatelessWidget {
  final String url;
  final double iconeErroSize;
  const FotoPerfilRede({super.key, required this.url, this.iconeErroSize = 48});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progresso) {
        if (progresso == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.white, size: iconeErroSize),
    );
  }
}

class BotaoPrimario extends StatelessWidget {
  final String label;
  final bool carregando;
  final VoidCallback onTap;
  const BotaoPrimario({super.key, required this.label, required this.carregando, required this.onTap});

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
                label,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .5, color: Colors.white),
              ),
      ),
    );
  }
}
