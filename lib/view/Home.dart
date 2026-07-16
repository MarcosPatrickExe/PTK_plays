import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/repositories/PostRepository.dart';
import 'package:ptk_plays/services/LiveNotificationRouter.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'package:url_launcher/url_launcher.dart' as launcher_url;
import '../components/Header.dart';
import "package:ptk_plays/utils/ThemeController.dart";

class HomePage extends StatefulWidget {
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PostViewModel _postViewModel;
  final ScrollController _scrollController = ScrollController();

  /// Id do post que veio de uma notificacao de "ao vivo" — usado pra rolar
  /// ate o topo (onde a live sempre aparece, por ser o post mais recente) e
  /// destacar visualmente o card certo por alguns segundos.
  String? _postIdDestacado;

  @override
  void initState() {
    super.initState();
    _postViewModel = PostViewModel(widget.postRepository ?? PostRepository());

    LiveNotificationRouter.postIdParaDestacar.addListener(_aoReceberNotificacaoAoVivo);
    _aoReceberNotificacaoAoVivo(); // cobre o caso do app ter aberto direto por uma notificacao
  }

  @override
  void dispose() {
    LiveNotificationRouter.postIdParaDestacar.removeListener(_aoReceberNotificacaoAoVivo);
    _scrollController.dispose();
    super.dispose();
  }

  void _aoReceberNotificacaoAoVivo() {
    final postId = LiveNotificationRouter.postIdParaDestacar.value;
    if (postId == null) return;

    LiveNotificationRouter.postIdParaDestacar.value = null; // consome o valor, uma vez so
    setState(() => _postIdDestacado = postId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _postIdDestacado == postId) {
        setState(() => _postIdDestacado = null);
      }
    });
  }

  @override
  Widget build( BuildContext context ) {
    bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      // A barra de navegacao NAO fica no slot bottomNavigationBar do Scaffold:
      // a combinacao extendBody+BackdropFilter nesse slot corrompe o frame
      // inteiro (body em branco) no CanvasKit web. Em vez disso, ela entra
      // como uma camada flutuante no Stack, igual um overlay comum.
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight)),
          Positioned.fill(child: AuthBackground(isDark: isDark)),
          SafeArea(
            child: Column(
              children: [
                buildHeader(title: "Feed", widgetContext: context),
                Expanded(
                  child: StreamBuilder<List<PostModel>>(
                    stream: _postViewModel.streamPostagens(),
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
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: postagens.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => PostCard(
                            isDark: isDark,
                            post: postagens[index],
                            uidAtual: widget.authViewModel.uidAtual,
                            destacado: postagens[index].id == _postIdDestacado,
                            onVotar: (indiceOpcao) {
                              final uid = widget.authViewModel.uidAtual;
                              if (uid == null) return;
                              _postViewModel.votar(postId: postagens[index].id, indiceOpcao: indiceOpcao, uid: uid);
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
                apiKey: widget.apiKEY,
                ytViewModel: widget.viewmodelYT,
                authViewModel: widget.authViewModel,
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
  final bool destacado;
  final void Function(int indiceOpcao)? onVotar;

  const PostCard({
    super.key,
    required this.isDark,
    required this.post,
    this.uidAtual,
    this.destacado = false,
    this.onVotar,
  });

  static const _corDestaque = Color(0xFFA12EE0);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: destacado ? Border.all(color: _corDestaque, width: 2.5) : null,
        boxShadow: destacado
            ? [BoxShadow(color: _corDestaque.withOpacity(.5), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: CardVidro(
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
            _conteudoPorTipo(),
          ],
        ),
      ),
    );
  }

  Widget _conteudoPorTipo() {
    switch (post.tipo) {
      case PostModel.tipoAoVivo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: post.encerrada ? Colors.grey.shade600 : const Color(0xFFE0264F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.encerrada ? 'LIVE ENCERRADA' : 'AO VIVO',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            if (post.texto != null) ...[
              const SizedBox(height: 8),
              Text(
                post.texto!,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
              ),
            ],
            if (post.linksPorPlataforma.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.linksPorPlataforma.entries.map((e) => _botaoPlataforma(e.key, e.value)).toList(),
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

  Color _corPlataforma(String p) {
    switch (p) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitch':
        return const Color(0xFF9146FF);
      case 'kick':
        return const Color(0xFF53FC18);
      default:
        return AuthTheme.buttonGradient.colors.first;
    }
  }

  IconData _iconePlataforma(String p) {
    switch (p) {
      case 'youtube':
        return Icons.play_arrow_rounded;
      case 'twitch':
        return Icons.videogame_asset_rounded;
      case 'kick':
        return Icons.bolt_rounded;
      default:
        return Icons.live_tv_rounded;
    }
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await launcher_url.canLaunchUrl(uri)) {
      await launcher_url.launchUrl(uri, mode: launcher_url.LaunchMode.externalApplication);
    }
  }

  Widget _botaoPlataforma(String plataforma, String link) {
    final cor = _corPlataforma(plataforma);
    // Kick e um verde bem claro; texto preto fica mais legivel que branco nele.
    final corTexto = plataforma == 'kick' ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () => _abrirLink(link),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconePlataforma(plataforma), color: corTexto, size: 18),
            const SizedBox(width: 6),
            Text(
              'Assistir na ${_labelPlataforma(plataforma)}',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: corTexto),
            ),
          ],
        ),
      ),
    );
  }

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
