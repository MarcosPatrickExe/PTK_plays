import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptk_plays/components/AvatarUsuario.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/i18n/Idioma.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';

/// Quantas miniaturas cabem antes de virar "+N". Três é o que sobrevive à
/// tela estreita de celular sem espremer a contagem ao lado.
const int maximoDeMiniaturas = 3;

/// A barra de ações no pé do card do feed: curtir, e as miniaturas de quem
/// já curtiu.
///
/// **Por que as miniaturas existem.** Um número ("12 curtidas") diz que
/// houve interação; **rostos** dizem que houve gente. É a diferença entre
/// um app que parece um mural e um app que parece uma comunidade — e é o
/// que um avaliador de loja consegue enxergar em cinco segundos, sem
/// precisar criar conta e testar nada.
///
/// Comentar e compartilhar aparecem desabilitados, com "Em breve": o lugar
/// deles no layout já está reservado, e a pessoa vê pra onde o app está
/// indo. Esconder os dois faria a barra mudar de forma quando eles
/// chegarem.
class BarraDeCurtidas extends StatelessWidget {
  final bool isDark;

  /// Uids de quem curtiu. A contagem sai daqui — não há contador separado.
  final List<String> curtidoPor;

  /// Se a pessoa logada está entre eles. Decide o coração cheio ou vazio.
  final bool euCurti;

  /// Nulo quando ninguém está logado: aí o coração aparece, mas não
  /// responde ao toque.
  final VoidCallback? onCurtir;

  /// Carrega os perfis pras miniaturas. Recebido de fora (e não chamado
  /// direto no repositório) pra este widget continuar montável em teste,
  /// sem Firebase.
  final Future<List<UserModel>> Function(List<String> uids)? carregarPerfis;

  const BarraDeCurtidas({
    super.key,
    required this.isDark,
    required this.curtidoPor,
    required this.euCurti,
    this.onCurtir,
    this.carregarPerfis,
  });

  @override
  Widget build(BuildContext context) {
    final corApoio = isDark ? AuthTheme.subDark : AuthTheme.subLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: .08)),
        const SizedBox(height: 4),
        Row(
          children: [
            _BotaoDeAcao(
              icone: euCurti ? Icons.favorite : Icons.favorite_border,
              rotulo: euCurti ? textos.feedDescurtir : textos.feedCurtir,
              // O vermelho só aparece depois do toque. Antes dele o ícone
              // fica na cor de apoio, senão o card parece já curtido.
              cor: euCurti ? const Color(0xFFE0264F) : corApoio,
              onTocar: onCurtir,
            ),
            _BotaoDeAcao(
              icone: Icons.mode_comment_outlined,
              rotulo: textos.feedComentar,
              cor: corApoio,
              onTocar: null,
              emBreve: true,
            ),
            _BotaoDeAcao(
              icone: Icons.send_outlined,
              rotulo: textos.feedCompartilhar,
              cor: corApoio,
              onTocar: null,
              emBreve: true,
            ),
          ],
        ),
        _LinhaDeQuemCurtiu(
          isDark: isDark,
          curtidoPor: curtidoPor,
          carregarPerfis: carregarPerfis,
        ),
      ],
    );
  }
}

class _BotaoDeAcao extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback? onTocar;
  final bool emBreve;

  const _BotaoDeAcao({
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.onTocar,
    this.emBreve = false,
  });

  @override
  Widget build(BuildContext context) {
    // A opacidade separa "ainda não existe" de "existe e você pode tocar",
    // sem precisar de texto explicando. O tooltip diz o resto pra quem
    // insistir.
    final conteudo = Opacity(
      opacity: emBreve ? .38 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 20, color: cor),
            const SizedBox(width: 6),
            Text(
              rotulo,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: cor),
            ),
          ],
        ),
      ),
    );

    if (emBreve) {
      return Tooltip(message: textos.feedEmBreve, child: conteudo);
    }

    return InkWell(
      onTap: onTocar,
      borderRadius: BorderRadius.circular(10),
      child: conteudo,
    );
  }
}

/// As miniaturas de quem curtiu, sobrepostas, com a contagem ao lado.
class _LinhaDeQuemCurtiu extends StatelessWidget {
  final bool isDark;
  final List<String> curtidoPor;
  final Future<List<UserModel>> Function(List<String> uids)? carregarPerfis;

  const _LinhaDeQuemCurtiu({
    required this.isDark,
    required this.curtidoPor,
    required this.carregarPerfis,
  });

  @override
  Widget build(BuildContext context) {
    final corApoio = isDark ? AuthTheme.subDark : AuthTheme.subLight;

    if (curtidoPor.isEmpty) {
      // Convite, e não um "0 curtidas". Zero é um número que só informa que
      // ninguém quis; o convite diz que o toque é seu.
      return Padding(
        padding: const EdgeInsets.only(left: 10, top: 2),
        child: Text(
          textos.feedSejaOPrimeiroACurtir,
          style: GoogleFonts.outfit(fontSize: 12, color: corApoio),
        ),
      );
    }

    final contagem = curtidoPor.length == 1
        ? textos.feedUmaCurtida
        : textos.feedVariasCurtidas(curtidoPor.length);
    final sobrando = curtidoPor.length - maximoDeMiniaturas;

    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 2),
      child: Row(
        children: [
          if (carregarPerfis != null)
            FutureBuilder<List<UserModel>>(
              future: carregarPerfis!(curtidoPor),
              builder: (context, snapshot) {
                final perfis = snapshot.data ?? const <UserModel>[];
                if (perfis.isEmpty) return const SizedBox.shrink();

                // Largura calculada à mão porque os avatares se sobrepõem:
                // o primeiro ocupa inteiro, cada seguinte só o que aparece
                // dele. Sem isso o Stack colapsaria pra largura de um só.
                final largura = _diametro + (perfis.length - 1) * _passo;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    height: _diametro,
                    width: largura,
                    child: Stack(
                      children: [
                        for (int i = 0; i < perfis.length; i++)
                          Positioned(
                            left: i * _passo,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // A borda na cor do card é o que separa um
                                // avatar do outro quando eles se encostam.
                                border: Border.all(
                                  color: isDark ? const Color(0xFF3A1670) : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: AvatarUsuario(usuario: perfis[i], tamanho: _diametro - 3),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (sobrando > 0) ...[
            Text(
              textos.feedMaisPessoas(sobrando),
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: corApoio),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              contagem,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 12, color: corApoio),
            ),
          ),
        ],
      ),
    );
  }

  static const double _diametro = 24;

  /// O quanto cada avatar anda pra direita. Menor que o diâmetro de
  /// propósito: é a sobreposição que faz a fileira parecer um grupo, e não
  /// uma lista.
  static const double _passo = 16;
}
