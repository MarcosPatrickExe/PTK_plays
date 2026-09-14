/// Os textos do app em ingles dos EUA.
///
/// Existe por dois motivos, e o segundo pesa tanto quanto o primeiro: a
/// comunidade tem gente fora do Brasil, e **o revisor da App Store e o da
/// Play Store leem em ingles**. Duas reprovacoes ja custaram semanas
/// adivinhando o que o revisor viu; um app inteiro em portugues e mais uma
/// chance de ele nao entender o que esta olhando.
library;

import 'Textos.dart';

class TextosEnUs extends Textos {
  const TextosEnUs();

  // ----- Palavras que aparecem em varias telas -----
  @override
  String get ops => 'Oops!';
  @override
  String get fechar => 'Close';
  @override
  String get cancelar => 'Cancel';
  @override
  String get excluir => 'Delete';
  @override
  String get remover => 'Remove';
  @override
  String get voltar => 'Back';
  @override
  String get sair => 'Leave';
  @override
  String get limpar => 'Clear';
  @override
  String get avancar => 'Next';
  @override
  String get pular => 'Skip';
  @override
  String get entrar => 'Sign in';
  @override
  String get criarConta => 'Create account';
  @override
  String get senha => 'Password';
  @override
  String get email => 'Email';
  @override
  String get nickname => 'Nickname';
  @override
  String get cargo => 'Role';
  @override
  String get status => 'Status';
  @override
  String get badges => 'Badges';
  @override
  String get whatsapp => 'WhatsApp';
  @override
  String get perfil => 'Profile';
  @override
  String get feed => 'Feed';
  @override
  String get videos => 'Videos';
  @override
  String get posts => 'Posts';
  @override
  String get cargos => 'Roles';
  @override
  String get privacidade => 'Privacy';
  @override
  String get configuracoes => 'Settings';
  @override
  String get notificacoes => 'Notifications';

  // ----- Erros genericos e traducao de codigo de servico -----
  @override
  String get erroGenerico => 'Something went wrong. Please try again.';
  @override
  String get erroEmailJaCadastrado => 'That email is already registered. Try signing in.';
  @override
  String get erroEmailInvalido => 'Invalid email.';
  @override
  String get erroSenhaFraca => 'The password needs at least 6 characters.';
  @override
  String get erroLoginOuSenha => 'Wrong login or password.';
  @override
  String get erroNicknameEmUso => 'That nickname is taken. Pick another one.';
  @override
  String get erroMuitasTentativas => 'Too many attempts. Try again later.';
  @override
  String get erroSemInternet => 'No internet connection.';
  @override
  String get erroDominioNaoAutorizado => 'This domain isn\'t authorized for Google sign-in. Let the app administrator know.';
  @override
  String get erroPopupBloqueado => 'The browser blocked the sign-in popup. Allow popups for this site and try again.';
  @override
  String get erroMetodoDesabilitado => 'This sign-in method isn\'t enabled for the app right now. Let the administrator know.';
  @override
  String get erroSemPermissao => 'You don\'t have permission to do this. If you should, let the administrator know.';
  @override
  String get erroSessaoExpirada => 'Your session expired. Sign in again to continue.';
  @override
  String get erroServidorIndisponivel => 'No connection to the server. Check your internet and try again.';
  @override
  String get erroItemNaoExiste => 'The item you tried to open no longer exists.';
  @override
  String get erroJaExiste => 'That already exists.';
  @override
  String get erroLimiteDoServico => 'The service limit was reached. Try again later.';
  @override
  String get erroOperacaoCancelada => 'The operation was cancelled.';
  @override
  String get erroPrecisaEstarLogado => 'You need to be signed in.';
  @override
  String get erroSessaoExpiradaCurta => 'Session expired.';
  @override
  String get erroUsuarioNaoEncontrado => 'User not found.';
  @override
  String get erroNicknameEmUsoCurto => 'That nickname is taken.';
  @override
  String codigoDoErro(String mensagem, String codigo) => '$mensagem\n\n(code: $codigo)';

  // ----- Login -----
  @override
  String get loginTitulo => 'SIGN IN';
  @override
  String get loginCampoLogin => 'Login or nickname';
  @override
  String get loginDicaLogin => 'Email or nickname';
  @override
  String get loginPreenchaTudo => 'Fill in your login and password.';
  @override
  String get loginNaoTemConta => 'Don\'t have an account? ';
  @override
  String get loginCliqueAqui => 'Tap here!';
  @override
  String get loginComApple => 'Sign in with Apple';
  @override
  String get loginComGoogle => 'Sign in with Google';
  @override
  String get loginRecuperarSenha => 'Password recovery';
  @override
  String get erroGoogleFalhou => 'Couldn\'t sign in with Google. Please try again.';
  @override
  String get erroAppleFalhou => 'Couldn\'t sign in with Apple. Please try again.';
  @override
  String get erroAppleSemConta => 'Couldn\'t finish signing in with Apple. If this is a simulator or a test device, check that it\'s signed in to an Apple account (iCloud) with two-factor authentication — without that, the system refuses this sign-in before the app is even called.';
  @override
  String get erroPerfilNaoSalvo => 'Your account was recognized, but we couldn\'t save your profile. Please try again.';

  // ----- Cadastro em etapas -----
  @override
  String cadastroPasso(int numero, int total) => 'STEP $numero OF $total';
  @override
  String get cadastroBoasVindasTitulo => 'Welcome to the\nPTK Plays community!';
  @override
  String get cadastroBoasVindasTexto => 'Here you follow everything happening on the channel up close: live alerts, new videos and PTK\'s polls — plus you get to talk to everyone in the feed.\n\nIt\'s just a few steps to create your account. Shall we?';
  @override
  String get cadastroBoasVindasCurto => 'Live alerts, new videos, polls and the community feed. Ready to create your account?';
  @override
  String get cadastroNickTitulo => 'What should we\ncall you?';
  @override
  String get cadastroNickTexto => 'This is the nickname that shows up on your posts and comments inside the app.';
  @override
  String get cadastroNickCurto => 'It\'s the nickname on your posts and comments.';
  @override
  String get cadastroNickCampo => 'Your nickname';
  @override
  String get cadastroEmailTitulo => 'What\'s your\nemail?';
  @override
  String get cadastroEmailTexto => 'It\'s how you sign in and recover your password if you forget it.';
  @override
  String get cadastroEmailCurto => 'Used to sign in and recover your password.';
  @override
  String get cadastroConfirmeEmail => 'Confirm your email';
  @override
  String get cadastroSenhaTitulo => 'Now create a password';
  @override
  String cadastroSenhaTexto(int minimo) => 'At least $minimo characters. Tap the eye to check what you typed.';
  @override
  String cadastroSenhaCurto(int minimo) => 'At least $minimo characters.';
  @override
  String get cadastroFotoTitulo => 'Your profile\npicture';
  @override
  String get cadastroFotoTexto => 'Pick one of the community avatars or take a selfie now.';
  @override
  String get cadastroFotoCurto => 'Pick an avatar or take a selfie.';
  @override
  String get cadastroTirarFoto => 'Take a photo';
  @override
  String get cadastroTirarOutra => 'Retake';
  @override
  String get cadastroDaGaleria => 'From gallery';
  @override
  String get cadastroOuEscolhaAvatar => 'Or pick an avatar:';
  @override
  String get cadastroWhatsappTitulo => 'Your WhatsApp';
  @override
  String get cadastroWhatsappTexto => 'Optional. It gives you another way to sign in, confirms password changes, and brings you the alert when I go live.';
  @override
  String get cadastroWhatsappCurto => 'Optional: another sign-in, password changes and live alerts.';
  @override
  String get cadastroWhatsappCampo => 'Number with area code';
  @override
  String get cadastroCameraFalhou => 'Couldn\'t open the camera.';
  @override
  String get cadastroFotoNaoSubiu => 'Account created! Only the photo didn\'t upload — try again from your profile.';

  // ----- Validacao dos campos -----
  @override
  String get validaNickVazio => 'Pick a nickname so we can call you something.';
  @override
  String validaNickCurto(int minimo) => 'The nickname needs at least $minimo letters.';
  @override
  String validaNickLongo(int maximo) => 'The nickname went past $maximo characters.';
  @override
  String get validaNickComArroba => 'The nickname can\'t contain @.';
  @override
  String get validaEmailVazio => 'Fill in your email.';
  @override
  String get validaEmailInvalido => 'That email doesn\'t look valid.';
  @override
  String get validaConfirmeEmailVazio => 'Type the email again to confirm.';
  @override
  String get validaEmailsDiferentes => 'The emails don\'t match.';
  @override
  String get validaSenhaVazia => 'Create a password.';
  @override
  String validaSenhaCurta(int minimo) => 'The password needs at least $minimo characters.';
  @override
  String get validaWhatsappIncompleto => 'Incomplete number. Fill in the area code and the number, or skip this step.';
  @override
  String get validaWhatsappIncompletoPerfil => 'Incomplete WhatsApp number. Fill in the area code and the number, or leave it blank.';
  @override
  String get validaFotoFaltando => 'Pick an avatar or take a photo.';
  @override
  String get validaSenhaAtualFaltando => 'Enter your current password to change it.';
  @override
  String get validaNovaSenhaCurta => 'The new password needs at least 6 characters.';
  @override
  String get validaSenhasDiferentes => 'The passwords don\'t match.';
  @override
  String get validaEscolhaFoto => 'Pick a profile picture.';
  @override
  String get validaFotoInvalida => 'Invalid profile picture.';
  @override
  String get validaPreenchaTudo => 'Fill in every field.';

  // ----- Feed e posts -----
  @override
  String get feedNovaPublicacao => 'New post';
  @override
  String get feedPublicar => 'Post';
  @override
  String get feedAviso => 'Announcement';
  @override
  String get feedEnquete => 'Poll';
  @override
  String get feedFoto => 'Photo';
  @override
  String get feedTrocarFoto => 'Change photo';
  @override
  String get feedVideo => 'Video';
  @override
  String get feedTrocarVideo => 'Change video';
  @override
  String get feedComoAdmin => 'As an admin, your post stays at the top of the feed — and you can attach a photo and a video.';
  @override
  String feedPublicandoComo(String nickname) => 'Posting as $nickname.';
  @override
  String get feedDicaAviso => 'What do you want to announce?';
  @override
  String get feedDicaTexto => 'What do you want to say?';
  @override
  String get feedDicaPergunta => 'What\'s the question?';
  @override
  String feedOpcaoNumero(int numero) => 'Option $numero';
  @override
  String get feedRemoverOpcao => 'Remove option';
  @override
  String get feedAdicionarOpcao => 'Add option';
  @override
  String get feedArquivoGrande => 'File is too large';
  @override
  String get feedNaoCarregouAvisos => 'Couldn\'t load the announcements.';
  @override
  String get feedNenhumAviso => 'No announcements here yet :)';
  @override
  String get feedVerAntigos => 'See older posts';
  @override
  String get feedExcluirPostTitulo => 'Delete post?';
  @override
  String get feedExcluirPostTexto => 'It disappears from everyone\'s feed. This can\'t be undone.';
  @override
  String get feedExcluirPost => 'Delete post';
  @override
  String get feedPostExcluido => 'Post deleted.';
  @override
  String get feedPublicado => 'Posted to the feed!';
  @override
  String get feedAoVivo => 'LIVE';
  @override
  String get feedCorrePraAssistir => 'Go watch it now!';
  @override
  String feedDurou(String duracao) => 'Lasted $duracao';
  @override
  String feedEncerradaEm(String quando) => 'Ended on $quando';
  @override
  String feedComecouAs(String quando) => 'Started at $quando';
  @override
  String get feedJaVotou => 'You already voted';
  @override
  String get feedLiveNaoAbriu => 'Couldn\'t open the live stream :/';
  @override
  String get feedNaoCarregouPosts => 'Couldn\'t load the posts.';
  @override
  String get feedNenhumPost => 'No posts in the feed yet.';
  @override
  String get feedSemTexto => '(no text)';
  @override
  String get feedMidia => 'MEDIA';
  @override
  String get erroEnvioDeMidia => 'Couldn\'t upload the file. Please try again.';
  @override
  String get erroSoAdminLimpa => 'Only an admin can run this cleanup.';
  @override
  String get erroNaoConcluiu => 'Couldn\'t finish. Please try again.';
  @override
  String get erroSemPermissaoFeed => 'You don\'t have permission for this. If you just became an admin, sign out and back in.';

  // ----- Validacao de post -----
  @override
  String get validaPostVazio => 'Write something before posting.';
  @override
  String validaAvisoLongo(int limite) => 'The announcement went past $limite characters. Shorten it a bit.';
  @override
  String get validaPerguntaVazia => 'Write the poll question.';
  @override
  String validaPerguntaLonga(int limite) => 'The question went past $limite characters. Shorten it a bit.';
  @override
  String validaPoucasOpcoes(int minimo) => 'A poll needs at least $minimo filled options.';
  @override
  String validaMuitasOpcoes(int maximo) => 'A poll takes at most $maximo options.';
  @override
  String get validaOpcoesRepetidas => 'The poll has duplicate options.';
  @override
  String validaVideoGrande(int limiteEmMb) => 'The video went past $limiteEmMb MB. Pick a smaller one or trim it.';
  @override
  String validaImagemGrande(int limiteEmMb) => 'The image went past $limiteEmMb MB. Pick a smaller one.';

  // ----- Videos -----
  @override
  String get videosTitulo => 'Videos';
  @override
  String get videosNenhum => 'No posts found :/';
  @override
  String get videosNaoAbriu => 'Couldn\'t open the video :/';
  @override
  String get videosNaoCarregou => 'Couldn\'t load the video.';
  @override
  String videosPublicadoEm(String data) => 'Published on $data';
  @override
  String videosErroCru(String erro) => 'Error: $erro';

  // ----- Foto e recorte -----
  @override
  String get fotoAjustar => 'Adjust photo';
  @override
  String get fotoUsarEssa => 'Use this photo';
  @override
  String get fotoRecorteFalhou => 'Couldn\'t crop the photo.';
  @override
  String get fotoAtualizada => 'Profile picture updated!';

  // ----- Perfil -----
  @override
  String get perfilEditar => 'Edit profile';
  @override
  String get perfilComoQuerSerChamado => 'What should we call you';
  @override
  String get perfilWhatsappOpcional => 'WhatsApp (optional)';
  @override
  String get perfilFotoDePerfil => 'Profile picture';
  @override
  String get perfilAlterarSenha => 'Change password (optional)';
  @override
  String get perfilSenhaAtual => 'Current password';
  @override
  String get perfilNovaSenha => 'New password';
  @override
  String get perfilConfirmarNovaSenha => 'Confirm new password';
  @override
  String get perfilEsqueceuSenha => 'Forgot your current password? Send a link by email';
  @override
  String perfilLinkEnviado(String email) => 'We sent a link to your email ($email) to reset your password.';
  @override
  String get perfilSalvar => 'Save changes';
  @override
  String get perfilSalvo => 'Profile saved!';
  @override
  String get perfilMembroDesde => 'Member since';
  @override
  String get perfilUltimoAcesso => 'Last seen';
  @override
  String get perfilCategorias => 'Categories';
  @override
  String get perfilNenhumaCategoria => 'No categories picked yet';
  @override
  String get perfilNenhumaBadge => 'No badges earned yet';
  @override
  String get perfilSairDaConta => 'Sign out';
  @override
  String get perfilExcluirConta => 'Delete account';
  @override
  String get perfilExcluirContaTexto => 'This can\'t be undone: your data will be permanently erased. Type your password to confirm.';
  @override
  String get perfilOnline => 'Online';
  @override
  String get perfilOffline => 'Offline';
  @override
  String get perfilInvisivel => 'Invisible';
  @override
  String get perfilNaoPerturbe => 'Do not disturb';

  // ----- Conquistas e badges -----
  @override
  String get conquistasTitulo => 'Achievements';
  @override
  String get conquistasProgresso => 'Progress';
  @override
  String get conquistasBadgesConquistadas => 'Badges earned';
  @override
  String get badgeAdministrador => 'Administrator';
  @override
  String get badgeAdministradorTexto => 'Takes care of PTK Plays from the inside: moderates the community and posts the channel\'s announcements.';
  @override
  String get badgeNovato => 'Rookie';
  @override
  String get badgeNovatoTexto => 'Every account created on PTK Plays starts with this one.';
  @override
  String get badgeComentarista => 'Commenter';
  @override
  String get badgeComentaristaTexto => 'Comment on 10 posts or videos.';
  @override
  String get badgePopular => 'Popular';
  @override
  String get badgePopularTexto => 'Get 50 likes on your comments.';
  @override
  String get badgePresencaVip => 'VIP Presence';
  @override
  String get badgePresencaVipTexto => 'Tap to watch 5 live streams.';

  // ----- Cargos e avatares -----
  @override
  String get cargoAdmin => 'Admin';
  @override
  String get cargoInscrito => 'Subscriber';
  @override
  String get cargoJogador => 'Player';
  @override
  String get categoriaOtaku => 'Otaku';
  @override
  String get categoriaGamer => 'Gamer';
  @override
  String get categoriaStreamer => 'Streamer';
  @override
  String get categoriaGeek => 'Geek';
  @override
  String get categoriaOutro => 'Other';
  @override
  String get avatarGamer => 'Gamer';
  @override
  String get avatarStreamer => 'Streamer';
  @override
  String get avatarInscrito => 'Channel subscriber';
  @override
  String get avatarBlogueiro => 'Blogger';
  @override
  String get avatarMaratonista => 'Binge-watcher';
  @override
  String get avatarOtaku => 'Otaku';

  // ----- Menu e telas de apoio -----
  @override
  String get menuTitulo => 'Menu';
  @override
  String get menuPoliticaDePrivacidade => 'Privacy Policy';
  @override
  String get menuPainelAdm => 'Admin panel';
  @override
  String get politicaNaoAbriu => 'Couldn\'t open the privacy policy :/';
  @override
  String get privacidadeEmBreve => 'Our privacy policy is still being written. Soon you\'ll find here how your data is used on PTK Plays.';
  @override
  String get configuracoesEmBreve => 'The app\'s settings are still on their way. Soon you\'ll be able to adjust your preferences here.';
  @override
  String get configuracoesIdioma => 'Language';
  @override
  String get configuracoesIdiomaTexto => 'The app follows your device\'s language. You can change it here without touching the device settings.';
  @override
  String get idiomaPortugues => 'Portuguese (Brazil)';
  @override
  String get idiomaIngles => 'English (US)';

  // ----- Conta bloqueada -----
  @override
  String get bloqueioBanida => 'Your account was banned';
  @override
  String get bloqueioSuspensa => 'Your account is suspended';
  @override
  String get bloqueioBanidaTexto => 'You can no longer use PTK Plays.';
  @override
  String bloqueioSuspensaTexto(String ate) => 'You can\'t use PTK Plays until $ate.';
  @override
  String bloqueioMotivo(String motivo) => 'Reason: $motivo';
  @override
  String get bloqueioDataFutura => 'a future date';

  // ----- Painel do administrador -----
  @override
  String get adminTitulo => 'Admin panel';
  @override
  String get adminUsuarios => 'Users';
  @override
  String get adminModeracao => 'Moderation';
  @override
  String get adminNaoCarregouUsuarios => 'Couldn\'t load the users.';
  @override
  String get adminNenhumUsuario => 'No users registered yet.';
  @override
  String get adminVerPerfil => 'View profile';
  @override
  String get adminBanir => 'Ban';
  @override
  String get adminSuspender => 'Suspend for 7 days';
  @override
  String get adminReativar => 'Reactivate account';
  @override
  String get adminMensagemPrivada => 'Private message';
  @override
  String get adminMensagemPrivadaEmBreve => 'Private messages aren\'t ready yet.';
  @override
  String get adminRemoverUsuario => 'Remove user';
  @override
  String get adminUsuarioAtualizado => 'User updated.';
  @override
  String get adminNaoAtualizou => 'Couldn\'t update.';
  @override
  String adminRemoverTitulo(String nickname) => 'Remove $nickname?';
  @override
  String get adminRemoverTexto => 'The account disappears and, with it, every post, message and conversation of that person. This can\'t be undone.\n\nTheir Firebase login still exists: if they sign in again with Google/Apple, a new empty account is created.';
  @override
  String adminUsuarioRemovido(int posts) => 'User removed, along with $posts post(s).';
  @override
  String get adminNaoRemoveu => 'Couldn\'t remove.';
  @override
  String get adminLimparAvisosTitulo => 'Clear old announcements?';
  @override
  String get adminLimparAvisosTexto => 'Permanently deletes the live alerts left without a thumbnail and without a platform. They no longer show in the feed. This can\'t be undone.';
  @override
  String get adminLimparAvisos => 'Clear old live alerts';
  @override
  String get adminNenhumAvisoAntigo => 'No old announcements to clear.';
  @override
  String adminAvisosApagados(int quantos) => '$quantos old announcement(s) deleted.';
  @override
  String get adminNaoCarregouConversas => 'Couldn\'t load the conversations.';
  @override
  String get adminNenhumaMensagem => 'No messages yet. Whatever arrives at the channel\'s number shows up here — including delivery confirmation for the alerts the app sends.';
  @override
  String get adminEnvioIndisponivel => 'Sending from the panel isn\'t available yet: it depends on the production number and the message templates approved by Meta.';
  @override
  String get adminRespostaLivre => 'Free reply allowed';
  @override
  String get adminForaDaJanela => 'Outside the window: template only';
  @override
  String get adminJanelaAberta => '24h window open: once sending exists, you\'ll be able to reply with free text.';
  @override
  String get adminJanelaFechada => 'Outside the 24h window: you can only send a message template approved by Meta.';
  @override
  String get adminCargosTexto => 'Register new roles beyond subscriber/vip/admin and define each one\'s permissions.';
  @override
  String get adminCargosPendencia => 'Depends on a "cargos" collection in Firestore and on rewriting firestore.rules to read permissions from there, instead of the fixed role it checks today.';
  @override
  String get adminBadgesTexto => 'Grant catalog badges to users picked from the list.';
  @override
  String get adminBadgesPendencia => 'The "badges" field is locked against client writes in firestore.rules — granting a badge needs a Cloud Function with the Admin SDK.';
  @override
  String get adminNotificacoesTexto => 'Send a push with title and description to everyone or to a specific role only.';
  @override
  String get adminNotificacoesPendencia => 'Needs a Cloud Function firing through FCM. Sending by role requires subscribing each user to a per-role topic at sign-in.';

  // ----- Mensagens do WhatsApp no painel -----
  @override
  String get whatsappVideo => '[video]';
  @override
  String get whatsappAudio => '[audio]';
  @override
  String get whatsappLocalizacao => '[location]';
  @override
  String get whatsappEnviada => 'Sent';
  @override
  String get whatsappEntregue => 'Delivered';
  @override
  String get whatsappLida => 'Read';
  @override
  String get whatsappFalhou => 'Failed';
  @override
  String whatsappFalhouCom(String erro) => 'Failed: $erro';

  // ----- Datas e duracoes -----
  @override
  String dataHaMinutos(int minutos) => '${minutos}m ago';
  @override
  String dataHaHoras(int horas) => '${horas}h ago';
  @override
  String dataHaDias(int dias) => '${dias}d ago';
  @override
  String duracaoHorasMinutos(int horas, int minutos) => '${horas}h ${minutos}m';
  @override
  String duracaoMinutos(int minutos) => '${minutos}m';

  // ----- Formato de data (a ordem dia/mes inverte em en-US) -----
  @override
  String dataDiaMes(String dia, String mes) => '$mes/$dia';
  @override
  String dataDiaMesAno(String dia, String mes, String ano) => '$mes/$dia/$ano';
  @override
  String dataDiaMesHora(String dia, String mes, String hora, String minuto) => '$mes/$dia at $hora:$minuto';
  @override
  String dataDiaMesAnoHora(String dia, String mes, String ano, String hora, String minuto) => '$mes/$dia/$ano at $hora:$minuto';

  // ----- Resumo de midia do WhatsApp -----
  @override
  String get whatsappImagem => '[image]';
  @override
  String get whatsappDocumento => '[document]';
  @override
  String get whatsappFigurinha => '[sticker]';
  @override
  String get whatsappContato => '[contact]';

  // ----- O que faltou na primeira varredura -----
  @override
  String get feedEncerrada => 'ENDED';
  @override
  String get dataAgora => 'now';
  @override
  String duracaoSoHoras(int horas) => '${horas}h';
  @override
  String duracaoSegundos(int segundos) => '${segundos}s';
  @override
  String get cadastroAntigoTitulo => 'CREATE YOUR ACCOUNT';
  @override
  String get cadastroEscolhaAvatar => 'Pick your avatar';
  @override
  String get cadastroJaTemConta => 'Already have an account? ';
  @override
  String get cadastroFazerLogin => 'Sign in';
  @override
  String get cadastroDigiteEmail => 'Type your email';
  @override
  String get validaNickComArrobaAntigo => 'The nickname can\'t contain @.';
  @override
  String apenasOCodigo(String codigo) => '(code: $codigo)';

  // ----- Selos de tipo de post, no painel -----
  @override
  String get seloAviso => 'NOTICE';
  @override
  String get seloFoto => 'PHOTO';
  @override
  String get seloEnquete => 'POLL';
  @override
  String get seloLive => 'LIVE';
  @override
  String get adminVocePrefixo => 'You: ';
}
