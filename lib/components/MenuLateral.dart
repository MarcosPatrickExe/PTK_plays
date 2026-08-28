import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/AuthTheme.dart';

/// Botao de menu lateral (3 linhas horizontais), no mesmo padrao visual do
/// botao de tema. So deve ser adicionado nas telas principais depois do
/// login (Home/Videos/Profile via [buildHeader]) - nunca em Login/Cadastro/
/// recuperacao de senha, que simplesmente nao usam esse widget.
///
/// Usa [Builder] pra obter um contexto abaixo do [Scaffold]: o context da
/// propria tela que chama esse widget ainda esta "acima" do Scaffold sendo
/// construido nesse mesmo build(), entao `Scaffold.of(context)` direto ali
/// não encontraria o Scaffold.
class BotaoMenuLateral extends StatelessWidget {
  final bool isDark;
  const BotaoMenuLateral({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => Scaffold.of(context).openEndDrawer(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? AuthTheme.themeBtnBgDark
                : AuthTheme.themeBtnBgLight,
            border: Border.all(
              color: isDark
                  ? AuthTheme.themeBtnBorderDark
                  : AuthTheme.themeBtnBorderLight,
            ),
          ),
          child: Icon(
            Icons.menu,
            color: isDark ? AuthTheme.themeIconDark : AuthTheme.themeIconLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Painel deslizante (endDrawer, entra pela direita) com os atalhos de
/// "Recuperação de senha", "Privacidade" e "Configurações". Cada opção
/// recebe seu proprio callback em vez do widget navegar sozinho, pra nao
/// precisar conhecer as dependencias (AuthViewModel, UserModel, etc.) de
/// quem o usa - cada tela decide pra onde navegar.
class MenuLateral extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRecuperacaoSenha;
  final VoidCallback onPrivacidade;
  final VoidCallback onPoliticaPrivacidade;
  final VoidCallback onConfiguracoes;
  final VoidCallback onSairDaConta;

  /// So aparece pra quem tem `cargo == 'admin'` (ver UserModel.ehAdmin).
  /// Esconder na UI e conveniencia: quem realmente barra um nao-admin de
  /// mexer nos dados e o `firestore.rules`.
  final bool ehAdmin;
  final VoidCallback? onPainelAdmin;

  const MenuLateral({
    super.key,
    required this.isDark,
    required this.onRecuperacaoSenha,
    required this.onPrivacidade,
    required this.onPoliticaPrivacidade,
    required this.onConfiguracoes,
    required this.onSairDaConta,
    this.ehAdmin = false,
    this.onPainelAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Drawer(
      width: largura * 0.62,
      backgroundColor: Colors.transparent,
      // O conteudo (itens do menu) fica sempre sobre uma faixa branca opaca
      // no topo, tanto no modo claro (fundo 100% branco) quanto no escuro
      // (gradiente que so vira roxo perto do rodape) - por isso o texto usa
      // uma unica cor fixa (titleLight) em vez de alternar com isDark.
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? null : AuthTheme.menuBgLight,
          gradient: isDark ? AuthTheme.menuBgGradientDark : null,
        ),
        // Material transparente entre a decoracao e os ListTile: sem isso,
        // o Container fica entre o ListTile e o Material mais proximo (o do
        // proprio Drawer), e o ripple/splash do toque para de aparecer.
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Menu',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AuthTheme.titleLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ItemMenu(
                  icone: Icons.lock_reset,
                  texto: 'Recuperação de senha',
                  onTap: () {
                    Navigator.of(context).pop();
                    onRecuperacaoSenha();
                  },
                ),
                _ItemMenu(
                  icone: Icons.privacy_tip_outlined,
                  texto: 'Privacidade',
                  onTap: () {
                    Navigator.of(context).pop();
                    onPrivacidade();
                  },
                ),
                _ItemMenu(
                  icone: Icons.policy_outlined,
                  texto: 'Política de Privacidade',
                  onTap: () {
                    Navigator.of(context).pop();
                    onPoliticaPrivacidade();
                  },
                ),
                if (ehAdmin)
                  _ItemMenu(
                    icone: Icons.admin_panel_settings_outlined,
                    texto: 'Painel ADM',
                    cor: const Color(0xFFA12EE0),
                    onTap: () {
                      Navigator.of(context).pop();
                      onPainelAdmin?.call();
                    },
                  ),
                _ItemMenu(
                  icone: Icons.settings_outlined,
                  texto: 'Configurações',
                  onTap: () {
                    Navigator.of(context).pop();
                    onConfiguracoes();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(color: Color(0x33000000), height: 1),
                ),
                _ItemMenu(
                  icone: Icons.logout,
                  texto: 'Sair da conta',
                  cor: const Color(0xFFE0264F),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSairDaConta();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  final Color? cor;

  const _ItemMenu({
    required this.icone,
    required this.texto,
    required this.onTap,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final corEfetiva = cor ?? AuthTheme.titleLight;
    return ListTile(
      leading: Icon(icone, color: corEfetiva),
      title: Text(
        texto,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: corEfetiva,
        ),
      ),
      onTap: onTap,
    );
  }
}
