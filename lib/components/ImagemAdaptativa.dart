import 'package:flutter/material.dart';
import 'package:ptk_plays/components/ImagemRede.dart';

/// Proporções limite do card de imagem do feed, no mesmo espírito do
/// Instagram: uma foto muito larga ou muito comprida não pode esticar o
/// card até quebrar a leitura do resto do post.
///
/// O limite de baixo é 9:16 (retrato de celular, o formato que mais aparece
/// postado do mobile) e não o 4:5 do Instagram — o pedido era o card
/// **acompanhar** a foto vertical, então uma 9:16 aparece inteira em vez de
/// ser cortada.
const double aspectoMinimoDoCard = 9 / 16;
const double aspectoMaximoDoCard = 1.91;

/// Proporção que o card deve usar pra uma imagem de [largura]x[altura].
/// Fica fora do widget porque é a única parte disso que dá pra testar sem
/// baixar imagem de verdade.
double aspectoDoCard(double largura, double altura) {
  if (largura <= 0 || altura <= 0) return 1;
  return (largura / altura).clamp(aspectoMinimoDoCard, aspectoMaximoDoCard);
}

/// Imagem de post que se adapta ao formato da foto: retrato, quadrada ou
/// paisagem, dentro dos limites acima.
///
/// A proporção real só é conhecida depois que a imagem carrega, então o
/// card começa quadrado e se ajusta quando as dimensões chegam. A medição é
/// feita num `ImageStream` separado do widget que desenha: quem desenha é o
/// [ImagemRede], que tem o caminho alternativo por `<img>` da Web — se a
/// medição falhar, a imagem ainda aparece, só que na proporção padrão.
class ImagemAdaptativa extends StatefulWidget {
  final String url;
  final bool isDark;

  const ImagemAdaptativa({super.key, required this.url, required this.isDark});

  @override
  State<ImagemAdaptativa> createState() => _ImagemAdaptativaState();
}

class _ImagemAdaptativaState extends State<ImagemAdaptativa> {
  double _aspecto = 1;
  ImageStream? _stream;
  ImageStreamListener? _ouvinte;

  @override
  void initState() {
    super.initState();
    _medir();
  }

  @override
  void didUpdateWidget(ImagemAdaptativa anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.url != widget.url) {
      _descartar();
      _aspecto = 1;
      _medir();
    }
  }

  void _medir() {
    final stream = NetworkImage(widget.url).resolve(const ImageConfiguration());
    final ouvinte = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _aspecto = aspectoDoCard(info.image.width.toDouble(), info.image.height.toDouble());
        });
      },
      // Sem proporção medida o card fica quadrado; o desenho em si é
      // problema do ImagemRede, que tem os próprios fallbacks.
      onError: (_, __) {},
    );

    stream.addListener(ouvinte);
    _stream = stream;
    _ouvinte = ouvinte;
  }

  void _descartar() {
    if (_stream != null && _ouvinte != null) _stream!.removeListener(_ouvinte!);
    _stream = null;
    _ouvinte = null;
  }

  @override
  void dispose() {
    _descartar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspecto,
      child: ImagemRede(url: widget.url, isDark: widget.isDark, largura: double.infinity),
    );
  }
}
