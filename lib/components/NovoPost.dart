import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ptk_plays/components/AuthWidgets.dart';
import 'package:ptk_plays/components/ModalMSG.dart';
import 'package:ptk_plays/components/Toast.dart';
import 'package:ptk_plays/data/models/UserModel.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/ThemeController.dart';
import 'package:ptk_plays/utils/ValidacaoPost.dart';
import 'package:ptk_plays/viewmodels/PostViewModel.dart';

/// Abre o formulario de nova publicacao do feed. Todo usuario logado pode
/// publicar um aviso de texto; **enquete so aparece pra quem e admin**, que
/// e o mesmo recorte do `firestore.rules` (a UI so esconde a opcao, quem
/// barra de verdade e a regra).
///
/// Retorna true quando algo foi publicado (a lista do feed e um stream, o
/// post aparece sozinho — o retorno serve pro chamador dar o toast de
/// sucesso).
Future<bool> mostrarNovoPost(
  BuildContext context, {
  required UserModel autor,
  required PostViewModel postViewModel,
}) async {
  final isDark = context.read<ThemeController>().isDark;

  final publicou = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF2C0F55) : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _FormularioNovoPost(isDark: isDark, autor: autor, postViewModel: postViewModel),
  );

  return publicou ?? false;
}

class _FormularioNovoPost extends StatefulWidget {
  final bool isDark;
  final UserModel autor;
  final PostViewModel postViewModel;

  const _FormularioNovoPost({required this.isDark, required this.autor, required this.postViewModel});

  @override
  State<_FormularioNovoPost> createState() => _FormularioNovoPostState();
}

class _FormularioNovoPostState extends State<_FormularioNovoPost> {
  final _texto = TextEditingController();
  final _pergunta = TextEditingController();
  final List<TextEditingController> _opcoes = [TextEditingController(), TextEditingController()];

  bool _enquete = false;
  bool _publicando = false;

  @override
  void dispose() {
    _texto.dispose();
    _pergunta.dispose();
    for (final opcao in _opcoes) {
      opcao.dispose();
    }
    super.dispose();
  }

  Future<void> _publicar() async {
    final erroDeValidacao = _enquete
        ? validarEnquete(pergunta: _pergunta.text, opcoes: _opcoes.map((o) => o.text).toList())
        : validarAviso(_texto.text);

    // Erro de formulario é modal bloqueante; erro da escrita em si é toast
    // (regra de feedback do CLAUDE.md).
    if (erroDeValidacao != null) {
      mostrarErroCustom(context, title: 'Ops!', msg: erroDeValidacao);
      return;
    }

    setState(() => _publicando = true);

    final erro = _enquete
        ? await widget.postViewModel.publicarEnquete(
            pergunta: _pergunta.text,
            opcoes: _opcoes.map((o) => o.text).toList(),
            autor: widget.autor,
          )
        : await widget.postViewModel.publicarAviso(texto: _texto.text, autor: widget.autor);

    if (!mounted) return;
    setState(() => _publicando = false);

    if (erro != null) {
      mostrarToast(context, mensagem: erro, erro: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final corTitulo = isDark ? AuthTheme.titleDark : AuthTheme.titleLight;

    return Padding(
      // Empurra o formulario acima do teclado quando ele abre.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AuthTheme.subDark : AuthTheme.subLight).withOpacity(.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nova publicação',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: corTitulo),
            ),
            const SizedBox(height: 4),
            Text(
              widget.autor.ehAdmin
                  ? 'Como admin, seu post fica no topo do feed.'
                  : 'Publicando como ${widget.autor.nickname}.',
              style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
            ),
            const SizedBox(height: 18),

            // Enquete é privilégio de admin, igual à regra do Firestore.
            if (widget.autor.ehAdmin) ...[
              Row(
                children: [
                  _BotaoTipo(
                    label: 'Aviso',
                    selecionado: !_enquete,
                    isDark: isDark,
                    onTap: () => setState(() => _enquete = false),
                  ),
                  const SizedBox(width: 10),
                  _BotaoTipo(
                    label: 'Enquete',
                    selecionado: _enquete,
                    isDark: isDark,
                    onTap: () => setState(() => _enquete = true),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            if (_enquete) ..._camposDeEnquete(isDark) else _campoDeAviso(isDark),

            const SizedBox(height: 22),
            BotaoPrimario(label: 'Publicar', carregando: _publicando, onTap: _publicar),
          ],
        ),
      ),
    );
  }

  Widget _campoDeAviso(bool isDark) {
    return _CampoMultilinha(
      isDark: isDark,
      controller: _texto,
      hint: 'O que você quer avisar pra galera?',
      linhas: 5,
      limite: limiteCaracteresAviso,
    );
  }

  List<Widget> _camposDeEnquete(bool isDark) {
    return [
      _CampoMultilinha(
        isDark: isDark,
        controller: _pergunta,
        hint: 'Qual é a pergunta?',
        linhas: 2,
        limite: limiteCaracteresPergunta,
      ),
      const SizedBox(height: 14),
      for (int i = 0; i < _opcoes.length; i++) ...[
        Row(
          children: [
            Expanded(
              child: _CampoMultilinha(
                isDark: isDark,
                controller: _opcoes[i],
                hint: 'Opção ${i + 1}',
                linhas: 1,
              ),
            ),
            if (_opcoes.length > minimoOpcoesEnquete)
              IconButton(
                tooltip: 'Remover opção',
                icon: Icon(Icons.close, size: 18, color: isDark ? AuthTheme.subDark : AuthTheme.subLight),
                onPressed: () => setState(() => _opcoes.removeAt(i).dispose()),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
      if (_opcoes.length < maximoOpcoesEnquete)
        TextButton.icon(
          onPressed: () => setState(() => _opcoes.add(TextEditingController())),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Adicionar opção'),
          style: TextButton.styleFrom(foregroundColor: isDark ? AuthTheme.linkDark : AuthTheme.linkLight),
        ),
    ];
  }
}

/// Campo de texto de várias linhas no mesmo visual do [CampoTexto] da tela
/// de login/cadastro (que só aceita uma linha e exige um ícone SVG).
class _CampoMultilinha extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final String hint;
  final int linhas;
  final int? limite;

  const _CampoMultilinha({
    required this.isDark,
    required this.controller,
    required this.hint,
    required this.linhas,
    this.limite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AuthTheme.inputBgDark : AuthTheme.inputBgLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        minLines: linhas,
        maxLines: linhas + 3,
        maxLength: limite,
        style: GoogleFonts.outfit(fontSize: 15, color: AuthTheme.inputTextColor),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: AuthTheme.placeholderColor),
        ),
      ),
    );
  }
}

class _BotaoTipo extends StatelessWidget {
  final String label;
  final bool selecionado;
  final bool isDark;
  final VoidCallback onTap;

  const _BotaoTipo({required this.label, required this.selecionado, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: selecionado ? AuthTheme.buttonGradient : null,
          color: selecionado ? null : (isDark ? AuthTheme.inputBgDark : AuthTheme.inputBgLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selecionado ? Colors.white : (isDark ? AuthTheme.subDark : AuthTheme.subLight),
          ),
        ),
      ),
    );
  }
}
