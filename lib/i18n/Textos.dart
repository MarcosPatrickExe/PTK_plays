/// O catalogo de textos do app, em uma lingua.
///
/// **Por que uma classe abstrata e nao um mapa de String pra String.** Com
/// mapa, uma chave que falta numa lingua so aparece quando alguem abre
/// aquela tela naquela lingua — e o que chega na tela e `null` ou a propria
/// chave. Aqui, esquecer uma frase em `TextosEnUs` nao compila.
///
/// **Por que nao o `flutter_gen_l10n` com arquivos ARB.** O gerado exige
/// `AppLocalizations.of(context)`, e boa parte do texto deste app nasce
/// longe de um `BuildContext`: `ValidacaoCadastro`, `AuthErrorTranslator`,
/// `AuthViewModel` e os repositorios todos devolvem frase pronta. Passar
/// contexto ate la seria arrastar UI pra dentro da regra de negocio; a
/// alternativa comum, guardar o `AppLocalizations` num global, perde
/// exatamente a garantia que o ARB dava. Com esta classe, o mesmo
/// `textos.x` serve nos dois lugares.
///
/// Quem implementa: [TextosPtBr] e [TextosEnUs].
library;

abstract class Textos {
  const Textos();

  // ----- Palavras que aparecem em varias telas -----
  String get ops;
  String get fechar;
  String get cancelar;
  String get excluir;
  String get remover;
  String get voltar;
  String get sair;
  String get limpar;
  String get avancar;
  String get pular;
  String get entrar;
  String get criarConta;
  String get senha;
  String get email;
  String get nickname;
  String get cargo;
  String get status;
  String get badges;
  String get whatsapp;
  String get perfil;
  String get feed;
  String get videos;
  String get posts;
  String get cargos;
  String get privacidade;
  String get configuracoes;
  String get notificacoes;

  // ----- Erros genericos e traducao de codigo de servico -----
  String get erroGenerico;
  String get erroEmailJaCadastrado;
  String get erroEmailInvalido;
  String get erroSenhaFraca;
  String get erroLoginOuSenha;
  String get erroNicknameEmUso;
  String get erroMuitasTentativas;
  String get erroSemInternet;
  String get erroDominioNaoAutorizado;
  String get erroPopupBloqueado;
  String get erroMetodoDesabilitado;
  String get erroSemPermissao;
  String get erroSessaoExpirada;
  String get erroServidorIndisponivel;
  String get erroItemNaoExiste;
  String get erroJaExiste;
  String get erroLimiteDoServico;
  String get erroOperacaoCancelada;
  String get erroPrecisaEstarLogado;
  String get erroSessaoExpiradaCurta;
  String get erroUsuarioNaoEncontrado;
  String get erroNicknameEmUsoCurto;
  String codigoDoErro(String mensagem, String codigo);

  // ----- Login -----
  String get loginTitulo;
  String get loginCampoLogin;
  String get loginDicaLogin;
  String get loginPreenchaTudo;
  String get loginNaoTemConta;
  String get loginCliqueAqui;
  String get loginComApple;
  String get loginComGoogle;
  String get loginRecuperarSenha;
  String get erroGoogleFalhou;
  String get erroAppleFalhou;
  String get erroAppleSemConta;
  String get erroPerfilNaoSalvo;

  // ----- Cadastro em etapas -----
  String cadastroPasso(int numero, int total);
  String get cadastroBoasVindasTitulo;
  String get cadastroBoasVindasTexto;
  String get cadastroBoasVindasCurto;
  String get cadastroNickTitulo;
  String get cadastroNickTexto;
  String get cadastroNickCurto;
  String get cadastroNickCampo;
  String get cadastroEmailTitulo;
  String get cadastroEmailTexto;
  String get cadastroEmailCurto;
  String get cadastroConfirmeEmail;
  String get cadastroSenhaTitulo;
  String cadastroSenhaTexto(int minimo);
  String cadastroSenhaCurto(int minimo);
  String get cadastroFotoTitulo;
  String get cadastroFotoTexto;
  String get cadastroFotoCurto;
  String get cadastroTirarFoto;
  String get cadastroTirarOutra;
  String get cadastroDaGaleria;
  String get cadastroOuEscolhaAvatar;
  String get cadastroWhatsappTitulo;
  String get cadastroWhatsappTexto;
  String get cadastroWhatsappCurto;
  String get cadastroWhatsappCampo;
  String get cadastroCameraFalhou;
  String get cadastroFotoNaoSubiu;

  // ----- Validacao dos campos -----
  String get validaNickVazio;
  String validaNickCurto(int minimo);
  String validaNickLongo(int maximo);
  String get validaNickComArroba;
  String get validaEmailVazio;
  String get validaEmailInvalido;
  String get validaConfirmeEmailVazio;
  String get validaEmailsDiferentes;
  String get validaSenhaVazia;
  String validaSenhaCurta(int minimo);
  String get validaWhatsappIncompleto;
  String get validaWhatsappIncompletoPerfil;
  String get validaFotoFaltando;
  String get validaSenhaAtualFaltando;
  String get validaNovaSenhaCurta;
  String get validaSenhasDiferentes;
  String get validaEscolhaFoto;
  String get validaFotoInvalida;
  String get validaPreenchaTudo;

  // ----- Feed e posts -----
  String get feedNovaPublicacao;
  String get feedPublicar;
  String get feedAviso;
  String get feedEnquete;
  String get feedFoto;
  String get feedTrocarFoto;
  String get feedVideo;
  String get feedTrocarVideo;
  String get feedComoAdmin;
  String feedPublicandoComo(String nickname);
  String get feedDicaAviso;
  String get feedDicaTexto;
  String get feedDicaPergunta;
  String feedOpcaoNumero(int numero);
  String get feedRemoverOpcao;
  String get feedAdicionarOpcao;
  String get feedArquivoGrande;
  String get feedNaoCarregouAvisos;
  String get feedNenhumAviso;
  String get feedVerAntigos;
  String get feedExcluirPostTitulo;
  String get feedExcluirPostTexto;
  String get feedExcluirPost;
  String get feedPostExcluido;
  String get feedPublicado;
  String get feedAoVivo;
  String get feedCorrePraAssistir;
  String feedDurou(String duracao);
  String feedEncerradaEm(String quando);
  String feedComecouAs(String quando);
  String get feedJaVotou;
  String get feedLiveNaoAbriu;
  String get feedNaoCarregouPosts;
  String get feedNenhumPost;
  String get feedSemTexto;
  String get feedMidia;
  String get erroEnvioDeMidia;
  String get erroSoAdminLimpa;
  String get erroNaoConcluiu;
  String get erroSemPermissaoFeed;

  // ----- Validacao de post -----
  String get validaPostVazio;
  String validaAvisoLongo(int limite);
  String get validaPerguntaVazia;
  String validaPerguntaLonga(int limite);
  String validaPoucasOpcoes(int minimo);
  String validaMuitasOpcoes(int maximo);
  String get validaOpcoesRepetidas;
  String validaVideoGrande(int limiteEmMb);
  String validaImagemGrande(int limiteEmMb);

  // ----- Videos -----
  String get videosTitulo;
  String get videosNenhum;
  String get videosNaoAbriu;
  String get videosNaoCarregou;
  String videosPublicadoEm(String data);
  String videosErroCru(String erro);

  // ----- Foto e recorte -----
  String get fotoAjustar;
  String get fotoUsarEssa;
  String get fotoRecorteFalhou;
  String get fotoAtualizada;

  // ----- Perfil -----
  String get perfilEditar;
  String get perfilComoQuerSerChamado;
  String get perfilWhatsappOpcional;
  String get perfilFotoDePerfil;
  String get perfilAlterarSenha;
  String get perfilSenhaAtual;
  String get perfilNovaSenha;
  String get perfilConfirmarNovaSenha;
  String get perfilEsqueceuSenha;
  String perfilLinkEnviado(String email);
  String get perfilSalvar;
  String get perfilSalvo;
  String get perfilMembroDesde;
  String get perfilUltimoAcesso;
  String get perfilCategorias;
  String get perfilNenhumaCategoria;
  String get perfilNenhumaBadge;
  String get perfilSairDaConta;
  String get perfilExcluirConta;
  String get perfilExcluirContaTexto;
  String get perfilOnline;
  String get perfilOffline;
  String get perfilInvisivel;
  String get perfilNaoPerturbe;

  // ----- Conquistas e badges -----
  String get conquistasTitulo;
  String get conquistasProgresso;
  String get conquistasBadgesConquistadas;
  String get badgeAdministrador;
  String get badgeAdministradorTexto;
  String get badgeNovato;
  String get badgeNovatoTexto;
  String get badgeComentarista;
  String get badgeComentaristaTexto;
  String get badgePopular;
  String get badgePopularTexto;
  String get badgePresencaVip;
  String get badgePresencaVipTexto;

  // ----- Cargos e avatares -----
  String get cargoAdmin;
  String get cargoInscrito;
  String get cargoJogador;
  String get categoriaOtaku;
  String get categoriaGamer;
  String get categoriaStreamer;
  String get categoriaGeek;
  String get categoriaOutro;
  String get avatarGamer;
  String get avatarStreamer;
  String get avatarInscrito;
  String get avatarBlogueiro;
  String get avatarMaratonista;
  String get avatarOtaku;

  // ----- Menu e telas de apoio -----
  String get menuTitulo;
  String get menuPoliticaDePrivacidade;
  String get menuPainelAdm;
  String get politicaNaoAbriu;
  String get privacidadeEmBreve;
  String get configuracoesEmBreve;
  String get configuracoesIdioma;
  String get configuracoesIdiomaTexto;
  String get idiomaPortugues;
  String get idiomaIngles;

  // ----- Conta bloqueada -----
  String get bloqueioBanida;
  String get bloqueioSuspensa;
  String get bloqueioBanidaTexto;
  String bloqueioSuspensaTexto(String ate);
  String bloqueioMotivo(String motivo);
  String get bloqueioDataFutura;

  // ----- Painel do administrador -----
  String get adminTitulo;
  String get adminUsuarios;
  String get adminModeracao;
  String get adminNaoCarregouUsuarios;
  String get adminNenhumUsuario;
  String get adminVerPerfil;
  String get adminBanir;
  String get adminSuspender;
  String get adminReativar;
  String get adminMensagemPrivada;
  String get adminMensagemPrivadaEmBreve;
  String get adminRemoverUsuario;
  String get adminUsuarioAtualizado;
  String get adminNaoAtualizou;
  String adminRemoverTitulo(String nickname);
  String get adminRemoverTexto;
  String adminUsuarioRemovido(int posts);
  String get adminNaoRemoveu;
  String get adminLimparAvisosTitulo;
  String get adminLimparAvisosTexto;
  String get adminLimparAvisos;
  String get adminNenhumAvisoAntigo;
  String adminAvisosApagados(int quantos);
  String get adminNaoCarregouConversas;
  String get adminNenhumaMensagem;
  String get adminEnvioIndisponivel;
  String get adminRespostaLivre;
  String get adminForaDaJanela;
  String get adminJanelaAberta;
  String get adminJanelaFechada;
  String get adminCargosTexto;
  String get adminCargosPendencia;
  String get adminBadgesTexto;
  String get adminBadgesPendencia;
  String get adminNotificacoesTexto;
  String get adminNotificacoesPendencia;

  // ----- Mensagens do WhatsApp no painel -----
  String get whatsappVideo;
  String get whatsappAudio;
  String get whatsappLocalizacao;
  String get whatsappEnviada;
  String get whatsappEntregue;
  String get whatsappLida;
  String get whatsappFalhou;
  String whatsappFalhouCom(String erro);

  // ----- Datas e duracoes -----
  String dataHaMinutos(int minutos);
  String dataHaHoras(int horas);
  String dataHaDias(int dias);
  String duracaoHorasMinutos(int horas, int minutos);
  String duracaoMinutos(int minutos);

  // ----- Formato de data (a ordem dia/mes inverte em en-US) -----
  String dataDiaMes(String dia, String mes);
  String dataDiaMesAno(String dia, String mes, String ano);
  String dataDiaMesHora(String dia, String mes, String hora, String minuto);
  String dataDiaMesAnoHora(String dia, String mes, String ano, String hora, String minuto);
}
