import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/utils/app_theme.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../components/Header.dart';
import 'Cadastro.dart';
import 'Home.dart';

class Login extends StatefulWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKey;
  final AuthViewModel authViewModel;

  const Login({
    super.key,
    required this.viewmodelYT,
    required this.apiKey,
    required this.authViewModel,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      mostrarErroCustom(context, title: "Ops!", msg: "Preencha email e senha.");
      return;
    }

    setState(() => _carregando = true);

    final erro = await widget.authViewModel.login(email: email, senha: senha);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      mostrarErroCustom(context, title: "Ops!", msg: erro);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(viewmodelYT: widget.viewmodelYT, apiKEY: widget.apiKey),
      ),
    );
  }

  void _irParaCadastro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Cadastro(
          viewmodelYT: widget.viewmodelYT,
          apiKey: widget.apiKey,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.watch<ThemeController>().isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? AppThemes.darkBackground : AppThemes.lightBackground),
        child: SafeArea(
          child: Column(
            children: [
              buildHeader(title: "Entrar", widgetContext: context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/original_icon_app.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _carregando ? null : _irParaCadastro,
                        child: const Text('Criar conta'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
