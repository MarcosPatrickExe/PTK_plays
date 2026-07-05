import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/AuthTheme.dart';

class _GamerSymbols {
  static const triangle =
      '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><polygon points="50,12 88,84 12,84" fill="none" stroke="black" stroke-width="7" stroke-linejoin="round"/></svg>';
  static const circle =
      '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="38" fill="none" stroke="black" stroke-width="7"/></svg>';
  static const square =
      '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><rect x="16" y="16" width="68" height="68" rx="12" fill="none" stroke="black" stroke-width="8"/></svg>';
  static const cross =
      '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><path d="M22 22 L78 78 M78 22 L22 78" stroke="black" stroke-width="9" stroke-linecap="round"/></svg>';
  static const diamond =
      '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><polygon points="50,10 90,50 50,90 10,50" fill="black"/></svg>';
  static const dpad =
      '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><rect x="40" y="10" width="20" height="80" rx="6" fill="black"/><rect x="10" y="40" width="80" height="20" rx="6" fill="black"/></svg>';
}

class _Floating extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double amplitude;

  const _Floating({required this.child, required this.duration, required this.amplitude});

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: widget.amplitude)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: widget.child,
    );
  }
}

Widget _symbol(String svg, {required double size, required Color color, double rotationDeg = 0}) {
  Widget icon = SvgPicture.string(
    svg,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );

  if (rotationDeg != 0) {
    icon = Transform.rotate(angle: rotationDeg * 3.1415926535 / 180, child: icon);
  }

  return icon;
}

Widget _blob({required double size, required Color color, required double blurSigma}) {
  return ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    ),
  );
}

/// Fundo decorativo das telas de auth: blobs desfocados + simbolos "gamer"
/// flutuando, traduzidos 1-pra-1 do design (Login PTK Plays - source.html).
class AuthBackground extends StatelessWidget {
  final bool isDark;

  const AuthBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mainColor = isDark ? AuthTheme.symMainDark : AuthTheme.symMainLight;
    final cyanColor = isDark ? AuthTheme.symCyanDark : AuthTheme.symCyanLight;
    final magColor = isDark ? AuthTheme.symMagDark : AuthTheme.symMagLight;

    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -110,
          child: _Floating(
            duration: const Duration(seconds: 9),
            amplitude: -18,
            child: _blob(size: 340, color: isDark ? AuthTheme.blob1Dark : AuthTheme.blob1Light, blurSigma: 6),
          ),
        ),
        Positioned(
          bottom: -110,
          left: -100,
          child: _Floating(
            duration: const Duration(seconds: 11),
            amplitude: 22,
            child: _blob(size: 300, color: isDark ? AuthTheme.blob2Dark : AuthTheme.blob2Light, blurSigma: 6),
          ),
        ),
        Positioned(
          top: 220,
          left: -70,
          child: _Floating(
            duration: const Duration(seconds: 13),
            amplitude: -18,
            child: _blob(size: 180, color: isDark ? AuthTheme.blob3Dark : AuthTheme.blob3Light, blurSigma: 4),
          ),
        ),
        Positioned(
          left: 40,
          top: 66,
          child: _Floating(
            duration: const Duration(seconds: 8),
            amplitude: -18,
            child: _symbol(_GamerSymbols.triangle, size: 54, color: cyanColor, rotationDeg: -6),
          ),
        ),
        Positioned(
          right: 34,
          top: 390,
          child: _Floating(
            duration: const Duration(seconds: 7),
            amplitude: -14,
            child: _symbol(_GamerSymbols.circle, size: 46, color: magColor),
          ),
        ),
        Positioned(
          left: 292,
          top: 34,
          child: _Floating(
            duration: const Duration(seconds: 10),
            amplitude: 22,
            child: _symbol(_GamerSymbols.square, size: 34, color: mainColor, rotationDeg: 12),
          ),
        ),
        Positioned(
          left: 150,
          top: 150,
          child: _Floating(
            duration: const Duration(seconds: 9),
            amplitude: 16,
            child: _symbol(_GamerSymbols.cross, size: 30, color: mainColor),
          ),
        ),
        Positioned(
          right: 40,
          top: 246,
          child: _Floating(
            duration: const Duration(seconds: 12),
            amplitude: -18,
            child: _symbol(_GamerSymbols.diamond, size: 22, color: mainColor),
          ),
        ),
        Positioned(
          left: 52,
          top: 300,
          child: _Floating(
            duration: const Duration(seconds: 11),
            amplitude: -14,
            child: _symbol(_GamerSymbols.dpad, size: 42, color: mainColor, rotationDeg: -8),
          ),
        ),
        Positioned(
          left: 250,
          top: 246,
          child: _Floating(
            duration: const Duration(seconds: 9),
            amplitude: 22,
            child: _symbol(_GamerSymbols.triangle, size: 26, color: mainColor, rotationDeg: 18),
          ),
        ),
        Positioned(
          left: 26,
          top: 486,
          child: _Floating(
            duration: const Duration(seconds: 10),
            amplitude: 16,
            child: _symbol(_GamerSymbols.circle, size: 30, color: mainColor),
          ),
        ),
        Positioned(
          right: 26,
          top: 520,
          child: _Floating(
            duration: const Duration(seconds: 11),
            amplitude: -18,
            child: _symbol(_GamerSymbols.square, size: 28, color: mainColor, rotationDeg: -10),
          ),
        ),
        Positioned(
          right: 44,
          top: 700,
          child: _Floating(
            duration: const Duration(seconds: 8),
            amplitude: -14,
            child: _symbol(_GamerSymbols.cross, size: 34, color: cyanColor),
          ),
        ),
        Positioned(
          left: 28,
          top: 726,
          child: _Floating(
            duration: const Duration(seconds: 12),
            amplitude: 22,
            child: _symbol(_GamerSymbols.triangle, size: 46, color: mainColor, rotationDeg: 8),
          ),
        ),
        Positioned(
          right: 96,
          top: 858,
          child: _Floating(
            duration: const Duration(seconds: 9),
            amplitude: 16,
            child: _symbol(_GamerSymbols.dpad, size: 36, color: mainColor, rotationDeg: 10),
          ),
        ),
        Positioned(
          left: 118,
          top: 884,
          child: _Floating(
            duration: const Duration(seconds: 10),
            amplitude: -18,
            child: _symbol(_GamerSymbols.circle, size: 40, color: magColor),
          ),
        ),
        Positioned(
          left: 300,
          top: 636,
          child: _Floating(
            duration: const Duration(seconds: 13),
            amplitude: -14,
            child: _symbol(_GamerSymbols.diamond, size: 20, color: mainColor),
          ),
        ),
      ],
    );
  }
}
