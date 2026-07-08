import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthBackground.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/BottomNavBar.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../components/Header.dart';
import 'Login.dart';

const Color _corExcluir = Color(0xFFE0264F);

String _labelCargo(String cargo) {
  switch (cargo) {
    case 'admin':
      return 'Admin';
    case 'vip':
      return 'VIP';
    default:
      return 'Inscrito';
  }
}

String _labelStatus(String status) {
  switch (status) {
    case 'invisivel':
      return 'Invisível';
    case 'naoPerturbe':
      return 'Não perturbe';
    case 'offline':
      return 'Offline';
    default:
      return 'Online';
  }
}

String _labelCategoria(String categoria) {
  switch (categoria) {
    case 'otaku':
      return 'Otaku';
    case 'gamer':
      return 'Gamer';
    case 'streamer':
      return 'Streamer';
    case 'geek':
      return 'Geek';
    default:
      return 'Outro';
  }
}

String _formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

class Profile extends StatelessWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKey;
  final AuthViewModel authViewModel;

  const Profile({
    super.key,
    required this.viewmodelYT,
    required this.apiKey,
    required this.authViewModel,
  });

  Future<void> _sair(BuildContext context) async {
    await authViewModel.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => Login(viewmodelYT: viewmodelYT, apiKey: apiKey, authViewModel: authViewModel),
      ),
      (route) => false,
    );
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DialogoExcluirConta(
        onConfirmar: (senha) async {
          final erro = await authViewModel.excluirConta(senha: senha);
          if (!context.mounted) return;

          if (erro != null) {
            mostrarErroCustom(context, title: "Ops!", msg: erro);
            return;
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => Login(viewmodelYT: viewmodelYT, apiKey: apiKey, authViewModel: authViewModel),
            ),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: isDark ? AuthTheme.backgroundDark : AuthTheme.backgroundLight)),
          Positioned.fill(child: AuthBackground(isDark: isDark)),
          SafeArea(
            child: Column(
              children: [
                buildHeader(title: "Perfil", widgetContext: context),
                Expanded(
                  child: StreamBuilder<UserModel?>(
                    stream: authViewModel.streamUsuarioAtual(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final usuario = snapshot.data!;

                      return ResponsiveCenter(
                        child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          _CabecalhoPerfil(usuario: usuario, isDark: isDark),
                          const SizedBox(height: 16),
                          CardVidro(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LinhaInfo(isDark: isDark, label: 'Cargo', valor: _labelCargo(usuario.cargo)),
                                _LinhaInfo(isDark: isDark, label: 'Status', valor: _labelStatus(usuario.status)),
                                _LinhaInfo(isDark: isDark, label: 'Membro desde', valor: _formatarData(usuario.criadoEm)),
                                _LinhaInfo(
                                  isDark: isDark,
                                  label: 'Último acesso',
                                  valor: usuario.ultimoAcesso != null ? _formatarData(usuario.ultimoAcesso!) : '—',
                                  ultima: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          CardVidro(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Categorias',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: .5,
                                    color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                usuario.categorias.isEmpty
                                    ? Text(
                                        'Nenhuma categoria escolhida ainda',
                                        style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: usuario.categorias.map((c) => _Chip(texto: _labelCategoria(c))).toList(),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          CardVidro(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Badges',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: .5,
                                    color: isDark ? AuthTheme.labelDark : AuthTheme.labelLight,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                usuario.badges.isEmpty
                                    ? Text(
                                        'Nenhuma badge conquistada ainda',
                                        style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: usuario.badges.map((b) => _Chip(texto: b)).toList(),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () => _sair(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              side: BorderSide(color: isDark ? AuthTheme.cardBorderDark : AuthTheme.cardBorderLight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              'Sair',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _confirmarExclusao(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: _corExcluir,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              'Excluir conta',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottonNavBar(
        currentIndex: 2,
        widgetContext: context,
        isDark: isDark,
        apiKey: apiKey,
        ytViewModel: viewmodelYT,
        authViewModel: authViewModel,
      ),
    );
  }
}

class _CabecalhoPerfil extends StatelessWidget {
  final UserModel usuario;
  final bool isDark;
  const _CabecalhoPerfil({required this.usuario, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AuthTheme.buttonGradient),
          child: usuario.fotoUrl.isNotEmpty
              ? ClipOval(child: Image.network(usuario.fotoUrl, fit: BoxFit.cover))
              : const Icon(Icons.person, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 12),
        Text(
          usuario.nickname,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          usuario.email,
          style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
        ),
      ],
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final bool isDark;
  final String label;
  final String valor;
  final bool ultima;
  const _LinhaInfo({required this.isDark, required this.label, required this.valor, this.ultima = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: isDark ? AuthTheme.subDark : AuthTheme.subLight)),
          Text(
            valor,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isDark ? AuthTheme.titleDark : AuthTheme.titleLight),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  const _Chip({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(gradient: AuthTheme.buttonGradient, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _DialogoExcluirConta extends StatefulWidget {
  final Future<void> Function(String senha) onConfirmar;
  const _DialogoExcluirConta({required this.onConfirmar});

  @override
  State<_DialogoExcluirConta> createState() => _DialogoExcluirContaState();
}

class _DialogoExcluirContaState extends State<_DialogoExcluirConta> {
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, color: _corExcluir, size: 48),
            const SizedBox(height: 12),
            Text(
              'Excluir conta',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Essa ação é irreversível: seus dados serão apagados permanentemente. Digite sua senha pra confirmar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _carregando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _corExcluir),
                    onPressed: _carregando
                        ? null
                        : () async {
                            if (_senhaController.text.isEmpty) return;
                            setState(() => _carregando = true);
                            await widget.onConfirmar(_senhaController.text);
                            if (mounted) setState(() => _carregando = false);
                          },
                    child: _carregando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Excluir', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
