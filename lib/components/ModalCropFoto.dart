import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AuthWidgets.dart';

/// Modal fullscreen pra cortar (crop) e dar zoom numa imagem antes de usar
/// como foto de perfil (ver EditarPerfil.dart). Devolve os bytes PNG ja
/// recortados (area quadrada de [_tamanhoRecorte] px, exibida em circulo)
/// via Navigator.pop, ou null se o usuario cancelar.
class ModalCropFoto extends StatefulWidget {
  final Uint8List imagemOriginal;
  const ModalCropFoto({super.key, required this.imagemOriginal});

  static Future<Uint8List?> abrir(BuildContext context, Uint8List imagemOriginal) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ModalCropFoto(imagemOriginal: imagemOriginal),
      ),
    );
  }

  @override
  State<ModalCropFoto> createState() => _ModalCropFotoState();
}

class _ModalCropFotoState extends State<ModalCropFoto> {
  static const double _tamanhoRecorte = 280;
  static const double _escalaMinima = 1;
  static const double _escalaMaxima = 4;

  final _boundaryKey = GlobalKey();
  final _transformController = TransformationController();
  double _escalaAtual = _escalaMinima;
  bool _salvando = false;

  // Zoom via botoes +/-, centralizado no meio do recorte (em vez de so
  // pinca-pra-zoom, que nem todo mundo descobre sozinho).
  void _zoom(double fator) {
    final novaEscala = (_escalaAtual * fator).clamp(_escalaMinima, _escalaMaxima);
    if (novaEscala == _escalaAtual) return;

    const centro = Offset(_tamanhoRecorte / 2, _tamanhoRecorte / 2);
    final relativo = novaEscala / _escalaAtual;
    final matriz = _transformController.value.clone()
      ..translateByDouble(centro.dx, centro.dy, 0, 1)
      ..scaleByDouble(relativo, relativo, relativo, 1)
      ..translateByDouble(-centro.dx, -centro.dy, 0, 1);

    setState(() {
      _escalaAtual = novaEscala;
      _transformController.value = matriz;
    });
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      // Captura exatamente o que esta renderizado dentro do RepaintBoundary
      // (a area do recorte, ja com o pan/zoom aplicado pelo InteractiveViewer).
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final imagem = await boundary.toImage(pixelRatio: 3);
      final byteData = await imagem.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop(byteData!.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Ajustar foto', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _salvando ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: SizedBox(
                          width: _tamanhoRecorte,
                          height: _tamanhoRecorte,
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: _escalaMinima,
                            maxScale: _escalaMaxima,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            onInteractionUpdate: (_) =>
                                _escalaAtual = _transformController.value.getMaxScaleOnAxis(),
                            child: Image.memory(
                              widget.imagemOriginal,
                              width: _tamanhoRecorte,
                              height: _tamanhoRecorte,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Guia visual do recorte circular, sem interceptar toque.
                    IgnorePointer(
                      child: Container(
                        width: _tamanhoRecorte,
                        height: _tamanhoRecorte,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BotaoZoom(icone: Icons.remove, onTap: () => _zoom(1 / 1.2)),
                  const SizedBox(width: 28),
                  Icon(Icons.zoom_in, color: Colors.white.withValues(alpha: .6)),
                  const SizedBox(width: 28),
                  _BotaoZoom(icone: Icons.add, onTap: () => _zoom(1.2)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: BotaoPrimario(label: 'Usar essa foto', carregando: _salvando, onTap: _salvar),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoZoom extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  const _BotaoZoom({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .12)),
        child: Icon(icone, color: Colors.white, size: 20),
      ),
    );
  }
}
