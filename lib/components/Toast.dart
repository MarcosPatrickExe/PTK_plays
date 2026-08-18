import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Feedback nao-bloqueante no topo da tela (Toast), que aparece e some
/// sozinho depois de alguns segundos — sem exigir toque do usuario pra
/// fechar. Padrao de feedback do app pro resultado de uma acao (salvar,
/// atualizar, etc.): ver a regra em CLAUDE.md.
void mostrarToast(BuildContext context, {required String mensagem, bool erro = false}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastWidget(mensagem: mensagem, erro: erro, onFechar: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String mensagem;
  final bool erro;
  final VoidCallback onFechar;
  const _ToastWidget({required this.mensagem, required this.erro, required this.onFechar});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _posicao;
  late final Timer _timerAutoFechar;
  bool _fechando = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _posicao = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Timer cancelavel (em vez de Future.delayed) pra nao deixar um callback
    // pendente depois que o widget for descartado (ex: usuario navegou pra
    // outra tela antes dos 3s passarem).
    _timerAutoFechar = Timer(const Duration(seconds: 3), _fechar);
  }

  Future<void> _fechar() async {
    if (_fechando || !mounted) return;
    _fechando = true;
    _timerAutoFechar.cancel();
    await _controller.reverse();
    widget.onFechar();
  }

  @override
  void dispose() {
    _timerAutoFechar.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _posicao,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _fechar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: widget.erro ? const Color(0xFFE0264F) : const Color(0xFF2CB67D),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.erro ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.mensagem,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
