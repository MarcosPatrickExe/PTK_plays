import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
/// publicar um aviso de texto; **enquete e midia (foto/video) so aparecem
/// pra quem e admin**, que e o mesmo recorte do `firestore.rules` (a UI so
/// esconde as opcoes, quem barra de verdade e a regra).
///
/// Midia so do admin e uma decisao de moderacao, nao de layout: imagem e
/// video sao o que da pra publicar de pior sem ninguem revisar antes (ver
/// REGRAS_DA_COMUNIDADE.md). Inscrito publica texto, que da pra ler e
/// apagar depois.
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
  bool _escolhendoMidia = false;

  _MidiaEscolhida? _foto;
  _MidiaEscolhida? _video;

  bool get _temMidia => _foto != null || _video != null;

  @override
  void dispose() {
    _texto.dispose();
    _pergunta.dispose();
    for (final opcao in _opcoes) {
      opcao.dispose();
    }
    super.dispose();
  }

  /// Abre a galeria e guarda os bytes do arquivo escolhido. Nada sobe pro
  /// Storage aqui: o envio so acontece no "Publicar", pra quem desistir no
  /// meio do caminho nao deixar arquivo orfao la.
  Future<void> _escolherMidia({required bool ehVideo}) async {
    setState(() => _escolhendoMidia = true);

    try {
      final seletor = ImagePicker();
      final arquivo = ehVideo
          ? await seletor.pickVideo(source: ImageSource.gallery)
          : await seletor.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);

      if (arquivo == null || !mounted) return;

      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;

      final erroDeTamanho = validarTamanhoMidia(bytes: bytes.length, ehVideo: ehVideo);
      if (erroDeTamanho != null) {
        mostrarErroCustom(context, title: 'Arquivo grande demais', msg: erroDeTamanho);
        return;
      }

      final escolhida = _MidiaEscolhida(
        bytes: bytes,
        contentType: arquivo.mimeType ?? (ehVideo ? 'video/mp4' : 'image/jpeg'),
        extensao: _extensaoDoArquivo(arquivo.name, ehVideo ? 'mp4' : 'jpg'),
        nome: arquivo.name,
      );

      setState(() => ehVideo ? _video = escolhida : _foto = escolhida);
    } finally {
      if (mounted) setState(() => _escolhendoMidia = false);
    }
  }

  Future<void> _publicar() async {
    final erroDeValidacao = _enquete
        ? validarEnquete(pergunta: _pergunta.text, opcoes: _opcoes.map((o) => o.text).toList())
        : validarAviso(_texto.text, temMidia: _temMidia);

    // Erro de formulario é modal bloqueante; erro da escrita em si é toast
    // (regra de feedback do CLAUDE.md).
    if (erroDeValidacao != null) {
      mostrarErroCustom(context, title: 'Ops!', msg: erroDeValidacao);
      return;
    }

    setState(() => _publicando = true);

    final erro = await _escrever();

    if (!mounted) return;
    setState(() => _publicando = false);

    if (erro != null) {
      mostrarToast(context, mensagem: erro, erro: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  /// Faz a escrita conforme o que o formulario tem: enquete, aviso com
  /// midia (sobe os arquivos primeiro) ou aviso so de texto.
  Future<String?> _escrever() async {
    if (_enquete) {
      return widget.postViewModel.publicarEnquete(
        pergunta: _pergunta.text,
        opcoes: _opcoes.map((o) => o.text).toList(),
        autor: widget.autor,
      );
    }

    if (!_temMidia) {
      return widget.postViewModel.publicarAviso(texto: _texto.text, autor: widget.autor);
    }

    final envioDaFoto = await _subir(_foto);
    if (envioDaFoto.erro != null) return envioDaFoto.erro;

    final envioDoVideo = await _subir(_video);
    if (envioDoVideo.erro != null) return envioDoVideo.erro;

    return widget.postViewModel.publicarMidia(
      texto: _texto.text,
      autor: widget.autor,
      fotoUrl: envioDaFoto.url,
      videoUrl: envioDoVideo.url,
    );
  }

  Future<({String? url, String? erro})> _subir(_MidiaEscolhida? midia) async {
    if (midia == null) return (url: null, erro: null);

    return widget.postViewModel.enviarMidia(
      uid: widget.autor.uid,
      bytes: midia.bytes,
      contentType: midia.contentType,
      extensao: midia.extensao,
    );
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
                  ? 'Como admin, seu post fica no topo do feed — e você pode anexar foto e vídeo.'
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CampoMultilinha(
          isDark: isDark,
          controller: _texto,
          hint: widget.autor.ehAdmin
              ? 'O que você quer avisar pra galera?'
              : 'O que você quer dizer pra galera?',
          linhas: 5,
          limite: limiteCaracteresAviso,
        ),
        if (widget.autor.ehAdmin) ...[
          const SizedBox(height: 14),
          _barraDeAnexos(isDark),
          if (_foto != null) ...[
            const SizedBox(height: 12),
            _previaDaFoto(isDark),
          ],
          if (_video != null) ...[
            const SizedBox(height: 12),
            _previaDoVideo(isDark),
          ],
        ],
      ],
    );
  }

  Widget _barraDeAnexos(bool isDark) {
    return Row(
      children: [
        _BotaoAnexo(
          icone: Icons.image_outlined,
          label: _foto == null ? 'Foto' : 'Trocar foto',
          isDark: isDark,
          onTap: _escolhendoMidia ? null : () => _escolherMidia(ehVideo: false),
        ),
        const SizedBox(width: 10),
        _BotaoAnexo(
          icone: Icons.videocam_outlined,
          label: _video == null ? 'Vídeo' : 'Trocar vídeo',
          isDark: isDark,
          onTap: _escolhendoMidia ? null : () => _escolherMidia(ehVideo: true),
        ),
        if (_escolhendoMidia) ...[
          const SizedBox(width: 12),
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AuthTheme.linkDark : AuthTheme.linkLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _previaDaFoto(bool isDark) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(_foto!.bytes, width: double.infinity, height: 180, fit: BoxFit.cover),
        ),
        Positioned(top: 6, right: 6, child: _BotaoRemoverAnexo(onTap: () => setState(() => _foto = null))),
      ],
    );
  }

  /// O vídeo não é reproduzido aqui: prévia é só a confirmação de qual
  /// arquivo foi escolhido, com o botão de tirar. Quem toca o vídeo é o
  /// card do feed depois de publicado.
  Widget _previaDoVideo(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AuthTheme.inputBgDark : AuthTheme.inputBgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.movie_outlined, size: 20, color: AuthTheme.inputTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _video!.nome,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 14, color: AuthTheme.inputTextColor),
            ),
          ),
          _BotaoRemoverAnexo(onTap: () => setState(() => _video = null)),
        ],
      ),
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

/// Arquivo escolhido na galeria e ainda nao enviado. Guarda os bytes junto
/// porque no Web nao existe caminho de arquivo pra reler depois.
class _MidiaEscolhida {
  final Uint8List bytes;
  final String contentType;
  final String extensao;
  final String nome;

  const _MidiaEscolhida({
    required this.bytes,
    required this.contentType,
    required this.extensao,
    required this.nome,
  });
}

String _extensaoDoArquivo(String nome, String padrao) {
  final ponto = nome.lastIndexOf('.');
  if (ponto == -1 || ponto == nome.length - 1) return padrao;
  return nome.substring(ponto + 1).toLowerCase();
}

class _BotaoAnexo extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _BotaoAnexo({required this.icone, required this.label, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = isDark ? AuthTheme.linkDark : AuthTheme.linkLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withOpacity(onTap == null ? .3 : .8), width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 17, color: cor),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: cor),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoRemoverAnexo extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoRemoverAnexo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }
}
