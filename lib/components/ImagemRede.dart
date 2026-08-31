import 'package:flutter/material.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

/// Imagem vinda da internet com o que o `Image.network` cru não dá:
/// carregamento por `<img>` quando o normal falha na Web, spinner enquanto
/// carrega, uma segunda URL pra tentar, e um placeholder no lugar do
/// quadrado cinza anônimo.
///
/// **Por que `webHtmlElementStrategy`**: na Web, o Flutter carrega imagem
/// baixando os bytes por XHR e decodificando — o que exige CORS. As
/// miniaturas do YouTube (`i.ytimg.com`) abrem numa aba do navegador mas
/// falham por esse caminho, e era isso que deixava os cards de vídeo e de
/// live com um quadrado cinza. Com `fallback`, quando o download de bytes
/// falha o Flutter monta um `<img>` de verdade — exatamente o que a aba do
/// navegador faz, e que comprovadamente funciona. Em Android/iOS o
/// parâmetro é ignorado.
///
/// O endereço alternativo é a linha de defesa seguinte, pra quando a URL em
/// si não responde: `img.youtube.com` serve exatamente a mesma miniatura
/// que `i.ytimg.com`, por outro domínio.
class ImagemRede extends StatelessWidget {
  final String url;
  final String? urlAlternativa;
  final bool isDark;
  final double? altura;
  final double? largura;
  final BoxFit fit;

  const ImagemRede({
    super.key,
    required this.url,
    required this.isDark,
    this.urlAlternativa,
    this.altura,
    this.largura,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) => _tentar(url, urlAlternativa);

  /// Encadeia as tentativas: o `errorBuilder` da primeira monta a segunda,
  /// e o da segunda cai no placeholder. Sem estado nenhum — cada tentativa
  /// é só um widget aninhado.
  Widget _tentar(String endereco, String? proximo) {
    return Image.network(
      endereco,
      height: altura,
      width: largura,
      fit: fit,
      // Só entra em ação na Web, e só se o caminho normal falhar.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, filho, progresso) {
        if (progresso == null) return filho;
        return _moldura(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
              value: progresso.expectedTotalBytes != null
                  ? progresso.cumulativeBytesLoaded / progresso.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, erro, pilha) {
        if (proximo != null) return _tentar(proximo, null);
        return _moldura(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 34),
        );
      },
    );
  }

  Widget _moldura({required Widget child}) {
    return Container(
      height: altura,
      width: largura,
      color: Colors.grey.shade800,
      child: Center(child: child),
    );
  }
}
