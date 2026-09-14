/// Os textos do app em portugues do Brasil. E a lingua padrao: quando o
/// aparelho nao esta em portugues nem em ingles, o app cai aqui — e e
/// tambem o que os testes veem, ja que eles nao passam pela deteccao.
library;

import 'Textos.dart';

class TextosPtBr extends Textos {
  const TextosPtBr();

  // ----- Palavras que aparecem em varias telas -----
  @override
  String get ops => 'Ops!';
  @override
  String get fechar => 'Fechar';
  @override
  String get cancelar => 'Cancelar';
  @override
  String get excluir => 'Excluir';
  @override
  String get remover => 'Remover';
  @override
  String get voltar => 'Voltar';
  @override
  String get sair => 'Sair';
  @override
  String get limpar => 'Limpar';
  @override
  String get avancar => 'Avançar';
  @override
  String get pular => 'Pular';
  @override
  String get entrar => 'Entrar';
  @override
  String get criarConta => 'Criar conta';
  @override
  String get senha => 'Senha';
  @override
  String get email => 'E-mail';
  @override
  String get nickname => 'Nickname';
  @override
  String get cargo => 'Cargo';
  @override
  String get status => 'Status';
  @override
  String get badges => 'Badges';
  @override
  String get whatsapp => 'WhatsApp';
  @override
  String get perfil => 'Perfil';
  @override
  String get feed => 'Feed';
  @override
  String get videos => 'Vídeos';
  @override
  String get posts => 'Posts';
  @override
  String get cargos => 'Cargos';
  @override
  String get privacidade => 'Privacidade';
  @override
  String get configuracoes => 'Configurações';
  @override
  String get notificacoes => 'Notificações';

  // ----- Erros genericos e traducao de codigo de servico -----
  @override
  String get erroGenerico => 'Algo deu errado. Tente novamente.';
  @override
  String get erroEmailJaCadastrado => 'Esse e-mail já está cadastrado. Tente fazer login.';
  @override
  String get erroEmailInvalido => 'E-mail inválido.';
  @override
  String get erroSenhaFraca => 'A senha precisa ter pelo menos 6 caracteres.';
  @override
  String get erroLoginOuSenha => 'Login ou senha incorretos.';
  @override
  String get erroNicknameEmUso => 'Esse nickname já está em uso. Escolha outro.';
  @override
  String get erroMuitasTentativas => 'Muitas tentativas. Tente novamente mais tarde.';
  @override
  String get erroSemInternet => 'Sem conexão com a internet.';
  @override
  String get erroDominioNaoAutorizado => 'Esse domínio não está autorizado a fazer login com Google. Avise o administrador do app.';
  @override
  String get erroPopupBloqueado => 'O navegador bloqueou o popup de login. Permita popups pra esse site e tente novamente.';
  @override
  String get erroMetodoDesabilitado => 'Esse jeito de entrar não está habilitado pra o app no momento. Avise o administrador.';
  @override
  String get erroSemPermissao => 'Você não tem permissão pra fazer isso. Se você deveria ter, avise o administrador.';
  @override
  String get erroSessaoExpirada => 'Sua sessão expirou. Entre de novo pra continuar.';
  @override
  String get erroServidorIndisponivel => 'Sem conexão com o servidor. Verifique a internet e tente de novo.';
  @override
  String get erroItemNaoExiste => 'O item que você tentou abrir não existe mais.';
  @override
  String get erroJaExiste => 'Isso já existe.';
  @override
  String get erroLimiteDoServico => 'O limite do serviço foi atingido. Tente mais tarde.';
  @override
  String get erroOperacaoCancelada => 'A operação foi cancelada.';
  @override
  String get erroPrecisaEstarLogado => 'Você precisa estar logado.';
  @override
  String get erroSessaoExpiradaCurta => 'Sessão expirada.';
  @override
  String get erroUsuarioNaoEncontrado => 'Usuário não encontrado.';
  @override
  String get erroNicknameEmUsoCurto => 'Esse nickname já está em uso.';
  @override
  String codigoDoErro(String mensagem, String codigo) => '$mensagem\n\n(código: $codigo)';

  // ----- Login -----
  @override
  String get loginTitulo => 'FAÇA SEU LOGIN';
  @override
  String get loginCampoLogin => 'Login ou nickname';
  @override
  String get loginDicaLogin => 'E-mail ou nickname';
  @override
  String get loginPreenchaTudo => 'Preencha login e senha.';
  @override
  String get loginNaoTemConta => 'Não tem uma conta? ';
  @override
  String get loginCliqueAqui => 'Clique aqui!';
  @override
  String get loginComApple => 'Entrar com a Apple';
  @override
  String get loginComGoogle => 'Entrar com o Google';
  @override
  String get loginRecuperarSenha => 'Recuperação de senha';
  @override
  String get erroGoogleFalhou => 'Não foi possível entrar com o Google. Tente novamente.';
  @override
  String get erroAppleFalhou => 'Não foi possível entrar com a Apple. Tente novamente.';
  @override
  String get erroAppleSemConta => 'Não foi possível concluir o login com a Apple. Se este for um simulador ou um aparelho de teste, confira se ele está conectado a uma conta Apple (iCloud) com autenticação de dois fatores — sem isso o sistema recusa esse login antes mesmo de chamar o app.';
  @override
  String get erroPerfilNaoSalvo => 'Sua conta foi reconhecida, mas não deu pra salvar o seu perfil. Tente novamente.';

  // ----- Cadastro em etapas -----
  @override
  String cadastroPasso(int numero, int total) => 'PASSO $numero DE $total';
  @override
  String get cadastroBoasVindasTitulo => 'Bem-vindo(a) à\ncomunidade PTK Plays!';
  @override
  String get cadastroBoasVindasTexto => 'Aqui você acompanha de perto tudo o que rola no canal: avisos de live, os vídeos novos e as enquetes do PTK — e ainda fala com a galera no feed.\n\nSão só alguns passos pra criar sua conta. Bora?';
  @override
  String get cadastroBoasVindasCurto => 'Avisos de live, vídeos novos, enquetes e o feed da galera. Bora criar sua conta?';
  @override
  String get cadastroNickTitulo => 'Como a gente\nte chama?';
  @override
  String get cadastroNickTexto => 'Esse é o nick que vai aparecer nos seus posts e comentários dentro do app.';
  @override
  String get cadastroNickCurto => 'É o nick que aparece nos seus posts e comentários.';
  @override
  String get cadastroNickCampo => 'Seu nick';
  @override
  String get cadastroEmailTitulo => 'Qual é o\nseu e-mail?';
  @override
  String get cadastroEmailTexto => 'É por ele que você entra na conta e recupera a senha se esquecer.';
  @override
  String get cadastroEmailCurto => 'Serve pra entrar e recuperar a senha.';
  @override
  String get cadastroConfirmeEmail => 'Confirme o e-mail';
  @override
  String get cadastroSenhaTitulo => 'Agora crie uma senha';
  @override
  String cadastroSenhaTexto(int minimo) => 'Pelo menos $minimo caracteres. Toque no olho pra conferir o que digitou.';
  @override
  String cadastroSenhaCurto(int minimo) => 'Pelo menos $minimo caracteres.';
  @override
  String get cadastroFotoTitulo => 'Sua foto\nde perfil';
  @override
  String get cadastroFotoTexto => 'Escolha um dos avatares da comunidade ou tire uma selfie agora.';
  @override
  String get cadastroFotoCurto => 'Escolha um avatar ou tire uma selfie.';
  @override
  String get cadastroTirarFoto => 'Tirar foto';
  @override
  String get cadastroTirarOutra => 'Tirar outra';
  @override
  String get cadastroDaGaleria => 'Da galeria';
  @override
  String get cadastroOuEscolhaAvatar => 'Ou escolha um avatar:';
  @override
  String get cadastroWhatsappTitulo => 'Seu WhatsApp';
  @override
  String get cadastroWhatsappTexto => 'Opcional. Com ele você ganha outra forma de entrar, confirma a troca de senha e recebe o aviso quando eu entrar ao vivo.';
  @override
  String get cadastroWhatsappCurto => 'Opcional: outro login, troca de senha e aviso de live.';
  @override
  String get cadastroWhatsappCampo => 'Número com DDD';
  @override
  String get cadastroCameraFalhou => 'Não foi possível abrir a câmera.';
  @override
  String get cadastroFotoNaoSubiu => 'Conta criada! Só a foto não subiu, tente de novo no perfil.';

  // ----- Validacao dos campos -----
  @override
  String get validaNickVazio => 'Escolha um nick pra gente te chamar.';
  @override
  String validaNickCurto(int minimo) => 'O nick precisa de pelo menos $minimo letras.';
  @override
  String validaNickLongo(int maximo) => 'O nick passou de $maximo caracteres.';
  @override
  String get validaNickComArroba => 'O nick não pode ter @.';
  @override
  String get validaEmailVazio => 'Preencha seu e-mail.';
  @override
  String get validaEmailInvalido => 'Esse e-mail não parece válido.';
  @override
  String get validaConfirmeEmailVazio => 'Repita o e-mail pra confirmar.';
  @override
  String get validaEmailsDiferentes => 'Os e-mails não coincidem.';
  @override
  String get validaSenhaVazia => 'Crie uma senha.';
  @override
  String validaSenhaCurta(int minimo) => 'A senha precisa de pelo menos $minimo caracteres.';
  @override
  String get validaWhatsappIncompleto => 'Número incompleto. Preencha o DDD e o número, ou pule esta etapa.';
  @override
  String get validaWhatsappIncompletoPerfil => 'Número de WhatsApp incompleto. Preencha o DDD e o número, ou deixe em branco.';
  @override
  String get validaFotoFaltando => 'Escolha um avatar ou tire uma foto.';
  @override
  String get validaSenhaAtualFaltando => 'Informe sua senha atual pra trocar de senha.';
  @override
  String get validaNovaSenhaCurta => 'A nova senha precisa ter pelo menos 6 caracteres.';
  @override
  String get validaSenhasDiferentes => 'As senhas não coincidem.';
  @override
  String get validaEscolhaFoto => 'Escolha uma foto de perfil.';
  @override
  String get validaFotoInvalida => 'Foto de perfil inválida.';
  @override
  String get validaPreenchaTudo => 'Preencha todos os campos.';

  // ----- Feed e posts -----
  @override
  String get feedNovaPublicacao => 'Nova publicação';
  @override
  String get feedPublicar => 'Publicar';
  @override
  String get feedAviso => 'Aviso';
  @override
  String get feedEnquete => 'Enquete';
  @override
  String get feedFoto => 'Foto';
  @override
  String get feedTrocarFoto => 'Trocar foto';
  @override
  String get feedVideo => 'Vídeo';
  @override
  String get feedTrocarVideo => 'Trocar vídeo';
  @override
  String get feedComoAdmin => 'Como admin, seu post fica no topo do feed — e você pode anexar foto e vídeo.';
  @override
  String feedPublicandoComo(String nickname) => 'Publicando como $nickname.';
  @override
  String get feedDicaAviso => 'O que você quer avisar pra galera?';
  @override
  String get feedDicaTexto => 'O que você quer dizer pra galera?';
  @override
  String get feedDicaPergunta => 'Qual é a pergunta?';
  @override
  String feedOpcaoNumero(int numero) => 'Opção $numero';
  @override
  String get feedRemoverOpcao => 'Remover opção';
  @override
  String get feedAdicionarOpcao => 'Adicionar opção';
  @override
  String get feedArquivoGrande => 'Arquivo grande demais';
  @override
  String get feedNaoCarregouAvisos => 'Não foi possível carregar os avisos.';
  @override
  String get feedNenhumAviso => 'Nenhum aviso por aqui ainda :)';
  @override
  String get feedVerAntigos => 'Ver publicações mais antigas';
  @override
  String get feedExcluirPostTitulo => 'Excluir post?';
  @override
  String get feedExcluirPostTexto => 'Ele some do feed pra todo mundo. Não dá pra desfazer.';
  @override
  String get feedExcluirPost => 'Excluir post';
  @override
  String get feedPostExcluido => 'Post excluído.';
  @override
  String get feedPublicado => 'Publicado no feed!';
  @override
  String get feedAoVivo => 'AO VIVO';
  @override
  String get feedCorrePraAssistir => 'Corre pra assistir agora!';
  @override
  String feedDurou(String duracao) => 'Durou $duracao';
  @override
  String feedEncerradaEm(String quando) => 'Encerrada em $quando';
  @override
  String feedComecouAs(String quando) => 'Começou às $quando';
  @override
  String get feedJaVotou => 'Você já votou';
  @override
  String get feedLiveNaoAbriu => 'Não foi possível abrir a live :/';
  @override
  String get feedNaoCarregouPosts => 'Não foi possível carregar os posts.';
  @override
  String get feedNenhumPost => 'Nenhum post no feed ainda.';
  @override
  String get feedSemTexto => '(sem texto)';
  @override
  String get feedMidia => 'MÍDIA';
  @override
  String get erroEnvioDeMidia => 'Não foi possível enviar o arquivo. Tente de novo.';
  @override
  String get erroSoAdminLimpa => 'Só o admin pode fazer essa limpeza.';
  @override
  String get erroNaoConcluiu => 'Não foi possível concluir. Tente de novo.';
  @override
  String get erroSemPermissaoFeed => 'Você não tem permissão pra isso. Se acabou de virar admin, saia e entre de novo.';

  // ----- Validacao de post -----
  @override
  String get validaPostVazio => 'Escreva alguma coisa antes de publicar.';
  @override
  String validaAvisoLongo(int limite) => 'O aviso passou de $limite caracteres. Encurte um pouco.';
  @override
  String get validaPerguntaVazia => 'Escreva a pergunta da enquete.';
  @override
  String validaPerguntaLonga(int limite) => 'A pergunta passou de $limite caracteres. Encurte um pouco.';
  @override
  String validaPoucasOpcoes(int minimo) => 'Uma enquete precisa de pelo menos $minimo opções preenchidas.';
  @override
  String validaMuitasOpcoes(int maximo) => 'Uma enquete aceita no máximo $maximo opções.';
  @override
  String get validaOpcoesRepetidas => 'Tem opções repetidas na enquete.';
  @override
  String validaVideoGrande(int limiteEmMb) => 'O vídeo passou de $limiteEmMb MB. Escolha um menor ou corte um trecho.';
  @override
  String validaImagemGrande(int limiteEmMb) => 'A imagem passou de $limiteEmMb MB. Escolha uma menor.';

  // ----- Videos -----
  @override
  String get videosTitulo => 'Vídeos';
  @override
  String get videosNenhum => 'Nenhuma postagem encontrada :/';
  @override
  String get videosNaoAbriu => 'Não foi possível abrir o vídeo :/';
  @override
  String get videosNaoCarregou => 'Não foi possível carregar o vídeo.';
  @override
  String videosPublicadoEm(String data) => 'Publicado em $data';
  @override
  String videosErroCru(String erro) => 'Erro: $erro';

  // ----- Foto e recorte -----
  @override
  String get fotoAjustar => 'Ajustar foto';
  @override
  String get fotoUsarEssa => 'Usar essa foto';
  @override
  String get fotoRecorteFalhou => 'Não foi possível recortar a foto.';
  @override
  String get fotoAtualizada => 'Foto de perfil atualizada!';

  // ----- Perfil -----
  @override
  String get perfilEditar => 'Editar perfil';
  @override
  String get perfilComoQuerSerChamado => 'Como quer ser chamado';
  @override
  String get perfilWhatsappOpcional => 'WhatsApp (opcional)';
  @override
  String get perfilFotoDePerfil => 'Foto de perfil';
  @override
  String get perfilAlterarSenha => 'Alterar senha (opcional)';
  @override
  String get perfilSenhaAtual => 'Senha atual';
  @override
  String get perfilNovaSenha => 'Nova senha';
  @override
  String get perfilConfirmarNovaSenha => 'Confirmar nova senha';
  @override
  String get perfilEsqueceuSenha => 'Esqueceu sua senha atual? Enviar link por e-mail';
  @override
  String perfilLinkEnviado(String email) => 'Enviamos um link pro seu e-mail ($email) pra redefinir a senha.';
  @override
  String get perfilSalvar => 'Salvar alterações';
  @override
  String get perfilSalvo => 'Perfil salvo com sucesso!';
  @override
  String get perfilMembroDesde => 'Membro desde';
  @override
  String get perfilUltimoAcesso => 'Último acesso';
  @override
  String get perfilCategorias => 'Categorias';
  @override
  String get perfilNenhumaCategoria => 'Nenhuma categoria escolhida ainda';
  @override
  String get perfilNenhumaBadge => 'Nenhuma badge conquistada ainda';
  @override
  String get perfilSairDaConta => 'Sair da conta';
  @override
  String get perfilExcluirConta => 'Excluir conta';
  @override
  String get perfilExcluirContaTexto => 'Essa ação é irreversível: seus dados serão apagados permanentemente. Digite sua senha pra confirmar.';
  @override
  String get perfilOnline => 'Online';
  @override
  String get perfilOffline => 'Offline';
  @override
  String get perfilInvisivel => 'Invisível';
  @override
  String get perfilNaoPerturbe => 'Não perturbe';

  // ----- Conquistas e badges -----
  @override
  String get conquistasTitulo => 'Conquistas';
  @override
  String get conquistasProgresso => 'Progresso';
  @override
  String get conquistasBadgesConquistadas => 'Badges conquistadas';
  @override
  String get badgeAdministrador => 'Administrador';
  @override
  String get badgeAdministradorTexto => 'Cuida do PTK Plays por dentro: modera a comunidade e publica os avisos do canal.';
  @override
  String get badgeNovato => 'Novato';
  @override
  String get badgeNovatoTexto => 'Toda conta criada no PTK Plays já começa com essa conquista.';
  @override
  String get badgeComentarista => 'Comentarista';
  @override
  String get badgeComentaristaTexto => 'Comente em 10 posts ou vídeos.';
  @override
  String get badgePopular => 'Popular';
  @override
  String get badgePopularTexto => 'Receba 50 curtidas nos seus comentários.';
  @override
  String get badgePresencaVip => 'Presença VIP';
  @override
  String get badgePresencaVipTexto => 'Clique pra assistir 5 lives.';

  // ----- Cargos e avatares -----
  @override
  String get cargoAdmin => 'Admin';
  @override
  String get cargoInscrito => 'Inscrito';
  @override
  String get cargoJogador => 'Jogador';
  @override
  String get categoriaOtaku => 'Otaku';
  @override
  String get categoriaGamer => 'Gamer';
  @override
  String get categoriaStreamer => 'Streamer';
  @override
  String get categoriaGeek => 'Geek';
  @override
  String get categoriaOutro => 'Outro';
  @override
  String get avatarGamer => 'Gamer';
  @override
  String get avatarStreamer => 'Streamer';
  @override
  String get avatarInscrito => 'Inscrito do canal';
  @override
  String get avatarBlogueiro => 'Blogueiro';
  @override
  String get avatarMaratonista => 'Maratonista';
  @override
  String get avatarOtaku => 'Otaku';

  // ----- Menu e telas de apoio -----
  @override
  String get menuTitulo => 'Menu';
  @override
  String get menuPoliticaDePrivacidade => 'Política de Privacidade';
  @override
  String get menuPainelAdm => 'Painel ADM';
  @override
  String get politicaNaoAbriu => 'Não foi possível abrir a política de privacidade :/';
  @override
  String get privacidadeEmBreve => 'Nossa política de privacidade ainda está sendo escrita. Em breve você vai encontrar aqui como seus dados são usados no PTK Plays.';
  @override
  String get configuracoesEmBreve => 'As opções de configuração do app ainda estão a caminho. Em breve você vai poder ajustar suas preferências por aqui.';
  @override
  String get configuracoesIdioma => 'Idioma';
  @override
  String get configuracoesIdiomaTexto => 'O app segue o idioma do seu aparelho. Dá pra trocar aqui sem mexer nas configurações dele.';
  @override
  String get idiomaPortugues => 'Português (Brasil)';
  @override
  String get idiomaIngles => 'Inglês (EUA)';

  // ----- Conta bloqueada -----
  @override
  String get bloqueioBanida => 'Sua conta foi banida';
  @override
  String get bloqueioSuspensa => 'Sua conta está suspensa';
  @override
  String get bloqueioBanidaTexto => 'Você não pode mais usar o PTK Plays.';
  @override
  String bloqueioSuspensaTexto(String ate) => 'Você não pode usar o PTK Plays até $ate.';
  @override
  String bloqueioMotivo(String motivo) => 'Motivo: $motivo';
  @override
  String get bloqueioDataFutura => 'uma data futura';

  // ----- Painel do administrador -----
  @override
  String get adminTitulo => 'Painel ADM';
  @override
  String get adminUsuarios => 'Usuários';
  @override
  String get adminModeracao => 'Moderação';
  @override
  String get adminNaoCarregouUsuarios => 'Não foi possível carregar os usuários.';
  @override
  String get adminNenhumUsuario => 'Nenhum usuário cadastrado ainda.';
  @override
  String get adminVerPerfil => 'Ver perfil';
  @override
  String get adminBanir => 'Banir';
  @override
  String get adminSuspender => 'Suspender por 7 dias';
  @override
  String get adminReativar => 'Reativar conta';
  @override
  String get adminMensagemPrivada => 'Mensagem privada';
  @override
  String get adminMensagemPrivadaEmBreve => 'Mensagem privada ainda não está pronta.';
  @override
  String get adminRemoverUsuario => 'Remover usuário';
  @override
  String get adminUsuarioAtualizado => 'Usuário atualizado.';
  @override
  String get adminNaoAtualizou => 'Não foi possível atualizar.';
  @override
  String adminRemoverTitulo(String nickname) => 'Remover $nickname?';
  @override
  String get adminRemoverTexto => 'Some a conta e, junto com ela, todos os posts, mensagens e conversas dessa pessoa. Não dá pra desfazer.\n\nO login dela no Firebase continua existindo: se entrar de novo pelo Google/Apple, uma conta nova e vazia é criada.';
  @override
  String adminUsuarioRemovido(int posts) => 'Usuário removido, com $posts post(s).';
  @override
  String get adminNaoRemoveu => 'Não foi possível remover.';
  @override
  String get adminLimparAvisosTitulo => 'Limpar avisos antigos?';
  @override
  String get adminLimparAvisosTexto => 'Apaga de vez os avisos de live que ficaram sem miniatura e sem plataforma. Eles já não aparecem no feed. Não dá pra desfazer.';
  @override
  String get adminLimparAvisos => 'Limpar avisos de live antigos';
  @override
  String get adminNenhumAvisoAntigo => 'Nenhum aviso antigo pra limpar.';
  @override
  String adminAvisosApagados(int quantos) => '$quantos aviso(s) antigo(s) apagado(s).';
  @override
  String get adminNaoCarregouConversas => 'Não foi possível carregar as conversas.';
  @override
  String get adminNenhumaMensagem => 'Nenhuma mensagem ainda. O que chegar no número do canal aparece aqui — inclusive a confirmação de entrega dos avisos que o app enviar.';
  @override
  String get adminEnvioIndisponivel => 'Envio pelo painel ainda não disponível: depende do número de produção e dos modelos de mensagem aprovados na Meta.';
  @override
  String get adminRespostaLivre => 'Resposta livre liberada';
  @override
  String get adminForaDaJanela => 'Fora da janela: só template';
  @override
  String get adminJanelaAberta => 'Janela de 24h aberta: quando o envio existir, dá pra responder com texto livre.';
  @override
  String get adminJanelaFechada => 'Fora da janela de 24h: só dá pra enviar modelo de mensagem aprovado pela Meta.';
  @override
  String get adminCargosTexto => 'Cadastrar cargos novos além de inscrito/vip/admin e definir as permissões de cada um.';
  @override
  String get adminCargosPendencia => 'Depende de uma coleção "cargos" no Firestore e de reescrever o firestore.rules pra ler as permissões de lá, em vez do cargo fixo que ele checa hoje.';
  @override
  String get adminBadgesTexto => 'Conceder badges do catálogo a usuários escolhidos na lista.';
  @override
  String get adminBadgesPendencia => 'O campo "badges" é travado contra escrita do cliente no firestore.rules — conceder badge precisa de uma Cloud Function com o Admin SDK.';
  @override
  String get adminNotificacoesTexto => 'Enviar push com título e descrição pra todos ou só pra um cargo específico.';
  @override
  String get adminNotificacoesPendencia => 'Precisa de uma Cloud Function que dispare via FCM. O envio por cargo exige inscrever cada usuário num tópico por cargo no login.';

  // ----- Mensagens do WhatsApp no painel -----
  @override
  String get whatsappVideo => '[vídeo]';
  @override
  String get whatsappAudio => '[áudio]';
  @override
  String get whatsappLocalizacao => '[localização]';
  @override
  String get whatsappEnviada => 'Enviada';
  @override
  String get whatsappEntregue => 'Entregue';
  @override
  String get whatsappLida => 'Lida';
  @override
  String get whatsappFalhou => 'Falhou';
  @override
  String whatsappFalhouCom(String erro) => 'Falhou: $erro';

  // ----- Datas e duracoes -----
  @override
  String dataHaMinutos(int minutos) => 'há ${minutos}min';
  @override
  String dataHaHoras(int horas) => 'há ${horas}h';
  @override
  String dataHaDias(int dias) => 'há ${dias}d';
  @override
  String duracaoHorasMinutos(int horas, int minutos) => '${horas}h ${minutos}min';
  @override
  String duracaoMinutos(int minutos) => '${minutos}min';

  // ----- Formato de data (a ordem dia/mes inverte em en-US) -----
  @override
  String dataDiaMes(String dia, String mes) => '$dia/$mes';
  @override
  String dataDiaMesAno(String dia, String mes, String ano) => '$dia/$mes/$ano';
  @override
  String dataDiaMesHora(String dia, String mes, String hora, String minuto) => '$dia/$mes às $hora:$minuto';
  @override
  String dataDiaMesAnoHora(String dia, String mes, String ano, String hora, String minuto) => '$dia/$mes/$ano às $hora:$minuto';

  // ----- Resumo de midia do WhatsApp -----
  @override
  String get whatsappImagem => '[imagem]';
  @override
  String get whatsappDocumento => '[documento]';
  @override
  String get whatsappFigurinha => '[figurinha]';
  @override
  String get whatsappContato => '[contato]';

  // ----- O que faltou na primeira varredura -----
  @override
  String get feedEncerrada => 'ENCERRADA';
  @override
  String get dataAgora => 'agora';
  @override
  String duracaoSoHoras(int horas) => '${horas}h';
  @override
  String duracaoSegundos(int segundos) => '${segundos}s';
  @override
  String get cadastroAntigoTitulo => 'CRIE SUA CONTA';
  @override
  String get cadastroEscolhaAvatar => 'Escolha seu avatar';
  @override
  String get cadastroJaTemConta => 'Já tem uma conta? ';
  @override
  String get cadastroFazerLogin => 'Fazer login';
  @override
  String get cadastroDigiteEmail => 'Digite seu email';
  @override
  String get validaNickComArrobaAntigo => 'O nickname não pode conter @.';
  @override
  String apenasOCodigo(String codigo) => '(código: $codigo)';

  // ----- Selos de tipo de post, no painel -----
  @override
  String get seloAviso => 'AVISO';
  @override
  String get seloFoto => 'FOTO';
  @override
  String get seloEnquete => 'ENQUETE';
  @override
  String get seloLive => 'LIVE';
  @override
  String get adminVocePrefixo => 'Você: ';

  // ----- Exclusao da propria conta -----
  @override
  String get perfilExcluirContaOQueSai => 'Some com tudo: seu perfil, suas badges, seu cargo, seus posts e seus votos nas enquetes. Não dá pra desfazer.';
  @override
  String get perfilExcluirContaSocial => 'Pra confirmar que é você, vamos abrir a tela do provedor com que você entrou mais uma vez.';
  @override
  String get perfilExcluirContaDigiteSenha => 'Digite sua senha pra confirmar.';
}
