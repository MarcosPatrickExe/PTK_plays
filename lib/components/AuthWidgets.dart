import 'dart:ui';
import 'package:flutter/material.dart';
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
const String iconEmail =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"><rect x="3" y="5" width="18" height="14" rx="2.5" stroke="#8a2bd0" stroke-width="2"/><path d="M4 6.5l8 6 8-6" stroke="#8a2bd0" stroke-width="2" fill="none"/></svg>';

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
  final Widget? iconeFinal;
  final TextInputType? keyboardType;

  const CampoTexto({
    super.key,
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
