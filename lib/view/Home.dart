import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/components/DegradeTopo.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/repositories/PostRepository.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/PoliticaPrivacidade.dart';
import 'package:ptk_plays/view/Configuracoes.dart';
import 'package:ptk_plays/view/Login.dart';
import 'package:ptk_plays/view/Privacidade.dart';
import 'package:ptk_plays/view/Profile.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'package:url_launcher/url_launcher.dart' as launcher_url;
import '../components/Header.dart';
import '../components/ModalMSG.dart';
import "package:ptk_plays/utils/ThemeController.dart";

class HomePage extends StatelessWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKEY;
  final AuthViewModel authViewModel;
  final PostRepository? postRepository;

  const HomePage({
    super.key,
    required this.viewmodelYT,
    required this.apiKEY,
    required this.authViewModel,
    this.postRepository,
  });

  @override
  Widget build( BuildContext context ) {
    bool isDark = context.watch<ThemeController>().isDark;
    final postViewModel = PostViewModel(postRepository ?? PostRepository());

    return Scaffold(
      endDrawer: MenuLateral(
        isDark: isDark,
        onRecuperacaoSenha: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Profile(viewmodelYT: viewmodelYT, apiKey: apiKEY, authViewModel: authViewModel),
          ),
        ),
        onPrivacidade: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Privacidade())),
        onPoliticaPrivacidade: () => abrirPoliticaPrivacidade(context),
        onConfiguracoes: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Configuracoes())),
        onSairDaConta: () async {
          await authViewModel.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => Login(viewmodelYT: viewmodelYT, apiKey: apiKEY, authViewModel: authViewModel),
            ),
            (route) => false,
          );
        },
      ),
      // A barra de navegacao NAO fica no slot bottomNavigationBar do Scaffold:
      // a combinacao extendBody+BackdropFilter nesse slot corrompe o frame
      // inteiro (body em branco) no CanvasKit web. Em vez disso, ela entra
      // como uma camada flutuante no Stack, igual um overlay comum.
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight)),
          Positioned.fill(child: AuthBackground(isDark: isDark)),
          const DegradeTopo(),
          SafeArea(
            child: Column(
              children: [
                buildHeader(title: "Feed", widgetContext: context, menu: BotaoMenuLateral(isDark: isDark)),
                Expanded(
                  child: StreamBuilder<List<PostModel>>(
                    stream: postViewModel.streamPostagens(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Não foi possível carregar os avisos.',
                            style: GoogleFonts.outfit(color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
                          ),
                        );
                      }

                      final postagens = snapshot.data ?? [];

                      if (postagens.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum aviso por aqui ainda :)',
                            style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                          ),
                        );
                      }

                      return ResponsiveCenter(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: postagens.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => PostCard(
                            isDark: isDark,
                            post: postagens[index],
                            uidAtual: authViewModel.uidAtual,
                            onVotar: (indiceOpcao) {
                              final uid = authViewModel.uidAtual;
                              if (uid == null) return;
                              postViewModel.votar(postId: postagens[index].id, indiceOpcao: indiceOpcao, uid: uid);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: buildBottonNavBar(
                currentIndex: 0,
                widgetContext: context,
                isDark: isDark,
                apiKey: apiKEY,
                ytViewModel: viewmodelYT,
                authViewModel: authViewModel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final bool isDark;
  final PostModel post;
  final String? uidAtual;
  final void Function(int indiceOpcao)? onVotar;

  const PostCard({
    super.key,
    required this.isDark,
    required this.post,
    this.uidAtual,
    this.onVotar,
  });

  @override
  Widget build(BuildContext context) {
    return CardVidro(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AuthTheme.buttonGradient),
                child: Icon(_iconePorTipo(post.tipo), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.autorNickname,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
                ),
              ),
              Text(
                _tempoRelativo(post.criadoEm),
                style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _conteudoPorTipo(context),
        ],
      ),
    );
  }

  // Ordem fixa de exibicao das plataformas nos cards aoVivo - so entram as
  // que estiverem realmente ativas no post (post.plataformasAoVivo).
  static const _ordemPlataformas = ['youtube', 'twitch', 'kick'];

  Widget _conteudoPorTipo(BuildContext context) {
    switch (post.tipo) {
      case PostModel.tipoAoVivo:
        final ativas = _ordemPlataformas.where((p) => post.plataformasAoVivo.containsKey(p)).toList();
        final detalhes = ativas.map((p) => post.plataformasAoVivo[p]!).toList();

        String? primeiroNaoVazio(Iterable<String?> valores) {
          for (final valor in valores) {
            if (valor != null && valor.isNotEmpty) return valor;
          }
          return null;
        }

        final tituloLive = primeiroNaoVazio(detalhes.map((d) => d.titulo));
        final jogo = primeiroNaoVazio(detalhes.map((d) => d.jogo));
        final thumbnailUrl = primeiroNaoVazio(detalhes.map((d) => d.thumbnailUrl));
        final iniciadaEm = detalhes
            .map((d) => d.iniciadaEm)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (menor, atual) => (menor == null || atual.isBefore(menor)) ? atual : menor);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE0264F), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'AO VIVO',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            if (thumbnailUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  thumbnailUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey.shade800,
                    child: const Center(child: Icon(Icons.image, color: Colors.white54)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              tituloLive ?? post.texto ?? 'Corre pra assistir agora!',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
            ),
            if (jogo != null || iniciadaEm != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (jogo != null) jogo,
                  if (iniciadaEm != null) 'começou às ${_formatarHorario(iniciadaEm)}',
                ].join(' • '),
                style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight, fontSize: 13),
              ),
            ],
            if (ativas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ativas.map((p) => _badgePlataforma(context, p, post.plataformasAoVivo[p]!.link)).toList(),
              ),
            ],
          ],
        );
      case PostModel.tipoAvisoFoto:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.texto != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  post.texto!,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
                ),
              ),
            if (post.fotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  post.fotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey.shade800,
                    child: const Center(child: Icon(Icons.image, color: Colors.white54)),
                  ),
                ),
              ),
          ],
        );
      case PostModel.tipoEnquete:
        final jaVotou = uidAtual != null && post.votantes.contains(uidAtual);
        final meuVotoIndice = jaVotou ? post.votosPorUsuario[uidAtual] : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.titulo ?? '',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
            ),
            const SizedBox(height: 10),
            if (post.opcoes != null)
              for (int indice = 0; indice < post.opcoes!.length; indice++)
                _barraOpcaoEnquete(post.opcoes![indice]),
            const SizedBox(height: 6),
            if (post.opcoes != null)
              for (int indice = 0; indice < post.opcoes!.length; indice++)
                _botaoOpcaoEnquete(indice, post.opcoes![indice], jaVotou, meuVotoIndice),
            if (jaVotou) ...[
              const SizedBox(height: 4),
              Text(
                'Você já votou',
                style: GoogleFonts.outfit(fontSize: 12, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
              ),
            ],
          ],
        );
      default: // avisoTexto
        return Text(
          post.texto ?? '',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
        );
    }
  }

  static const _corVotacao = Color(0xFFA12EE0);
  static const _corVotacaoEscura = Color(0xFF6A1B9A);

  Widget _barraOpcaoEnquete(PostOpcaoEnquete opcao) {
    final totalVotos = post.opcoes!.fold<int>(0, (soma, o) => soma + o.votos);
    final percentual = totalVotos == 0 ? 0.0 : opcao.votos / totalVotos;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(opcao.texto, style: GoogleFonts.outfit(color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight)),
              ),
              Text('${(percentual * 100).round()}%', style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentual,
              minHeight: 8,
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(.1),
              valueColor: const AlwaysStoppedAnimation(_corVotacao),
            ),
          ),
        ],
      ),
    );
  }

  // Os botoes de voto ficam sempre visiveis (antes e depois de votar). Depois
  // que o usuario vota, o botao escolhido fica roxo escuro (selecionado) e os
  // demais ficam com aspecto desabilitado (cinza, sem toque) — em vez de
  // sumir, pra deixar claro em qual opcao a pessoa votou.
  Widget _botaoOpcaoEnquete(int indice, PostOpcaoEnquete opcao, bool jaVotou, int? meuVotoIndice) {
    final selecionado = jaVotou && indice == meuVotoIndice;
    final desabilitado = jaVotou && indice != meuVotoIndice;

    Color corFundo;
    Color corTexto;
    Border? borda;

    if (selecionado) {
      corFundo = _corVotacaoEscura;
      corTexto = Colors.white;
    } else if (desabilitado) {
      corFundo = (isDark ? Colors.white : Colors.black).withOpacity(.06);
      corTexto = isDark ? AuthTheme.subDark : AuthTheme.subLight;
    } else {
      corFundo = Colors.transparent;
      corTexto = _corVotacao;
      borda = Border.all(color: _corVotacao, width: 1.4);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: jaVotou ? null : () => onVotar?.call(indice),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(12),
            border: borda,
          ),
          child: Text(
            opcao.texto,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: corTexto),
          ),
        ),
      ),
    );
  }

  IconData _iconePorTipo(String tipo) {
    switch (tipo) {
      case PostModel.tipoAoVivo:
        return Icons.sensors;
      case PostModel.tipoAvisoFoto:
        return Icons.image;
      case PostModel.tipoEnquete:
        return Icons.poll;
      default:
        return Icons.campaign;
    }
  }

  String _labelPlataforma(String p) {
    switch (p) {
      case 'youtube':
        return 'YouTube';
      case 'twitch':
        return 'Twitch';
      case 'kick':
        return 'Kick';
      default:
        return p;
    }
  }

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }

  String _formatarHorario(DateTime data) {
    final local = data.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$hora:$minuto ($dia/$mes)';
  }

  Color _corPlataforma(String p) {
    switch (p) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitch':
        return const Color(0xFF9146FF);
      case 'kick':
        return const Color(0xFF53FC18);
      default:
        return _corVotacao;
    }
  }

  // Cor de texto/icone sobre o fundo de _corPlataforma - Kick e um verde
  // claro demais pra texto branco ficar legivel em cima.
  Color _corTextoPlataforma(String p) => p == 'kick' ? Colors.black : Colors.white;

  Widget _badgePlataforma(BuildContext context, String plataforma, String link) {
    final cor = _corPlataforma(plataforma);
    final corTexto = _corTextoPlataforma(plataforma);
    return GestureDetector(
      onTap: () => _abrirLink(context, link),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labelPlataforma(plataforma),
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: corTexto),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 13, color: corTexto),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirLink(BuildContext context, String link) async {
    final url = Uri.parse(link);
    if (await launcher_url.canLaunchUrl(url)) {
      await launcher_url.launchUrl(url, mode: launcher_url.LaunchMode.externalApplication);
    } else if (context.mounted) {
      mostrarErroCustom(context, title: "Ops!", msg: "Não foi possível abrir a live :/");
    }
  }
}
