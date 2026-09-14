import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../i18n/Idioma.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ptk_plays/components/CampoFlutuante.dart';
import 'package:ptk_plays/components/FundoPTK.dart';
import 'package:ptk_plays/components/ModalCropFoto.dart';
import 'package:ptk_plays/components/Responsive.dart';
import 'package:ptk_plays/components/SeletorAvatarPreset.dart';
import 'package:ptk_plays/components/Toast.dart';
import 'package:ptk_plays/utils/AuthTheme.dart';
import 'package:ptk_plays/utils/MascaraTelefoneWhatsapp.dart';
import 'package:ptk_plays/utils/ValidacaoCadastro.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import 'package:ptk_plays/view/Home.dart';
import '../utils/DiagnosticoDeErro.dart';

/// As telas do cadastro, na ordem em que aparecem.
enum EtapaCadastro { boasVindas, nickname, email, senha, foto, whatsapp }

/// Cores do formulário do cadastro. Fixas de propósito: essa é a única tela
/// do app sem troca de tema, e o conteúdo vive sempre sobre a parte branca
/// da onda (ver `FundoPTK`).
const Color corDeTituloDoCadastro = Color(0xFF2D1B4E);
const Color corDeApoioDoCadastro = Color(0xFF6E5B92);

/// Acima disso a tela troca a onda (pensada pra celular, retrato) por um
/// cartão de duas colunas: formulário à esquerda, a arte do PTK num painel
/// próprio à direita — sem disputa de espaço entre texto e curva, que é o
/// problema que a onda resolve só na tela estreita. Cobre notebook,
/// desktop e tablet em paisagem; abaixo disso continua celular/tablet
/// retrato com a onda de sempre.
const double larguraDoCadastroDesktop = 900;

/// Domínio que a Apple usa quando a pessoa escolhe "Hide My Email" na folha
/// do Sign in with Apple: em vez do endereço real, ela entrega um relay que
/// reencaminha pra ele.
const String _dominioRelayDaApple = '@privaterelay.appleid.com';

/// Se o cadastro social ainda precisa perguntar o e-mail.
///
/// Google sempre entrega o endereço real, e a Apple entrega quando a pessoa
/// escolhe "Share My Email" — nesses casos não há o que perguntar, o e-mail
/// já está no Firebase Auth e vai pro Firestore junto.
///
/// **O caso que obriga a etapa a existir** é o "Hide My Email" da Apple: o
/// que chega é um relay `@privaterelay.appleid.com`, que reencaminha mas não
/// serve pra contato nem pra reconhecer a pessoa. Sem perguntar, a conta
/// ficaria pra sempre sem um e-mail de verdade.
bool precisaPedirEmail({required bool contaSocial, String? emailDoProvedor}) {
  if (!contaSocial) return true;
  final email = emailDoProvedor?.trim().toLowerCase() ?? '';
  return email.isEmpty || email.endsWith(_dominioRelayDaApple);
}

/// Quais etapas o cadastro tem. Quem entrou pelo Google/Apple já teve senha
/// resolvida pelo provedor, então essa etapa some — pedir de novo seria
/// pedir uma segunda senha pra mesma conta.
///
/// A de e-mail é diferente: ela some só quando o provedor entregou um
/// endereço utilizável (ver [precisaPedirEmail]).
List<EtapaCadastro> etapasDoCadastro({required bool contaSocial, bool pedirEmail = true}) {
  return [
    EtapaCadastro.boasVindas,
    EtapaCadastro.nickname,
    if (!contaSocial || pedirEmail) EtapaCadastro.email,
    if (!contaSocial) EtapaCadastro.senha,
    EtapaCadastro.foto,
    EtapaCadastro.whatsapp,
  ];
}

/// Se o botão "Avançar" deve **aparecer** nesta etapa.
///
/// Diferente de estar habilitado: o "Avançar" some enquanto a etapa não tem
/// nem o mínimo preenchido, e surge quando tem. A ideia veio de UX — o olho
/// nota mudança na tela antes de ler qualquer aviso, então o botão surgindo
/// diz "é por aqui" melhor que um botão cinza parado, que a pessoa nem
/// registra que mudou de estado.
///
/// Os limiares aqui são de **aparecer**, e são propositalmente mais frouxos
/// que os de validar: no nick o botão surge na 2ª letra mas só libera na 3ª,
/// e no e-mail basta um "@" pra ele aparecer. Quando aparece sem estar
/// válido, ele aparece desabilitado — e aí o aviso embaixo do campo diz o
/// que falta. As duas coisas juntas é que guiam; o botão sozinho não
/// explicaria, e o aviso sozinho não chamaria atenção.
bool avancarVisivel({
  required EtapaCadastro etapa,
  required String nickname,
  required String email,
  required String senha,
  required bool temFoto,
  required String whatsapp,
}) {
  switch (etapa) {
    // Não tem o que preencher: o botão é a única saída da tela.
    case EtapaCadastro.boasVindas:
      return true;
    case EtapaCadastro.nickname:
      return nickname.trim().length >= minimoParaMostrarAvancar;
    case EtapaCadastro.email:
      return email.contains('@');
    case EtapaCadastro.senha:
      return senha.length >= minimoCaracteresSenha;
    case EtapaCadastro.foto:
      return temFoto;
    // O WhatsApp é opcional: vazio significa "vou pular", e quem resolve
    // isso é o botão Pular, não o Avançar. O Avançar só faz sentido com o
    // número inteiro — pela metade ele não chamaria ninguém.
    case EtapaCadastro.whatsapp:
      return whatsappCompleto(whatsapp);
  }
}

/// A arte do PTK que fica ao fundo de cada etapa. Etapas sem arte definida
/// ainda caem no gradiente do app (ver [FundoPTK]).
///
/// São WebP com transparência, e não os JPEGs de antes: com o fundo do
/// desenho recortado, o PTK se funde no gradiente da tela em vez de aparecer
/// dentro de um retângulo com emenda visível. O WebP é o formato porque o
/// PNG equivalente passava de 1 MB por arte.
String? assetDaEtapa(EtapaCadastro etapa) {
  switch (etapa) {
    case EtapaCadastro.nickname:
      return 'assets/ptk/ptk_nickname.webp';
    case EtapaCadastro.email:
      return 'assets/ptk/ptk_email.webp';
    case EtapaCadastro.senha:
      return 'assets/ptk/ptk_senha.webp';
    case EtapaCadastro.foto:
      return 'assets/ptk/ptk_foto.webp';
    case EtapaCadastro.whatsapp:
      return 'assets/ptk/ptk_whatsapp.webp';
    // Boas-vindas ainda nao tem arte propria: cai no gradiente do app.
    case EtapaCadastro.boasVindas:
      return null;
  }
}

/// Cadastro em etapas: uma pergunta por tela, com a arte do PTK ao fundo
/// mudando junto. Só dá pra avançar com a etapa atual preenchida — o botão
/// "Avançar" fica desabilitado até lá, e cada campo avisa o que falta
/// enquanto a pessoa digita (ver [CampoFlutuante]).
class CriarConta extends StatefulWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKey;
  final AuthViewModel authViewModel;

  /// true quando a pessoa já entrou pelo Google/Apple e está só completando
  /// o perfil: pula e-mail e senha.
  final bool contaSocial;

  /// Nick sugerido pelo provedor social (o nome da conta Google/Apple), pra
  /// já vir preenchido em vez de campo em branco.
  final String? nicknameSugerido;

  /// E-mail que o provedor entregou. Decide se a etapa de e-mail aparece —
  /// ver [precisaPedirEmail].
  final String? emailDoProvedor;

  const CriarConta({
    super.key,
    required this.viewmodelYT,
    required this.apiKey,
    required this.authViewModel,
    this.contaSocial = false,
    this.nicknameSugerido,
    this.emailDoProvedor,
  });

  @override
  State<CriarConta> createState() => _CriarContaState();
}

class _CriarContaState extends State<CriarConta> {
  late final List<EtapaCadastro> _etapas = etapasDoCadastro(
    contaSocial: widget.contaSocial,
    pedirEmail: precisaPedirEmail(
      contaSocial: widget.contaSocial,
      emailDoProvedor: widget.emailDoProvedor,
    ),
  );
  final _paginas = PageController();
  int _indice = 0;

  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _confirmarEmail = TextEditingController();
  final _senha = TextEditingController();
  final _whatsapp = TextEditingController();

  String? _avatarPreset;
  Uint8List? _fotoPropria;
  bool _escolhendoFoto = false;
  bool _criando = false;

  EtapaCadastro get _etapaAtual => _etapas[_indice];

  @override
  void initState() {
    super.initState();
    _whatsapp.text = MascaraTelefoneWhatsapp.mascaraVazia;
    if (widget.nicknameSugerido != null) _nickname.text = widget.nicknameSugerido!;
  }

  @override
  void dispose() {
    _paginas.dispose();
    for (final campo in [_nickname, _email, _confirmarEmail, _senha, _whatsapp]) {
      campo.dispose();
    }
    super.dispose();
  }

  /// O que ainda falta na etapa atual, ou null se ela está completa. É o
  /// mesmo conjunto de regras que os campos usam pra avisar enquanto a
  /// pessoa digita — aqui elas decidem se o "Avançar" libera.
  String? _pendenciaDaEtapa(EtapaCadastro etapa) {
    switch (etapa) {
      case EtapaCadastro.boasVindas:
        return null;
      case EtapaCadastro.nickname:
        return validarNickname(_nickname.text);
      case EtapaCadastro.email:
        return validarEmail(_email.text) ??
            validarConfirmacaoEmail(email: _email.text, confirmacao: _confirmarEmail.text);
      case EtapaCadastro.senha:
        return validarSenha(_senha.text);
      case EtapaCadastro.foto:
        return validarFotoEscolhida(avatarPreset: _avatarPreset, temFotoPropria: _fotoPropria != null);
      case EtapaCadastro.whatsapp:
        return validarWhatsappOpcional(_whatsapp.text);
    }
  }

  bool get _podeAvancar => _pendenciaDaEtapa(_etapaAtual) == null;

  bool get _avancarVisivel => avancarVisivel(
        etapa: _etapaAtual,
        nickname: _nickname.text,
        email: _email.text,
        senha: _senha.text,
        temFoto: _avatarPreset != null || _fotoPropria != null,
        whatsapp: _whatsapp.text,
      );

  /// "Pular" só existe na etapa do WhatsApp, a única opcional. Ele aparece
  /// mesmo com o número já digitado: quem se arrependeu de informar precisa
  /// de uma saída que não seja apagar o campo dígito por dígito.
  bool get _podePular => _etapaAtual == EtapaCadastro.whatsapp;

  /// Conclui sem o número. Limpa o campo antes porque ele pode estar
  /// preenchido pela metade — e meio número salvo seria pior que nenhum.
  void _pular() {
    if (_criando) return;
    _whatsapp.text = MascaraTelefoneWhatsapp.mascaraVazia;
    _avancar(ignorarPendencia: true);
  }
  bool get _ehUltimaEtapa => _indice == _etapas.length - 1;

  void _avancar({bool ignorarPendencia = false}) {
    if (!ignorarPendencia && !_podeAvancar) return;
    if (_ehUltimaEtapa) {
      _criarConta();
      return;
    }

    setState(() => _indice++);
    _sincronizarPagina();
  }

  void _voltar() {
    if (_indice == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _indice--);
    _sincronizarPagina();
  }

  /// Anima o `PageView` do layout de celular pra `_indice`. No desktop não
  /// existe `PageView` nenhum (ver `_buildDesktop`) — sem cliente anexado,
  /// `animateToPage` lançaria erro; `hasClients` é o que deixa `_avancar` e
  /// `_voltar` funcionarem nos dois layouts sem saber qual está montado. O
  /// `AnimatedSwitcher` do desktop já reage sozinho à mudança de `_indice`.
  void _sincronizarPagina() {
    if (!_paginas.hasClients) return;
    _paginas.animateToPage(_indice, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  /// Tira uma selfie (ou escolhe da galeria) e manda pro mesmo recorte com
  /// zoom que a edição de perfil usa.
  Future<void> _escolherFoto(ImageSource origem) async {
    setState(() => _escolhendoFoto = true);

    try {
      final arquivo = await ImagePicker().pickImage(source: origem, maxWidth: 1600, imageQuality: 90);
      if (arquivo == null || !mounted) return;

      final bytesOriginais = await arquivo.readAsBytes();
      if (!mounted) return;

      final recortada = await ModalCropFoto.abrir(context, bytesOriginais);
      if (recortada == null || !mounted) return;

      // A foto tirada passa a ser o avatar: o preset sai de cena, igual à
      // regra de exibição (preset tem prioridade sobre fotoUrl).
      setState(() {
        _fotoPropria = recortada;
        _avatarPreset = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Falha de camera/galeria vem do lado nativo (`plataforma/...`), e o
      // codigo distingue "o usuario negou a permissao" de "o aparelho nao
      // tem camera" — que pedem respostas opostas de quem for ajudar.
      mostrarToast(context, mensagem: comCodigo(textos.cadastroCameraFalhou, e), erro: true);
    } finally {
      if (mounted) setState(() => _escolhendoFoto = false);
    }
  }

  Future<void> _criarConta() async {
    setState(() => _criando = true);

    // Conta social JÁ EXISTE — o provedor a criou no login. Chamar
    // `cadastrar` aqui (que era o que acontecia até 13/set) vira
    // `createUserWithEmailAndPassword('', '')`, porque neste fluxo os campos
    // de e-mail e senha nem chegam a ser exibidos. O cadastro social não
    // tinha como ser concluído: quem entrava pela Apple ficava preso na
    // última etapa.
    final erro = widget.contaSocial
        ? await widget.authViewModel.completarCadastroSocial(
            nickname: _nickname.text.trim(),
            telefoneWhatsapp: MascaraTelefoneWhatsapp.paraSalvar(_whatsapp.text),
            avatarPreset: _avatarPreset ?? '',
            emailInformado: _email.text.trim(),
          )
        : await widget.authViewModel.cadastrar(
            nickname: _nickname.text.trim(),
            email: _email.text.trim(),
            senha: _senha.text,
            telefoneWhatsapp: MascaraTelefoneWhatsapp.paraSalvar(_whatsapp.text),
            avatarPreset: _avatarPreset ?? '',
          );

    if (!mounted) return;

    if (erro != null) {
      setState(() => _criando = false);
      mostrarToast(context, mensagem: erro, erro: true);
      return;
    }

    // A foto sobe depois da conta existir: o caminho no Storage é por uid,
    // que só existe a partir daqui.
    if (_fotoPropria != null) {
      final envio = await widget.authViewModel.atualizarFotoPerfil(bytes: _fotoPropria!);
      if (!mounted) return;
      if (envio.erro != null) {
        // Conta criada, foto não subiu: não vale barrar a entrada por causa
        // disso — a pessoa troca a foto depois na edição de perfil.
        mostrarToast(
          context,
          mensagem: textos.cadastroFotoNaoSubiu,
          erro: true,
        );
      }
    }

    if (!mounted) return;
    setState(() => _criando = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(
          viewmodelYT: widget.viewmodelYT,
          apiKEY: widget.apiKey,
          authViewModel: widget.authViewModel,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculado aqui fora, e não dentro do LayoutBuilder: é o mesmo lugar
    // de sempre, antes da versão desktop existir. MediaQuery.viewInsetsOf
    // registra a dependência no context de quem chama — mover essa
    // chamada pra dentro do builder do LayoutBuilder (um context mais
    // interno, recriado a cada layout) mudava onde o Flutter reconhece a
    // dependência, e o rebuild do "some" do subtítulo parava de disparar
    // no teste do teclado.
    final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Esta tela não tem botão de trocar tema, de propósito: é a única do
    // app com identidade visual própria (arte + onda branca no celular,
    // cartão de duas colunas no desktop), e o formulário vive sempre sobre
    // o branco. Por isso as cores aqui são fixas, e não vêm do
    // ThemeController.
    return Scaffold(
      // LayoutBuilder, e não MediaQuery, pra decidir o layout: com o
      // teclado aberto o Scaffold encolhe o corpo, e é essa altura menor
      // que a onda usa pra se desenhar (no layout de celular). A largura
      // que ele mede é a mesma que decide qual dos dois layouts entra em
      // cena.
      body: LayoutBuilder(
        builder: (context, restricoes) {
          if (restricoes.maxWidth >= larguraDoCadastroDesktop) {
            return _buildDesktop(restricoes);
          }
          return _buildMobile(restricoes, tecladoAberto);
        },
      ),
    );
  }

  /// Celular e tablet em retrato: arte do PTK no alto, onda branca subindo
  /// de baixo com o formulário sobre ela. O layout original da tela —
  /// inalterado desde antes da versão desktop existir.
  Widget _buildMobile(BoxConstraints restricoes, bool tecladoAberto) {
    final onda = ondaDaEtapa(_indice, tecladoAberto: tecladoAberto);
    final altura = restricoes.maxHeight;

    // O texto começa logo abaixo do **cume** da onda (a metade mais
    // alta da curva), encostado naquele lado — um bloco que não ocupa
    // a largura toda não precisa esperar a curva descer do outro
    // lado. É o que tira o vazio que sobrava entre a onda e o título.
    final topoDoTexto = altura * onda.topoDoTexto(fracaoDeFolga: tecladoAberto ? .03 : .04);

    // Já os campos têm largura cheia, então precisam esperar a curva
    // inteira passar. A distância entre um e outro vira a altura
    // mínima do cabeçalho, pra um título curto não deixar os campos
    // subirem pra cima da curva.
    final topoDosCampos = altura * onda.topoDoConteudo(fracaoDeFolga: tecladoAberto ? .06 : .12);

    // Se o PageView acabou de remontar depois de um tempo sem cliente
    // nenhum anexado (a pessoa navegou entre etapas com o cartão desktop
    // aberto, sem PageView, e depois estreitou a janela), ele reabriria
    // sozinho na primeira página — o controller não guarda posição de uma
    // vez pra outra que remonta. Sincroniza com `_indice` assim que o
    // layout terminar; `jumpToPage` não anima, então não compete com a
    // transição de entrada da tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_paginas.hasClients) return;
      if (_paginas.page?.round() != _indice) _paginas.jumpToPage(_indice);
    });

    return Stack(
      children: [
        FundoPTK(
          asset: assetDaEtapa(_etapaAtual),
          onda: onda,
          // A etapa de boas-vindas não tem arte do PTK: no lugar dela
          // vai a logo do canal, que é o que a pessoa reconhece antes
          // mesmo de ler o texto. É a versão sem o fundo roxo quadrado
          // (o `login_logo.png` continua com fundo, porque lá ele é
          // recortado num círculo e o quadrado nunca aparece).
          logo: _etapaAtual == EtapaCadastro.boasVindas ? 'assets/ptk/ptk_logo.webp' : null,
        ),

        // O formulário ocupa a parte branca, abaixo da onda. O `bottom: 0`
        // já respeita o teclado, porque o Scaffold encolhe o corpo — é o
        // que mantém os campos visíveis com o teclado aberto.
        AnimatedPositioned(
          // Mesma duração e curva da onda: o formulário sobe junto com o
          // "líquido", em vez de saltar pro lugar antes dela chegar.
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          top: topoDoTexto,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: ResponsiveCenter(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _paginas,
                      // A navegação é só pelos botões: arrastar pularia a
                      // checagem que impede avançar com a etapa incompleta.
                      physics: const NeverScrollableScrollPhysics(),
                      children: _etapas
                          .map(
                            (etapa) => _conteudoDaEtapa(
                              etapa,
                              tecladoAberto: tecladoAberto,
                              alturaDoCabecalho: topoDosCampos - topoDoTexto,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  _barraDeBotoes(),
                ],
              ),
            ),
          ),
        ),

        // As bolinhas ficam sobre a arte, no alto: ali elas não roubam
        // espaço do formulário. Com o teclado aberto a onda cobre esse
        // pedaço, então elas trocam pro tom escuro — brancas sobre branco
        // sumiriam.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _IndicadorDeEtapas(
              total: _etapas.length,
              atual: _indice,
              sobreFundoClaro: tecladoAberto,
            ),
          ),
        ),
      ],
    );
  }

  /// Notebook, desktop e tablet em paisagem: um cartão de duas colunas
  /// centralizado na tela, sem a onda — ela existe pra brigar por espaço
  /// numa tela estreita, e aqui esse espaço sobra. O formulário ocupa a
  /// coluna da esquerda; a arte do PTK vira um painel próprio à direita,
  /// com o mesmo gradiente e a mesma arte da versão celular, só que sem a
  /// curva — o contorno arredondado sai do cartão inteiro, via `ClipRRect`.
  ///
  /// Sem `PageView` aqui. Ele reaparece de vez em quando (ver
  /// `_buildMobile`), e um controller compartilhado entre dois `PageView`s
  /// que entram e saem de cena reabriria sempre na primeira página ao
  /// remontar. Um `AnimatedSwitcher` trocando pelo `_etapaAtual` não
  /// depende de posição nenhuma guardada — `_avancar`/`_voltar` continuam
  /// sendo a única forma de navegar, idêntico ao celular.
  Widget _buildDesktop(BoxConstraints restricoes) {
    final largura = math.min(restricoes.maxWidth * .84, 1180.0);
    final altura = (restricoes.maxHeight * .88).clamp(520.0, 760.0);

    return ColoredBox(
      // O mesmo lilás claro do preenchimento dos campos (CampoFlutuante) —
      // reaproveitar o tom em vez de inventar um novo é o que faz o cartão
      // branco se destacar do fundo sem introduzir uma cor nova na tela.
      color: const Color(0xFFF4F0FA),
      child: Center(
        child: SizedBox(
          width: largura,
          height: altura,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // A sombra fica no Container de fora: se estivesse dentro do
              // ClipRRect, o próprio clip cortaria o BoxShadow (que se
              // espalha além dos limites do cartão) e ela nunca apareceria.
              boxShadow: const [BoxShadow(color: Color(0x1F2D1B4E), blurRadius: 44, offset: Offset(0, 22))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 36, bottom: 12),
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (filho, animacao) =>
                                    FadeTransition(opacity: animacao, child: filho),
                                // A key troca com a etapa, mesmo quando duas
                                // etapas seguidas usam o mesmo tipo de widget
                                // (_Etapa) — sem ela o AnimatedSwitcher não
                                // percebe que o conteúdo mudou.
                                child: KeyedSubtree(
                                  key: ValueKey(_etapaAtual),
                                  child: _conteudoDaEtapa(
                                    _etapaAtual,
                                    tecladoAberto: false,
                                    alturaDoCabecalho: 0,
                                    desktop: true,
                                  ),
                                ),
                              ),
                            ),
                            _barraDeBotoes(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: FundoPTK(
                      asset: assetDaEtapa(_etapaAtual),
                      onda: ondaInteira,
                      desenharOnda: false,
                      alturaDaArte: .92,
                      logo: _etapaAtual == EtapaCadastro.boasVindas ? 'assets/ptk/ptk_logo.webp' : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudoDaEtapa(
    EtapaCadastro etapa, {
    required bool tecladoAberto,
    required double alturaDoCabecalho,
    bool desktop = false,
  }) {
    // Repassado a toda etapa: é o que faz o texto se encostar no lado do
    // cume, o subtítulo sumir enquanto a pessoa digita, e os campos
    // começarem sempre abaixo da curva inteira — ou, no desktop, que troca
    // tudo isso por título grande e subtítulo inteiro, sem disputa de
    // espaço com onda nenhuma (ver `_EstiloDaEtapa.desktop`).
    final estilo = _EstiloDaEtapa(
      // O cume vem da onda **da etapa**, não da onda do momento: com o
      // teclado aberto a onda vira a `ondaCheia` e o cume dela muda de lado,
      // o que faria o título quebrar de outro jeito no meio da digitação.
      // No desktop isso nem chega a ser lido (ver `desktop` abaixo), mas
      // continua vindo de um lugar consistente com o celular.
      cumeEhAEsquerda: ondaDaEtapa(_indice).cumeEhAEsquerda,
      tecladoAberto: tecladoAberto,
      alturaDoCabecalho: alturaDoCabecalho,
      desktop: desktop,
      numeroDaEtapa: _indice + 1,
      totalDeEtapas: _etapas.length,
    );

    switch (etapa) {
      case EtapaCadastro.boasVindas:
        return _EtapaBoasVindas(estilo: estilo);

      case EtapaCadastro.nickname:
        return _Etapa(
          estilo: estilo,
          titulo: textos.cadastroNickTitulo,
          subtitulo: textos.cadastroNickTexto,
          subtituloCurto: textos.cadastroNickCurto,
          campos: [
            CampoFlutuante(
              controller: _nickname,
              rotulo: textos.cadastroNickCampo,
              icone: Icons.person_outline,
              capitalizacao: TextCapitalization.words,
              validador: validarNickname,
              onMudou: () => setState(() {}),
            ),
          ],
        );

      case EtapaCadastro.email:
        return _Etapa(
          estilo: estilo,
          titulo: textos.cadastroEmailTitulo,
          subtitulo: textos.cadastroEmailTexto,
          subtituloCurto: textos.cadastroEmailCurto,
          campos: [
            CampoFlutuante(
              controller: _email,
              rotulo: textos.email,
              icone: Icons.mail_outline,
              tipoDeTeclado: TextInputType.emailAddress,
              validador: validarEmail,
              onMudou: () => setState(() {}),
            ),
            CampoFlutuante(
              controller: _confirmarEmail,
              rotulo: textos.cadastroConfirmeEmail,
              icone: Icons.mark_email_read_outlined,
              tipoDeTeclado: TextInputType.emailAddress,
              validador: (valor) => validarConfirmacaoEmail(email: _email.text, confirmacao: valor),
              onMudou: () => setState(() {}),
            ),
          ],
        );

      case EtapaCadastro.senha:
        return _Etapa(
          estilo: estilo,
          titulo: textos.cadastroSenhaTitulo,
          subtitulo: textos.cadastroSenhaTexto(minimoCaracteresSenha),
          subtituloCurto: textos.cadastroSenhaCurto(minimoCaracteresSenha),
          campos: [
            CampoFlutuante(
              controller: _senha,
              rotulo: textos.senha,
              icone: Icons.lock_outline,
              ehSenha: true,
              validador: validarSenha,
              onMudou: () => setState(() {}),
            ),
          ],
        );

      case EtapaCadastro.foto:
        return _EtapaFoto(
          estilo: estilo,
          avatarPreset: _avatarPreset,
          fotoPropria: _fotoPropria,
          escolhendo: _escolhendoFoto,
          onSelecionarPreset: (chave) => setState(() {
            _avatarPreset = chave;
            _fotoPropria = null;
          }),
          onTirarFoto: () => _escolherFoto(ImageSource.camera),
          onEscolherDaGaleria: () => _escolherFoto(ImageSource.gallery),
        );

      case EtapaCadastro.whatsapp:
        return _Etapa(
          estilo: estilo,
          titulo: textos.cadastroWhatsappTitulo,
          subtitulo: textos.cadastroWhatsappTexto,
          subtituloCurto: textos.cadastroWhatsappCurto,
          campos: [
            CampoFlutuante(
              controller: _whatsapp,
              rotulo: textos.cadastroWhatsappCampo,
              icone: Icons.phone_outlined,
              tipoDeTeclado: TextInputType.phone,
              formatadores: [MascaraTelefoneWhatsapp()],
              validador: validarWhatsappOpcional,
              onMudou: () => setState(() {}),
            ),
          ],
        );
    }
  }

  Widget _barraDeBotoes() {
    return Padding(
      // 16 de folga lateral, e não 24: na última etapa a barra carrega três
      // controles ("Voltar", "Pular" e "Criar conta", que é o rótulo mais
      // largo do fluxo) e estourava por 42px num aparelho de 420 de largura
      // — faixa de celular comum, não caso extremo.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          // Flexible + ellipsis: o "Voltar" é quem cede espaço quando os
          // três não cabem. Ele é o controle menos importante da barra, e
          // ainda sobra a seta pra dizer o que ele faz.
          Flexible(
            child: TextButton.icon(
              onPressed: _criando ? null : _voltar,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(
                _indice == 0 ? textos.sair : textos.voltar,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: corDeApoioDoCadastro),
            ),
          ),
          const Spacer(),
          // "Pular" fica colado no Avançar de propósito: é ali que o polegar
          // já está, e é ali que a pessoa procura a saída da etapa. Discreto
          // (texto, sem fundo, cor de apoio) pra não competir com a ação
          // principal — quem quer informar o número deve ver o Avançar
          // primeiro.
          if (_podePular)
            TextButton(
              onPressed: _criando ? null : _pular,
              style: TextButton.styleFrom(
                foregroundColor: corDeApoioDoCadastro,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                textos.pular,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          if (_podePular) const SizedBox(width: 4),
          // O botão aparece e some conforme a etapa passa a ter o mínimo
          // preenchido. A escala junto com o fade é o que faz o olho
          // registrar — só opacidade passa despercebido no canto da tela.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (filho, animacao) => FadeTransition(
              opacity: animacao,
              child: ScaleTransition(scale: Tween(begin: .8, end: 1.0).animate(animacao), child: filho),
            ),
            child: _avancarVisivel
                ? _BotaoAvancar(
                    key: const ValueKey('avancar'),
                    label: _ehUltimaEtapa ? textos.criarConta : textos.avancar,
                    habilitado: _podeAvancar,
                    carregando: _criando,
                    onTap: _avancar,
                  )
                // SizedBox vazio, e não `null`: sem um filho com tamanho o
                // AnimatedSwitcher colapsa a Row e o "Pular" pula de lugar
                // no meio da animação.
                : const SizedBox(key: ValueKey('sem-avancar'), height: 52),
          ),
        ],
      ),
    );
  }
}

/// O que a onda e o teclado ditam pro conteúdo de cada etapa.
///
/// O texto fica **sempre à esquerda**, em toda etapa: alternar o lado a cada
/// tela cansava a leitura. O que o cume muda é o quanto de espaço o texto
/// tem em cima da esquerda, e daí saem as três diferenças abaixo —
/// quebra de linha, tamanho da fonte e tamanho do subtítulo.
class _EstiloDaEtapa {
  /// De que lado a onda subiu mais.
  ///
  /// Cume à esquerda: sobra bastante branco no alto da esquerda, o título
  /// nasce lá em cima e pode quebrar em duas linhas com folga.
  ///
  /// Cume à direita: a curva desce do lado esquerdo, então o título nasce
  /// mais baixo, com menos altura disponível — daí a fonte menor e o
  /// subtítulo resumido, pra tudo caber antes dos campos.
  final bool cumeEhAEsquerda;

  final bool tecladoAberto;

  /// Altura reservada pro cabeçalho, medida entre o topo do texto e o
  /// ponto em que os campos podem começar. Garante que um título curto não
  /// deixe os campos subirem pra cima da curva.
  final double alturaDoCabecalho;

  /// true no cartão da versão desktop (`_CriarContaState._buildDesktop`).
  /// Desliga toda a lógica pensada pra disputar espaço com a onda — lá não
  /// existe onda nenhuma, e o painel do formulário tem largura e altura de
  /// sobra: título sempre no tamanho grande, sem quebra forçada, com o
  /// subtítulo inteiro.
  final bool desktop;

  /// Número da etapa atual e o total, base 1 — só usados pelo selo acima
  /// do título no desktop ("Passo 2 de 6"). No celular o mesmo papel é
  /// feito pelas bolinhas sobre a arte (`_IndicadorDeEtapas`).
  final int numeroDaEtapa;
  final int totalDeEtapas;

  const _EstiloDaEtapa({
    required this.cumeEhAEsquerda,
    required this.tecladoAberto,
    required this.alturaDoCabecalho,
    this.desktop = false,
    this.numeroDaEtapa = 0,
    this.totalDeEtapas = 0,
  });

  Alignment get alinhamento => Alignment.centerLeft;
  TextAlign get alinhamentoDoTexto => TextAlign.left;
  CrossAxisAlignment get colunaDoTexto => CrossAxisAlignment.start;

  /// Quanto da largura o cabeçalho ocupa. Com o cume à esquerda ele é mais
  /// estreito de propósito: é o que segura o texto embaixo do cume, sem
  /// esbarrar na curva descendo do outro lado. No desktop essa disputa não
  /// existe — o painel é só do formulário —, então o texto usa a largura
  /// inteira.
  double get larguraDoTexto {
    if (desktop) return 1;
    if (tecladoAberto) return 1;
    return cumeEhAEsquerda ? .70 : .84;
  }

  double get tamanhoDoTitulo {
    if (desktop) return 34;
    if (tecladoAberto) return 22;
    return cumeEhAEsquerda ? 26 : 22.5;
  }

  double get tamanhoDoSubtitulo => desktop ? 16 : 14.5;

  /// O `\n` que vem no título é a quebra pensada pro caso do cume à
  /// esquerda, onde o texto sobe e o espaço é mais estreito que alto. Com o
  /// cume à direita, ou no desktop — onde o painel é largo e baixo, o
  /// oposto da tela estreita —, a quebra sai e o título deixa a linha
  /// fluir.
  String tituloComQuebra(String titulo) {
    if (desktop) return titulo.replaceAll('\n', ' ');
    return cumeEhAEsquerda ? titulo : titulo.replaceAll('\n', ' ');
  }

  /// Com o cume à direita o cabeçalho começa mais baixo e tem menos altura
  /// até os campos, então entra a versão resumida do subtítulo. No desktop
  /// sobra altura de sobra — sempre o texto inteiro.
  String subtituloQueCabe(String longo, String curto) {
    if (desktop) return longo;
    return cumeEhAEsquerda ? longo : curto;
  }
}

/// Primeira tela: só a apresentação da comunidade, sem nada pra preencher.
class _EtapaBoasVindas extends StatelessWidget {
  final _EstiloDaEtapa estilo;

  const _EtapaBoasVindas({required this.estilo});

  @override
  Widget build(BuildContext context) {
    return _Etapa(
      estilo: estilo,
      titulo: textos.cadastroBoasVindasTitulo,
      subtitulo: textos.cadastroBoasVindasTexto,
      subtituloCurto: textos.cadastroBoasVindasCurto,
      campos: const [],
    );
  }
}

/// Cabeçalho da etapa: título sempre, subtítulo só quando o teclado está
/// fechado. Sempre à esquerda, ocupando parte da largura — é assim que ele
/// consegue subir até quase a curva.
///
/// O [subtituloCurto] é a versão que entra quando o cume está à direita e
/// sobra menos altura pro cabeçalho (ver [_EstiloDaEtapa]).
class _CabecalhoDaEtapa extends StatelessWidget {
  final _EstiloDaEtapa estilo;
  final String titulo;
  final String subtitulo;
  final String subtituloCurto;

  /// Reserva a altura entre o topo do texto e o começo dos campos, pra um
  /// título curto não deixar os campos subirem pra cima da curva. A etapa
  /// de boas-vindas não tem campos e desliga isso: lá o texto se
  /// centraliza na faixa branca inteira.
  final bool reservarAltura;

  const _CabecalhoDaEtapa({
    required this.estilo,
    required this.titulo,
    required this.subtitulo,
    required this.subtituloCurto,
    this.reservarAltura = true,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: reservarAltura ? estilo.alturaDoCabecalho.clamp(0, 400) : 0,
      ),
      child: Align(
        alignment: estilo.alinhamento,
        child: FractionallySizedBox(
          // Não ocupa a largura toda de propósito: é o que permite o texto
          // subir até o cume sem esbarrar na curva do outro lado.
          widthFactor: estilo.larguraDoTexto,
          alignment: estilo.alinhamento,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: estilo.colunaDoTexto,
            children: [
              // O selo é a versão desktop das bolinhas de progresso
              // (`_IndicadorDeEtapas`) — no celular elas ficam sobre a
              // arte; aqui, sem onda nem arte no painel do formulário, o
              // progresso precisa do próprio lugar. De quebra, dá ao
              // título o estilo "rótulo pequeno e colorido + texto grande"
              // que dá destaque sem depender de palavra nenhuma do texto.
              if (estilo.desktop) ...[
                _SeloDeEtapa(numero: estilo.numeroDaEtapa, total: estilo.totalDeEtapas),
                const SizedBox(height: 18),
              ],
              Text(
                estilo.tituloComQuebra(titulo),
                textAlign: estilo.alinhamentoDoTexto,
                style: GoogleFonts.outfit(
                  fontSize: estilo.tamanhoDoTitulo,
                  fontWeight: FontWeight.w800,
                  color: corDeTituloDoCadastro,
                  height: 1.15,
                ),
              ),
              // Com o teclado aberto o subtítulo sai de cena: o título já
              // diz o que a pessoa está preenchendo, e o espaço vale mais
              // pro campo do que pra explicação. No desktop não existe
              // teclado que cubra a tela, então isso nunca dispara.
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: estilo.tecladoAberto
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          estilo.subtituloQueCabe(subtitulo, subtituloCurto),
                          textAlign: estilo.alinhamentoDoTexto,
                          style: GoogleFonts.outfit(
                            fontSize: estilo.tamanhoDoSubtitulo,
                            color: corDeApoioDoCadastro,
                            height: 1.45,
                          ),
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

/// "PASSO 2 DE 6" acima do título, no desktop — o mesmo papel das
/// bolinhas de progresso (`_IndicadorDeEtapas`), que no celular ficam
/// sobre a arte. Aqui, sem onda nem arte no painel do formulário, o
/// progresso precisa do próprio lugar — e de quebra empresta ao título o
/// estilo "rótulo pequeno e colorido + texto grande" comum em telas de
/// onboarding, sem precisar destacar uma palavra específica de cada texto.
class _SeloDeEtapa extends StatelessWidget {
  final int numero;
  final int total;

  const _SeloDeEtapa({required this.numero, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: Color(0xFFA12EE0), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            textos.cadastroPasso(numero, total),
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFA12EE0),
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Molde comum das etapas: cabeçalho e os campos daquela pergunta.
class _Etapa extends StatelessWidget {
  final _EstiloDaEtapa estilo;
  final String titulo;
  final String subtitulo;
  final String subtituloCurto;
  final List<Widget> campos;

  const _Etapa({
    required this.estilo,
    required this.titulo,
    required this.subtitulo,
    required this.subtituloCurto,
    required this.campos,
  });

  @override
  Widget build(BuildContext context) {
    // Sem campos (boas-vindas), o texto é tudo que existe na parte branca:
    // encostá-lo no topo deixava um vazio enorme embaixo, então ele fica
    // centralizado na faixa inteira.
    if (campos.isEmpty) {
      return _RolagemDaEtapa(
        centralizar: true,
        child: _CabecalhoDaEtapa(
          estilo: estilo,
          titulo: titulo,
          subtitulo: subtitulo,
          subtituloCurto: subtituloCurto,
          reservarAltura: false,
        ),
      );
    }

    return _RolagemDaEtapa(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CabecalhoDaEtapa(
            estilo: estilo,
            titulo: titulo,
            subtitulo: subtitulo,
            subtituloCurto: subtituloCurto,
          ),
          const SizedBox(height: 16),
          ...campos,
        ],
      ),
    );
  }
}

/// Área rolável das etapas, sem barra e sem o brilho de "puxou demais".
///
/// O conteúdo é dimensionado pra caber sem rolar; a rolagem existe só como
/// rede de segurança (fonte grande do sistema, tela muito baixa). Deixar a
/// barra à mostra num formulário que cabe passa a impressão errada de que
/// há mais coisa escondida embaixo.
class _RolagemDaEtapa extends StatelessWidget {
  final Widget child;

  /// Centraliza o conteúdo na altura disponível, sem abrir mão da rolagem
  /// quando ele não couber. O `minHeight` no filho é o que faz as duas
  /// coisas conviverem: cabendo, o Center manda; não cabendo, o conteúdo
  /// passa da altura mínima e o scroll assume.
  final bool centralizar;

  const _RolagemDaEtapa({required this.child, this.centralizar = false});

  static const _margem = EdgeInsets.fromLTRB(24, 4, 24, 12);

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _SemBarraDeRolagem(),
      child: LayoutBuilder(
        builder: (context, restricoes) => SingleChildScrollView(
          padding: _margem,
          child: centralizar
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (restricoes.maxHeight - _margem.vertical).clamp(0.0, double.infinity),
                  ),
                  child: Center(child: child),
                )
              : child,
        ),
      ),
    );
  }
}

class _SemBarraDeRolagem extends ScrollBehavior {
  const _SemBarraDeRolagem();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

/// Etapa da foto: os avatares pré-definidos, ou uma foto tirada na hora.
class _EtapaFoto extends StatelessWidget {
  final _EstiloDaEtapa estilo;
  final String? avatarPreset;
  final Uint8List? fotoPropria;
  final bool escolhendo;
  final ValueChanged<String> onSelecionarPreset;
  final VoidCallback onTirarFoto;
  final VoidCallback onEscolherDaGaleria;

  const _EtapaFoto({
    required this.estilo,
    required this.avatarPreset,
    required this.fotoPropria,
    required this.escolhendo,
    required this.onSelecionarPreset,
    required this.onTirarFoto,
    required this.onEscolherDaGaleria,
  });

  @override
  Widget build(BuildContext context) {
    return _RolagemDaEtapa(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CabecalhoDaEtapa(
            estilo: estilo,
            titulo: textos.cadastroFotoTitulo,
            subtitulo: textos.cadastroFotoTexto,
            subtituloCurto: textos.cadastroFotoCurto,
          ),
          const SizedBox(height: 16),

          if (fotoPropria != null) ...[
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AuthTheme.buttonGradient),
                child: ClipOval(child: Image.memory(fotoPropria!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 18),
          ],

          Row(
            children: [
              Expanded(
                child: _BotaoDeFoto(
                  icone: Icons.photo_camera_outlined,
                  label: fotoPropria == null ? textos.cadastroTirarFoto : textos.cadastroTirarOutra,
                  carregando: escolhendo,
                  onTap: onTirarFoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BotaoDeFoto(
                  icone: Icons.photo_library_outlined,
                  label: textos.cadastroDaGaleria,
                  carregando: false,
                  onTap: onEscolherDaGaleria,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            textos.cadastroOuEscolhaAvatar,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: corDeApoioDoCadastro),
          ),
          const SizedBox(height: 12),
          SeletorAvatarPreset(
            // false porque aqui o fundo é a parte branca da onda, não o
            // gradiente escuro do resto do app.
            isDark: false,
            selecionado: avatarPreset,
            onSelecionar: onSelecionarPreset,
          ),
        ],
      ),
    );
  }
}

class _BotaoDeFoto extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool carregando;
  final VoidCallback onTap;

  const _BotaoDeFoto({
    required this.icone,
    required this.label,
    required this.carregando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: carregando ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9D0EC), width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (carregando)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: corDeTituloDoCadastro),
              )
            else
              Icon(icone, color: corDeTituloDoCadastro, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: corDeTituloDoCadastro),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bolinhas de progresso: mostram quantas etapas faltam, o que evita a
/// sensação de formulário sem fim.
class _IndicadorDeEtapas extends StatelessWidget {
  final int total;
  final int atual;

  /// true quando a onda já cobriu o topo (teclado aberto): aí as bolinhas
  /// apagadas precisam ser escuras, senão somem no branco.
  final bool sobreFundoClaro;

  const _IndicadorDeEtapas({required this.total, required this.atual, this.sobreFundoClaro = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (indice) {
          final ativo = indice <= atual;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: indice == atual ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: ativo
                  ? const Color(0xFFC33BE8)
                  : (sobreFundoClaro ? const Color(0x332D1B4E) : Colors.white24),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

/// Botão de avançar em formato de pílula com seta, desabilitado enquanto a
/// etapa não estiver completa.
class _BotaoAvancar extends StatelessWidget {
  final String label;
  final bool habilitado;
  final bool carregando;
  final VoidCallback onTap;

  const _BotaoAvancar({
    super.key,
    required this.label,
    required this.habilitado,
    required this.carregando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ativo = habilitado && !carregando;

    return GestureDetector(
      onTap: ativo ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ativo ? 1 : .45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: AuthTheme.buttonGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x66C828B4), blurRadius: 22, offset: Offset(0, 10))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
              ),
              const SizedBox(width: 8),
              if (carregando)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
