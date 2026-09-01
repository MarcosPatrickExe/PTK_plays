import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:video_player/video_player.dart';

/// Vídeo anexado a um post do feed, tocado dentro do próprio card.
///
/// Começa parado num quadro do vídeo com o botão de play por cima (não
/// autoplay: o feed pode ter vários cards e nenhum deles deve começar a
/// consumir dados sozinho). O controle é só toque pra dar play/pausa, mais
/// a barra de progresso.
///
/// Se a inicialização falhar — sem rede, formato que o aparelho não toca,
/// ou o plugin indisponível (é o caso dos testes de widget, que rodam sem
/// plataforma nativa) — o card mostra um aviso no lugar, em vez de ficar
/// preso no indicador de carregamento.
class VideoPost extends StatefulWidget {
  final String url;
  final bool isDark;

  const VideoPost({super.key, required this.url, required this.isDark});

  @override
  State<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  VideoPlayerController? _controlador;
  bool _pronto = false;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  Future<void> _preparar() async {
    final controlador = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controlador = controlador;

    try {
      await controlador.initialize();
      if (!mounted) return;
      setState(() => _pronto = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _falhou = true);
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  void _alternarPlay() {
    final controlador = _controlador;
    if (controlador == null || !_pronto) return;

    setState(() {
      controlador.value.isPlaying ? controlador.pause() : controlador.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_falhou) return _moldura(child: _avisoDeFalha());

    final controlador = _controlador;
    if (!_pronto || controlador == null) {
      return _moldura(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controlador.value.aspectRatio,
      child: GestureDetector(
        onTap: _alternarPlay,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controlador),
            if (!controlador.value.isPlaying)
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controlador,
                allowScrubbing: true,
                colors: const VideoProgressColors(playedColor: Color(0xFFA12EE0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avisoDeFalha() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 32),
        const SizedBox(height: 6),
        Text(
          'Não foi possível carregar o vídeo.',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _moldura({required Widget child}) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(color: Colors.grey.shade800, child: Center(child: child)),
    );
  }
}
