import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Campo de texto do cadastro em etapas: borda arredondada, ícone dentro do
/// campo, rótulo que sobe quando a pessoa começa a digitar (ou quando o
/// campo ganha foco) e aviso de erro embaixo, atualizado **enquanto** ela
/// digita.
///
/// O aviso em tempo real é a razão de o [validador] ser uma função pura
/// passada de fora (ver `ValidacaoCadastro.dart`): a mesma regra alimenta o
/// texto de erro daqui e a decisão de liberar o botão "Avançar" da etapa,
/// então as duas coisas nunca discordam.
///
/// Diferente do resto do app, um erro aqui **não** abre modal: o campo está
/// na frente da pessoa e o aviso embaixo dele é mais direto que um diálogo
/// pra fechar a cada tecla. A regra do CLAUDE.md (erro de formulário em
/// modal bloqueante) continua valendo pra validação no envio do formulário
/// — aqui é a checagem contínua que roda a cada caractere.
///
/// As cores são fixas em vez de seguirem o tema: o cadastro é a única tela
/// do app sem troca de tema, e o formulário dele vive sempre sobre a parte
/// branca da onda (ver `FundoPTK`).
class CampoFlutuante extends StatefulWidget {
  final TextEditingController controller;
  final String rotulo;
  final IconData icone;

  /// Regra aplicada a cada mudança do texto. Recebe o valor atual e devolve
  /// null (tudo certo) ou a mensagem de erro.
  final String? Function(String valor)? validador;

  final bool ehSenha;
  final TextInputType? tipoDeTeclado;
  final List<TextInputFormatter>? formatadores;
  final TextCapitalization capitalizacao;

  /// Chamado a cada tecla, depois do [validador] rodar — é como a etapa
  /// sabe que precisa reavaliar se o "Avançar" libera.
  final VoidCallback? onMudou;

  const CampoFlutuante({
    super.key,
    required this.controller,
    required this.rotulo,
    required this.icone,
    this.validador,
    this.ehSenha = false,
    this.tipoDeTeclado,
    this.formatadores,
    this.capitalizacao = TextCapitalization.none,
    this.onMudou,
  });

  @override
  State<CampoFlutuante> createState() => _CampoFlutuanteState();
}

class _CampoFlutuanteState extends State<CampoFlutuante> {
  final _foco = FocusNode();
  bool _senhaVisivel = false;

  /// Só aparece depois que a pessoa mexeu no campo: mostrar "preencha seu
  /// e-mail" num campo que ela ainda nem tocou seria acusar antes da hora.
  bool _jaMexeu = false;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  String? get _erro {
    if (!_jaMexeu || widget.validador == null) return null;
    return widget.validador!(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final erro = _erro;
    final temFoco = _foco.hasFocus;

    final Color corDaBorda = erro != null
        ? _corDeErro
        : temFoco
            ? _corDeDestaque
            : const Color(0xFFD9D0EC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _foco,
          obscureText: widget.ehSenha && !_senhaVisivel,
          keyboardType: widget.tipoDeTeclado,
          inputFormatters: widget.formatadores,
          textCapitalization: widget.capitalizacao,
          style: GoogleFonts.outfit(fontSize: 16, color: _corDoTexto),
          cursorColor: _corDeDestaque,
          onChanged: (_) {
            if (!_jaMexeu) _jaMexeu = true;
            setState(() {});
            widget.onMudou?.call();
          },
          decoration: InputDecoration(
            // floatingLabelBehavior.auto: o rótulo começa dentro do campo,
            // como placeholder, e sobe pra borda ao focar/digitar.
            labelText: widget.rotulo,
            labelStyle: GoogleFonts.outfit(color: _corApagada),
            floatingLabelStyle: GoogleFonts.outfit(
              color: erro != null ? _corDeErro : _corDeDestaque,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(widget.icone, color: temFoco ? _corDeDestaque : _corApagada, size: 22),
            suffixIcon: widget.ehSenha
                ? IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _corApagada,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F0FA),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            // O erro sai do InputDecoration e vira uma linha própria abaixo:
            // assim ele pode ter ícone e não empurra o layout a cada tecla.
            border: _borda(corDaBorda),
            enabledBorder: _borda(corDaBorda),
            focusedBorder: _borda(corDaBorda, largura: 1.8),
          ),
        ),
        // Altura reservada mesmo sem erro, pra linha de aviso não empurrar o
        // campo de baixo a cada caractere digitado.
        SizedBox(
          height: 26,
          child: erro == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _corDeErro, size: 15),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          erro,
                          style: GoogleFonts.outfit(fontSize: 12.5, color: _corDeErro),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  static const _corDeDestaque = Color(0xFFA12EE0);
  static const _corDeErro = Color(0xFFE0264F);
  static const _corDoTexto = Color(0xFF2D1B4E);
  static const _corApagada = Color(0xFF8A7BA8);

  OutlineInputBorder _borda(Color cor, {double largura = 1.3}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: cor, width: largura),
    );
  }
}
