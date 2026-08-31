import 'package:flutter/material.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

/// Imagem vinda da internet com três coisas que o `Image.network` cru não
/// dá: spinner enquanto carrega, uma segunda URL pra tentar quando a
/// primeira falha, e um placeholder no lugar do quadrado cinza anônimo.
///
/// O endereço alternativo existe por um motivo concreto: as miniaturas do
/// YouTube ficam em `i.ytimg.com`, um domínio que extensão de bloqueio de
/// anúncio/rastreamento e alguns provedores derrubam. `img.youtube.com`
/// serve exatamente a mesma imagem por outro domínio, então quando a
/// primeira falha a segunda costuma passar. Se as duas falharem, aí é
/// bloqueio do navegador/rede mesmo — e o placeholder diz isso, em vez de
/// parecer um bug do app.
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
