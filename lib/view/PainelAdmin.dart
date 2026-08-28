import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/DegradeTopo.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/components/Toast.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/data/repositories/AdminRepository.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/ThemeController.dart';

/// Painel de administração, acessível só pelo menu lateral de quem tem
/// `cargo == 'admin'` (ver [UserModel.ehAdmin]). A UI apenas esconde a
/// opção; quem de fato barra um não-admin é o `firestore.rules`.
///
/// Seções previstas (ver ROADMAP.md, "Painel ADM"): Usuários, Cargos,
/// Badges, Notificações e Aviso no WhatsApp. Só "Usuários" está
/// implementada — as demais aparecem como seções pendentes, com o que
/// falta pra cada uma, em vez de sumirem da navegação.
class PainelAdmin extends StatelessWidget {
  final AdminRepository? repository;

  const PainelAdmin({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;
    final repo = repository ?? AdminRepository();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight),
            ),
            Positioned.fill(child: AuthBackground(isDark: isDark)),
            SafeArea(
              child: Column(
                children: [
                  _cabecalho(context, isDark),
                  _abas(isDark),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _SecaoUsuarios(isDark: isDark, repository: repo),
                        const _SecaoPendente(
                          titulo: 'Cargos',
                          descricao:
                              'Cadastrar cargos novos além de inscrito/vip/admin e definir as permissões de cada um.',
                          oQueFalta:
                              'Depende de uma coleção "cargos" no Firestore e de reescrever o firestore.rules pra ler as permissões de lá, em vez do cargo fixo que ele checa hoje.',
                        ),
                        const _SecaoPendente(
                          titulo: 'Badges',
                          descricao: 'Conceder badges do catálogo a usuários escolhidos na lista.',
                          oQueFalta:
                              'O campo "badges" é travado contra escrita do cliente no firestore.rules — conceder badge precisa de uma Cloud Function com o Admin SDK.',
                        ),
                        const _SecaoPendente(
                          titulo: 'Notificações',
                          descricao: 'Enviar push com título e descrição pra todos ou só pra um cargo específico.',
                          oQueFalta:
                              'Precisa de uma Cloud Function que dispare via FCM. O envio por cargo exige inscrever cada usuário num tópico por cargo no login.',
                        ),
                        const _SecaoPendente(
                          titulo: 'Aviso no WhatsApp',
                          descricao: 'Disparar aviso pelo número do bot do canal, como as notificações.',
                          oQueFalta:
                              'Bloqueado até você comprar o número virtual e concluir a verificação na Meta. O webhook do WhatsApp Business já existe em functions/src/webhook.js.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DegradeTopo(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 6),
      child: Row(
        children: [
          BotaoVoltar(isDark: isDark, onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 14),
          Text(
            'Painel ADM',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _abas(bool isDark) {
    final cor = isDark ? AuthTheme.titleDark : AuthTheme.titleLight;
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: cor,
      unselectedLabelColor: isDark ? AuthTheme.subDark : AuthTheme.subLight,
      indicatorColor: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
      tabs: const [
        Tab(text: 'Usuários'),
        Tab(text: 'Cargos'),
        Tab(text: 'Badges'),
        Tab(text: 'Notificações'),
        Tab(text: 'WhatsApp'),
      ],
    );
  }
}

class _SecaoUsuarios extends StatelessWidget {
  final bool isDark;
  final AdminRepository repository;

  const _SecaoUsuarios({required this.isDark, required this.repository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: repository.streamUsuarios(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight));
        }
        if (snapshot.hasError) {
          return _mensagem(context, 'Não foi possível carregar os usuários.');
        }

        final usuarios = snapshot.data ?? [];
        if (usuarios.isEmpty) return _mensagem(context, 'Nenhum usuário cadastrado ainda.');

        return ResponsiveCenter(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: usuarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _LinhaUsuario(
              usuario: usuarios[index],
              isDark: isDark,
              repository: repository,
            ),
          ),
        );
      },
    );
  }

  Widget _mensagem(BuildContext context, String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
        ),
      ),
    );
  }
}

class _LinhaUsuario extends StatelessWidget {
  final UserModel usuario;
  final bool isDark;
  final AdminRepository repository;

  const _LinhaUsuario({required this.usuario, required this.isDark, required this.repository});

  @override
  Widget build(BuildContext context) {
    return CardVidro(
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        usuario.nickname,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _selo(usuario.cargo.toUpperCase(), const Color(0xFFA12EE0)),
                    if (usuario.estadoModeracao != 'ativo') ...[
                      const SizedBox(width: 6),
                      _selo(usuario.estadoModeracao.toUpperCase(), const Color(0xFFE0264F)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.email,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
            onSelected: (opcao) => _executar(context, opcao),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'perfil', child: Text('Ver perfil')),
              if (usuario.estadoModeracao == 'ativo') ...[
                const PopupMenuItem(value: 'suspender', child: Text('Suspender por 7 dias')),
                const PopupMenuItem(value: 'banir', child: Text('Banir')),
              ] else
                const PopupMenuItem(value: 'reativar', child: Text('Reativar conta')),
              const PopupMenuItem(value: 'mensagem', child: Text('Enviar mensagem privada')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selo(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        texto,
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Future<void> _executar(BuildContext context, String opcao) async {
    if (opcao == 'perfil') {
      _mostrarPerfil(context);
      return;
    }
    if (opcao == 'mensagem') {
      // Mensagem privada depende de uma coleção de conversas + regras +
      // tela de chat, que ainda não existem (ver ROADMAP.md).
      mostrarToast(context, mensagem: 'Mensagem privada ainda não está pronta.', erro: true);
      return;
    }

    try {
      switch (opcao) {
        case 'suspender':
          await repository.suspenderUsuario(usuario.uid, duracao: const Duration(days: 7));
          break;
        case 'banir':
          await repository.banirUsuario(usuario.uid);
          break;
        case 'reativar':
          await repository.reativarUsuario(usuario.uid);
          break;
      }
      if (context.mounted) mostrarToast(context, mensagem: 'Usuário atualizado.', erro: false);
    } catch (e) {
      if (context.mounted) mostrarToast(context, mensagem: 'Não foi possível atualizar: $e', erro: true);
    }
  }

  void _mostrarPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF3A1670) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              usuario.nickname,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
              ),
            ),
            const SizedBox(height: 12),
            _linha('E-mail', usuario.email),
            _linha('Cargo', usuario.cargo),
            _linha('Status', usuario.status),
            _linha('Moderação', usuario.estadoModeracao),
            _linha('Badges', usuario.badges.isEmpty ? '—' : usuario.badges.join(', ')),
            _linha('WhatsApp', usuario.telefoneWhatsapp.isEmpty ? '—' : usuario.telefoneWhatsapp),
          ],
        ),
      ),
    );
  }

  Widget _linha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: GoogleFonts.outfit(
                color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção do painel ainda não implementada. Mostra o que ela vai fazer e o
/// que falta pra sair do papel, em vez de um "em breve" vazio.
class _SecaoPendente extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String oQueFalta;

  const _SecaoPendente({required this.titulo, required this.descricao, required this.oQueFalta});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          CardVidro(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  descricao,
                  style: GoogleFonts.outfit(color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight, height: 1.5),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.build_outlined, size: 16, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        oQueFalta,
                        style: GoogleFonts.outfit(
                          color: isDark ? AuthTheme.subDark : AuthTheme.subLight,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
