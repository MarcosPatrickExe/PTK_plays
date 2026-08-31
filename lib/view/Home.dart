import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/components/DegradeTopo.dart';
import 'package:ptk_plays/components/ImagemRede.dart';
import 'package:ptk_plays/components/MenuLateral.dart';
import 'package:ptk_plays/components/NovoPost.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/components/Toast.dart';
import 'package:ptk_plays/data/models/PostModel.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/data/repositories/PostRepository.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/PoliticaPrivacidade.dart';
import 'package:ptk_plays/view/Configuracoes.dart';
import 'package:ptk_plays/view/Login.dart';
import 'package:ptk_plays/view/PainelAdmin.dart';
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

    // O perfil do usuario logado e lido uma vez pra tela inteira: o cargo
    // decide se o "Painel ADM" aparece no menu, e os dados do autor sao o
    // que o botao de publicar manda pro post.
    return StreamBuilder<UserModel?>(
      stream: authViewModel.streamUsuarioAtual(),
      builder: (context, snapshotUsuario) {
        final usuario = snapshotUsuario.data;
        return _construirTela(context, isDark, postViewModel, usuario);
      },
    );
  }

  Widget _construirTela(BuildContext context, bool isDark, PostViewModel postViewModel, UserModel? usuario) {
    return Scaffold(
      endDrawer: MenuLateral(
        isDark: isDark,
        ehAdmin: usuario?.ehAdmin ?? false,
        onPainelAdmin: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PainelAdmin(admin: usuario!)),
        ),
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
          // O conteudo ocupa a tela inteira (sem Column com o cabecalho
          // acima) pra poder rolar POR BAIXO do cabecalho e do scrim - se
          // ficasse numa Column, a area rolavel comecaria embaixo do
          // cabecalho e os cards seriam cortados numa linha reta ali.
          SafeArea(
            child: Column(
              children: [
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
                          // O topo abre espaco pro cabecalho flutuante: a
                          // lista comeca abaixo dele, mas rola por baixo.
                          padding: const EdgeInsets.fromLTRB(16, alturaCabecalho + 16, 16, 100),
                          itemCount: postagens.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => PostCard(
                            isDark: isDark,
                            post: postagens[index],
                            uidAtual: authViewModel.uidAtual,
                            // Autor apaga o proprio post; admin apaga
                            // qualquer um. Avisos de live sao do sistema e
                            // ninguem apaga pela UI (eles se encerram
                            // sozinhos quando a transmissao acaba).
                            onExcluir: postagens[index].tipo != PostModel.tipoAoVivo &&
                                    (usuario?.ehAdmin == true || postagens[index].autorUid == authViewModel.uidAtual)
                                ? () => _excluirPost(context, postViewModel, postagens[index].id)
                                : null,
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
          // Scrim e cabecalho ficam DEPOIS do conteudo no Stack: o conteudo
          // rolado passa por baixo dos dois em vez de ser cortado.
          DegradeTopo(isDark: isDark),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: buildHeader(title: "Feed", widgetContext: context, menu: BotaoMenuLateral(isDark: isDark)),
            ),
          ),
          // Scrim do rodape: escurece o conteudo que passa por baixo da
          // barra de navegacao, espelhando o do topo.
          DegradeRodape(isDark: isDark),
          // Publicar no feed: todo usuario logado pode (inscrito publica
          // aviso de texto; admin tambem publica enquete e cai no topo da
          // lista). Sem perfil carregado ainda, o botao nem aparece - nao
          // da pra assinar o post sem saber quem e o autor.
          if (usuario != null)
            Positioned(
              right: 18,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 96),
                  child: BotaoNovoPost(isDark: isDark, autor: usuario, postViewModel: postViewModel),
                ),
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

/// Pede confirmacao e apaga o post. A exclusao e definitiva e some pra
/// todo mundo, entao nao da pra ser um toque unico sem pergunta.
Future<void> _excluirPost(BuildContext context, PostViewModel postViewModel, String postId) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir post?'),
      content: const Text('Ele some do feed pra todo mundo. Não dá pra desfazer.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Excluir', style: TextStyle(color: Color(0xFFE0264F))),
        ),
      ],
    ),
  );

  if (confirmou != true || !context.mounted) return;

  final erro = await postViewModel.excluirPost(postId);
  if (!context.mounted) return;
  mostrarToast(context, mensagem: erro ?? 'Post excluído.', erro: erro != null);
}

/// Botao flutuante de publicar no feed (Home). Fica acima da barra de
/// navegacao, no canto direito. O formulario em si e compartilhado com a
/// aba "Posts" do Painel ADM (ver `mostrarNovoPost`).
class BotaoNovoPost extends StatelessWidget {
  final bool isDark;
  final UserModel autor;
  final PostViewModel postViewModel;

  const BotaoNovoPost({super.key, required this.isDark, required this.autor, required this.postViewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final publicou = await mostrarNovoPost(context, autor: autor, postViewModel: postViewModel);
        if (publicou && context.mounted) {
          mostrarToast(context, mensagem: 'Publicado no feed!', erro: false);
        }
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AuthTheme.buttonGradient,
          boxShadow: const [BoxShadow(color: Color(0x66C828B4), blurRadius: 22, offset: Offset(0, 10))],
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final bool isDark;
  final PostModel post;
  final String? uidAtual;
  final void Function(int indiceOpcao)? onVotar;

  /// Quando nao for nulo, o card mostra o menu de 3 pontos com "Excluir".
  /// Quem decide se ele aparece e a Home (autor do post ou admin) — as
  /// regras do Firestore aplicam o mesmo recorte no servidor.
  final Future<void> Function()? onExcluir;

  const PostCard({
    super.key,
    required this.isDark,
    required this.post,
    this.uidAtual,
    this.onVotar,
    this.onExcluir,
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
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.autorNickname,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                        ),
                      ),
                    ),
                    // Deixa visivel de quem e a "preferencia" no feed: post
                    // de admin fica no topo (PostModel.ordenarParaFeed).
                    if (post.autorCargo == 'admin') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA12EE0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _tempoRelativo(post.criadoEm),
                style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight, fontSize: 12),
              ),
              if (onExcluir != null)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, size: 18, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                  onSelected: (_) => onExcluir!(),
                  itemBuilder: (context) => const [PopupMenuItem(value: 'excluir', child: Text('Excluir post'))],
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
        // Guarda a plataforma inteira, e nao so a URL: o card precisa
        // tambem do endereco alternativo dela pra segunda tentativa.
        PostPlataformaAoVivo? comPreview;
        for (final detalhe in detalhes) {
          if (detalhe.previewUrl != null) {
            comPreview = detalhe;
            break;
          }
        }
        final thumbnailUrl = comPreview?.previewUrl;
        final iniciadaEm = detalhes
            .map((d) => d.iniciadaEm)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (menor, atual) => (menor == null || atual.isBefore(menor)) ? atual : menor);

        final aindaAoVivo = detalhes.any((d) => d.aoVivo);
        // Depois que acaba, o que interessa e quando terminou e quanto
        // durou - a maior duracao entre as plataformas e o encerramento
        // mais recente representam a transmissao como um todo.
        final encerradaEm = detalhes
            .map((d) => d.encerradaEm)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (maior, atual) => (maior == null || atual.isAfter(maior)) ? atual : maior);
        final duracaoSegundos = detalhes
            .map((d) => d.duracaoSegundos)
            .whereType<int>()
            .fold<int?>(null, (maior, atual) => (maior == null || atual > maior) ? atual : maior);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: aindaAoVivo ? const Color(0xFFE0264F) : (isDark ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                aindaAoVivo ? 'AO VIVO' : 'ENCERRADA',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            if (thumbnailUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ImagemRede(
                  url: thumbnailUrl,
                  urlAlternativa: comPreview?.previewUrlAlternativo,
                  isDark: isDark,
                  altura: 160,
                  largura: double.infinity,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              tituloLive ?? post.texto ?? 'Corre pra assistir agora!',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
            ),
            if (jogo != null) ...[
              const SizedBox(height: 6),
              _linhaDetalhe(Icons.sports_esports, jogo),
            ],
            if (duracaoSegundos != null) ...[
              const SizedBox(height: 4),
              _linhaDetalhe(Icons.schedule, 'Durou ${_formatarDuracao(duracaoSegundos)}'),
            ],
            if (!aindaAoVivo && encerradaEm != null) ...[
              const SizedBox(height: 4),
              _linhaDetalhe(Icons.event_available, 'Encerrada em ${_formatarDataHora(encerradaEm)}'),
            ] else if (aindaAoVivo && iniciadaEm != null) ...[
              const SizedBox(height: 4),
              _linhaDetalhe(Icons.play_circle_outline, 'Começou às ${_formatarDataHora(iniciadaEm)}'),
            ],
            if (ativas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ativas
                    .map((p) => _badgePlataforma(context, p, post.plataformasAoVivo[p]!))
                    .toList(),
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
                child: ImagemRede(url: post.fotoUrl!, isDark: isDark),
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

  String _formatarDataHora(DateTime data) {
    final local = data.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $hora:$minuto';
  }

  /// "2h 35min", "45min" ou "38s" - sem zeros a esquerda inuteis, pra ficar
  /// legivel num card curto.
  String _formatarDuracao(int totalSegundos) {
    final horas = totalSegundos ~/ 3600;
    final minutos = (totalSegundos % 3600) ~/ 60;
    if (horas > 0) return minutos > 0 ? '${horas}h ${minutos}min' : '${horas}h';
    if (minutos > 0) return '${minutos}min';
    return '${totalSegundos}s';
  }

  Widget _linhaDetalhe(IconData icone, String texto) {
    final cor = isDark ? AuthTheme.subDark : AuthTheme.subLight;
    return Row(
      children: [
        Icon(icone, size: 15, color: cor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: GoogleFonts.outfit(color: cor, fontSize: 13)),
        ),
      ],
    );
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

  /// Badge da plataforma. O toque abre a live enquanto ela esta no ar e a
  /// gravacao depois que acaba (ver [PostPlataformaAoVivo.linkParaAbrir]).
  /// O icone reflete isso: "abrir link" pra live, "play" pra gravacao.
  Widget _badgePlataforma(BuildContext context, String plataforma, PostPlataformaAoVivo dados) {
    final cor = _corPlataforma(plataforma);
    final corTexto = _corTextoPlataforma(plataforma);
    final temGravacao = !dados.aoVivo && dados.vodUrl != null && dados.vodUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _abrirLink(context, dados.linkParaAbrir),
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
            Icon(temGravacao ? Icons.play_arrow : Icons.open_in_new, size: 13, color: corTexto),
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
