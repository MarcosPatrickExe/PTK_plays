import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data' show Uint8List;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/BloqueioDaConta.dart';
import '../models/UserModel.dart';
import '../../i18n/Idioma.dart';

/// Como a conta prova que e ela mesma antes de uma operacao sensivel.
///
/// Existe porque o Firebase exige reautenticacao recente pra apagar a
/// conta, e cada provedor reautentica de um jeito. Ver
/// [AuthRepository.formaDeReautenticar].
enum FormaDeReautenticar { senha, google, apple }

/// A forma em que o e-mail e guardado e comparado: sem espaco e em
/// minusculas.
///
/// Existe porque a consulta do Firestore e **sensivel a maiuscula** e nao
/// tem como pedir o contrario. Sem normalizar na escrita e na leitura,
/// "Fulano@Gmail.com" e "fulano@gmail.com" seriam dois enderecos
/// diferentes pro pre-teste de e-mail repetido — e ele deixaria passar o
/// duplicado que estava tentando evitar. O proprio Firebase Auth ja guarda
/// o e-mail em minusculas.
String emailNormalizado(String email) => email.trim().toLowerCase();

/// A decisao em si, separada do Firebase pra poder ser testada.
///
/// [AuthRepository] cria `FirebaseAuth.instance` no proprio campo, entao
/// nada dentro dele roda em `flutter test`. Esta funcao recebe so a lista
/// de `providerId` que o Firebase devolveria, e e ela que carrega a regra
/// que importa.
///
/// **Senha ganha de todas**, quando existe: quem tem senha E login social
/// prova quem e sem abrir a folha do provedor, que e o caminho mais curto
/// e o que nao depende de rede externa na hora de apagar a conta.
FormaDeReautenticar formaParaProvedores(Iterable<String> provedores) {
  final ids = provedores.toSet();
  if (ids.contains('password')) return FormaDeReautenticar.senha;
  if (ids.contains('apple.com')) return FormaDeReautenticar.apple;
  if (ids.contains('google.com')) return FormaDeReautenticar.google;
  // Sem provedor reconhecido, cai na senha: e o unico caminho que o app
  // sabe percorrer sozinho, e o erro que vier dali diz o que houve.
  return FormaDeReautenticar.senha;
}

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // "Web client" gerado automaticamente pelo Firebase ao ativar o Google
  // Sign-In (google-services.json / GoogleService-Info.plist). Nao e segredo,
  // e o identificador publico usado pra validar o idToken em qualquer plataforma.
  static const _webClientId = '696548413882-caba685okm8d002hvvq60k32ceim56bc.apps.googleusercontent.com';
  static const _iosClientId = '696548413882-0f1s66gkjohih26in5roq2jf1r4na18b.apps.googleusercontent.com';

  bool _googleSignInInicializado = false;

  User? get usuarioAtual => _auth.currentUser;

  Future<void> cadastrar({
    required String nickname,
    required String email,
    required String senha,
    String telefoneWhatsapp = '',
    String avatarPreset = '',
  }) async {
    final nicknameChave = nickname.trim().toLowerCase();

    final mapeamentoExistente = await _firestore.collection('nicknamesParaEmail').doc(nicknameChave).get();
    if (mapeamentoExistente.exists) {
      throw FirebaseAuthException(code: 'nickname-em-uso', message: textos.erroNicknameEmUsoCurto);
    }

    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    await credential.user!.updateDisplayName(nickname);

    final novoUsuario = UserModel.novoInscrito(
      uid: uid,
      nickname: nickname,
      email: email,
      telefoneWhatsapp: telefoneWhatsapp,
      avatarPreset: avatarPreset,
    );
    await _firestore.collection('users').doc(uid).set(novoUsuario.toFirestore());

    await _firestore.collection('nicknamesParaEmail').doc(nicknameChave).set({
      'uid': uid,
      'email': emailNormalizado(email),
    });
  }

  /// Se ja existe conta com este e-mail.
  ///
  /// **Consulta `nicknamesParaEmail`, e nao o Firebase Auth.** O caminho
  /// obvio seria `fetchSignInMethodsForEmail`, mas ele foi descontinuado
  /// justamente por ser um oraculo de enumeracao: qualquer um podia
  /// perguntar "essa pessoa tem conta aqui?" sem limite. Com a protecao
  /// contra enumeracao ligada no Console — que e o padrao em projeto novo —
  /// ele devolve lista vazia sempre, e um pre-teste em cima dele mentiria
  /// dizendo que todo e-mail esta livre.
  ///
  /// **Ha um buraco conhecido**: quem entrou pelo Google/Apple e abandonou
  /// o cadastro antes da etapa do nick nao tem reserva aqui, e passa por
  /// livre. O Firebase ainda barra no fim, com `email-already-in-use` — o
  /// pre-teste adianta o aviso na maioria dos casos, nao substitui a
  /// checagem de verdade.
  Future<bool> emailJaCadastrado(String email) async {
    final alvo = emailNormalizado(email);
    if (alvo.isEmpty) return false;

    final achados = await _firestore
        .collection('nicknamesParaEmail')
        .where('email', isEqualTo: alvo)
        .limit(1)
        .get();

    return achados.docs.isNotEmpty;
  }

  /// Completa o perfil de quem entrou pelo Google/Apple e caiu no cadastro
  /// em etapas.
  ///
  /// **Nao cria conta nenhuma** — e essa a diferenca pro [cadastrar], e o
  /// motivo deste metodo existir. Ate 13/set o `CriarConta` chamava
  /// `cadastrar` nos dois fluxos, e no social isso virava
  /// `createUserWithEmailAndPassword('', '')`: a conta JA existia (o
  /// provedor criou no login), e o cadastro social simplesmente nao tinha
  /// como ser concluido. Quem entrasse pela Apple ficava presoted na ultima
  /// etapa pra sempre.
  ///
  /// [emailInformado] so vem preenchido quando a pessoa escondeu o e-mail
  /// real na Apple (ver `precisaPedirEmail` em CriarConta.dart). Nos demais
  /// casos vale o e-mail que o provedor ja deu.
  Future<void> completarCadastroSocial({
    required String nickname,
    required String telefoneWhatsapp,
    required String avatarPreset,
    String emailInformado = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found', message: textos.erroSessaoExpiradaCurta);
    }

    final chave = nickname.trim().toLowerCase();
    final mapeamentoExistente = await _firestore.collection('nicknamesParaEmail').doc(chave).get();
    // A comparacao com o uid importa: sem ela, alguem que voltasse pra
    // completar o cadastro com o MESMO nick que ja reservou seria barrado
    // pelo proprio registro.
    if (mapeamentoExistente.exists && mapeamentoExistente.data()?['uid'] != user.uid) {
      throw FirebaseAuthException(code: 'nickname-em-uso', message: textos.erroNicknameEmUsoCurto);
    }

    final email = emailInformado.trim().isNotEmpty ? emailInformado.trim() : (user.email ?? '');

    await user.updateDisplayName(nickname);

    // merge, e nao set inteiro: o documento ja nasceu no login social
    // (_sincronizarUsuarioNoFirestore) com cargo, badges e contadores, e as
    // regras do Firestore recusam um update que mude qualquer um dos tres.
    await _firestore.collection('users').doc(user.uid).set(
      {
        'nickname': nickname,
        'email': email,
        'telefoneWhatsapp': telefoneWhatsapp,
        'avatarPreset': avatarPreset,
        ...UserModel.touchUltimoAcesso(),
      },
      SetOptions(merge: true),
    );

    // Sem esta reserva, a pessoa nao conseguiria entrar pelo nickname
    // depois — o login por nick resolve o e-mail justamente por aqui.
    await _firestore.collection('nicknamesParaEmail').doc(chave).set({
      'uid': user.uid,
      'email': emailNormalizado(email),
    });
  }

  /// Atualiza nickname e/ou telefone de WhatsApp do usuario logado.
  /// Se o nickname mudou, remapeia nicknamesParaEmail (usado pelo login por
  /// nickname) pra continuar resolvendo pro email correto.
  Future<void> atualizarPerfil({
    required String uid,
    required String nicknameAtual,
    required String novoNickname,
    required String email,
    required String telefoneWhatsapp,
    required String avatarPreset,
  }) async {
    final chaveAtual = nicknameAtual.trim().toLowerCase();
    final novaChave = novoNickname.trim().toLowerCase();

    if (novaChave != chaveAtual) {
      final mapeamentoExistente = await _firestore.collection('nicknamesParaEmail').doc(novaChave).get();
      if (mapeamentoExistente.exists) {
        throw FirebaseAuthException(code: 'nickname-em-uso', message: textos.erroNicknameEmUsoCurto);
      }

      await _firestore.collection('nicknamesParaEmail').doc(chaveAtual).delete();
      await _firestore.collection('nicknamesParaEmail').doc(novaChave).set({'uid': uid, 'email': email});
      await _auth.currentUser?.updateDisplayName(novoNickname);
    }

    // ultimoAcesso precisa ser tocado em toda escrita: a regra de seguranca
    // do Firestore exige request.resource.data.ultimoAcesso == request.time
    // em qualquer update (ver firestore.rules), senao a escrita e recusada.
    await _firestore.collection('users').doc(uid).set(
      {
        'nickname': novoNickname,
        'telefoneWhatsapp': telefoneWhatsapp,
        'avatarPreset': avatarPreset,
        ...UserModel.touchUltimoAcesso(),
      },
      SetOptions(merge: true),
    );
  }

  /// Aceita tanto email quanto nickname no campo de login: se tiver "@",
  /// trata como email direto; senao, resolve o email pelo mapeamento
  /// nicknamesParaEmail antes de autenticar.
  Future<String> _resolverEmailParaLogin(String loginOuEmail) async {
    final valor = loginOuEmail.trim();
    if (valor.contains('@')) return valor;

    final doc = await _firestore.collection('nicknamesParaEmail').doc(valor.toLowerCase()).get();
    if (!doc.exists) {
      throw FirebaseAuthException(code: 'user-not-found', message: textos.erroUsuarioNaoEncontrado);
    }

    return doc.data()!['email'] as String;
  }

  Future<BloqueioDaConta?> login({required String loginOuEmail, required String senha}) async {
    final email = await _resolverEmailParaLogin(loginOuEmail);
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: senha);
    final uid = credential.user!.uid;

    final bloqueio = await _barrarSeBloqueado(uid);
    if (bloqueio != null) return bloqueio;

    await _firestore.collection('users').doc(uid).set(
      UserModel.touchUltimoAcesso(),
      SetOptions(merge: true),
    );
    return null;
  }

  /// Lê o estado de moderação de quem acabou de entrar e, se estiver
  /// bloqueado, **desloga antes de devolver**.
  ///
  /// A ordem importa: a regra do Firestore só libera ler `users/{uid}` pra
  /// quem está logado, então a leitura tem que acontecer com a sessão ainda
  /// de pé. Logo depois ela cai.
  ///
  /// Sem isto, quem foi banido entrava normalmente e só era barrado quando
  /// o `ContaGate` reagisse — ou seja, **depois** de já estar dentro do app.
  Future<BloqueioDaConta?> _barrarSeBloqueado(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final bloqueio = bloqueioDe(UserModel.fromFirestore(doc.data() ?? {}));
    if (bloqueio == null) return null;

    await _auth.signOut();
    return bloqueio;
  }

  Future<void> _garantirGoogleSignInInicializado() async {
    if (_googleSignInInicializado) return;

    await GoogleSignIn.instance.initialize(
      clientId: (!kIsWeb && Platform.isIOS) ? _iosClientId : null,
      serverClientId: kIsWeb ? null : _webClientId,
    );

    _googleSignInInicializado = true;
  }

  /// Retorna true quando a conta acabou de ser criada — e o que o Login usa
  /// pra mandar a pessoa completar o cadastro (nick, foto e WhatsApp) em vez
  /// de cair direto no feed.
  Future<({bool contaNova, BloqueioDaConta? bloqueio})> loginComGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _garantirGoogleSignInInicializado();
      final conta = await GoogleSignIn.instance.authenticate();
      final idToken = conta.authentication.idToken;

      credential = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    }

    return _sincronizarUsuarioNoFirestore(credential.user!);
  }

  /// Fluxo exigido pela Apple (guideline 4.8) como alternativa equivalente
  /// ao Google Sign-In. So funciona em iOS/macOS: nao ha configuracao de
  /// Service ID/return URL feita pro fluxo web do pacote em Android/Web.
  /// Ver [loginComGoogle] sobre o retorno.
  Future<({bool contaNova, BloqueioDaConta? bloqueio})> loginComApple() async {
    final rawNonce = _gerarNonce();
    final nonce = _sha256DoNonce(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);
    final user = credential.user!;

    // A Apple so retorna nome na primeira autorizacao; usa aqui pra
    // preencher o profile do Firebase Auth caso ainda esteja vazio.
    if (user.displayName == null || user.displayName!.isEmpty) {
      final nomeCompleto = [appleCredential.givenName, appleCredential.familyName]
          .where((parte) => parte != null && parte.isNotEmpty)
          .join(' ');
      if (nomeCompleto.isNotEmpty) await user.updateDisplayName(nomeCompleto);
    }

    return _sincronizarUsuarioNoFirestore(user, nicknameSugerido: appleCredential.givenName);
  }

  /// Cria o documento do usuario no primeiro login social, ou so atualiza o
  /// ultimo acesso nos seguintes.
  ///
  /// `contaNova` e true quando acabou de criar — e o que o Login usa pra
  /// mandar a pessoa completar o cadastro em vez de cair no feed.
  /// `bloqueio` vem preenchido quando a conta esta banida/suspensa; nesse
  /// caso a sessao **ja foi encerrada** aqui dentro.
  Future<({bool contaNova, BloqueioDaConta? bloqueio})> _sincronizarUsuarioNoFirestore(
    User user, {
    String? nicknameSugerido,
  }) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();

    // Antes de tocar em qualquer coisa: conta banida que volta pelo Google
    // ou pela Apple tem que ser barrada igual a que volta por senha. Sem
    // isto, o caminho social seria a porta dos fundos do banimento.
    if (doc.exists) {
      final bloqueio = bloqueioDe(UserModel.fromFirestore(doc.data() ?? {}));
      if (bloqueio != null) {
        await _auth.signOut();
        return (contaNova: false, bloqueio: bloqueio);
      }
    }

    if (!doc.exists) {
      final novoUsuario = UserModel.novoInscrito(
        uid: user.uid,
        nickname: user.displayName ?? nicknameSugerido ?? user.email?.split('@').first ?? textos.cargoJogador,
        email: user.email ?? '',
        fotoUrl: user.photoURL ?? '',
      );
      await _firestore.collection('users').doc(user.uid).set(novoUsuario.toFirestore());
      return (contaNova: true, bloqueio: null);
    } else {
      // Conta que ja existia: so toca o ultimoAcesso, MENOS quando ela esta
      // sem foto nenhuma e o provedor social traz uma. E o caso de quem se
      // cadastrou por email/senha e so depois entrou pelo Google/Apple — o
      // avatar do provedor nunca chegava ao Firestore porque este ramo so
      // era escrito com o ultimoAcesso. Foto propria ja enviada e preset
      // escolhido continuam intocados: a condicao exige os dois vazios.
      final dados = doc.data() ?? {};
      final semFotoPropria = (dados['fotoUrl'] as String? ?? '').isEmpty;
      final semPreset = (dados['avatarPreset'] as String? ?? '').isEmpty;
      final fotoDoProvedor = user.photoURL ?? '';

      await _firestore.collection('users').doc(user.uid).set(
        {
          if (semFotoPropria && semPreset && fotoDoProvedor.isNotEmpty) 'fotoUrl': fotoDoProvedor,
          ...UserModel.touchUltimoAcesso(),
        },
        SetOptions(merge: true),
      );
      return (contaNova: false, bloqueio: null);
    }
  }

  /// String aleatoria criptograficamente segura usada como nonce anti-replay
  /// no fluxo OpenID Connect da Apple.
  String _gerarNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256DoNonce(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Stream<UserModel?> streamUsuario(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? UserModel.fromFirestore(doc.data()!) : null,
    );
  }

  /// Como [streamUsuario], mas acompanha login/logout em si — troca de
  /// assinatura sozinho quando o uid muda, em vez de ficar preso ao uid
  /// que estava logado no instante em que o stream foi criado (que e como
  /// [streamUsuario] se comporta quando chamado uma vez soh).
  ///
  /// Existe pro `ContaGate` (`lib/components/ContaGate.dart`), o unico
  /// lugar que precisa disso: ele envolve o app inteiro e nunca e
  /// desmontado por uma troca de tela, entao nao pode depender de ser
  /// recriado a cada login pra saber de quem e a vez de ouvir.
  Stream<UserModel?> streamUsuarioReativo() {
    final controlador = StreamController<UserModel?>.broadcast();
    StreamSubscription<UserModel?>? assinaturaDoDocumento;

    final assinaturaDoAuth = _auth.authStateChanges().listen((user) {
      assinaturaDoDocumento?.cancel();
      if (user == null) {
        controlador.add(null);
        return;
      }
      assinaturaDoDocumento = streamUsuario(user.uid).listen(controlador.add, onError: controlador.addError);
    });

    controlador.onCancel = () {
      assinaturaDoDocumento?.cancel();
      assinaturaDoAuth.cancel();
    };

    return controlador.stream;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Envia o email de redefinicao de senha do Firebase Auth (link que leva
  /// a uma pagina hospedada pelo proprio Firebase pra escolher uma senha
  /// nova, sem precisar saber a senha atual). Uso: usuario logado que
  /// esqueceu a senha atual em EditarPerfil, ou (futuramente) a tela de
  /// login pra quem nao consegue entrar.
  Future<void> enviarEmailRedefinicaoSenha({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Como esta conta prova que e ela mesma antes de uma operacao sensivel.
  ///
  /// O Firebase exige reautenticacao recente pra apagar a conta, e o jeito
  /// de reautenticar depende de como a pessoa entrou. Ate 14/set isso era
  /// sempre `EmailAuthProvider.credential`, e por isso **quem entrou pelo
  /// Google ou pela Apple simplesmente nao conseguia apagar a propria
  /// conta**: o `user.email!` podia nem existir, e a senha pedida na tela
  /// nao existia em lugar nenhum.
  FormaDeReautenticar formaDeReautenticar() => formaParaProvedores(
        _auth.currentUser?.providerData.map((p) => p.providerId) ?? const <String>[],
      );

  /// Apaga a conta e tudo que esta preso a ela.
  ///
  /// **A ordem nao e arbitraria.** A conta do Auth e a ULTIMA a cair: as
  /// regras do Firestore e do Storage so autorizam apagar o que e "meu"
  /// enquanto `request.auth` existe. Apagando o login primeiro, todo o
  /// resto viraria lixo impossivel de remover por qualquer caminho que nao
  /// seja o Admin SDK.
  ///
  /// Pelo mesmo motivo, `users/{uid}` e o ultimo documento do Firestore a
  /// sair: as regras de post fazem `get()` nele pra descobrir o cargo de
  /// quem chama. Sem o documento, a regra nao avalia e a exclusao dos
  /// proprios posts seria negada.
  ///
  /// Falhar no meio deixa a conta existindo, e nao meio apagada — de
  /// proposito: da pra tentar de novo. O contrario (login apagado, dados
  /// de pe) nao teria conserto.
  Future<void> excluirConta({String? senha}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final forma = formaDeReautenticar();
    AuthorizationCredentialAppleID? credencialApple;

    switch (forma) {
      case FormaDeReautenticar.senha:
        final credential = EmailAuthProvider.credential(email: user.email!, password: senha ?? '');
        await user.reauthenticateWithCredential(credential);
      case FormaDeReautenticar.google:
        await user.reauthenticateWithCredential(await _credencialDoGoogle());
      case FormaDeReautenticar.apple:
        credencialApple = await _credencialDaApple();
        await user.reauthenticateWithCredential(
          OAuthProvider('apple.com').credential(
            idToken: credencialApple.identityToken,
            rawNonce: _nonceDaUltimaApple,
          ),
        );
    }

    await _apagarDadosDoUsuario(user.uid);

    // A Apple exige (desde jun/2022) que apagar a conta no app revogue o
    // token dela tambem — senao o "Sign in with Apple" continua listando o
    // PTK Plays nos ajustes do aparelho. Depende da configuracao de fluxo
    // OAuth no Console (Team ID, Key ID e a chave .p8); sem ela isto
    // lanca, e ai a exclusao segue mesmo assim. Travar a exclusao da conta
    // por causa da revogacao seria trocar um problema por um pior.
    if (credencialApple?.authorizationCode != null) {
      try {
        await _auth.revokeTokenWithAuthorizationCode(credencialApple!.authorizationCode);
      } catch (e, stack) {
        debugPrint('revogacao do token da Apple falhou (a conta foi apagada assim mesmo): $e\n$stack');
      }
    }

    await user.delete();
  }

  /// Tudo que esta preso ao uid e que o cliente tem permissao de remover.
  ///
  /// **O que NAO esta aqui, e por que.** As mensagens em
  /// `mensagensWhatsapp` sao indexadas por telefone e so o webhook escreve
  /// nelas (`write: if false` vale pra todo mundo, admin incluido) —
  /// limpa-las precisa do Admin SDK, numa Cloud Function que ainda nao
  /// existe. Comentarios e curtidas tambem nao aparecem porque nao existem
  /// como documento: hoje sao so contadores dentro do post.
  Future<void> _apagarDadosDoUsuario(String uid) async {
    final posts = await _firestore.collection('posts').where('autorUid', isEqualTo: uid).get();
    await _apagarEmLote(posts.docs.map((doc) => doc.reference));

    await _removerVotosEmEnquetes(uid);
    await _removerCurtidas(uid);

    // Indexada pelo nickname, nao pelo uid — por isso vem por consulta. Sem
    // apagar, o nick fica preso pra sempre a uma conta que nao existe mais.
    final nicknames = await _firestore.collection('nicknamesParaEmail').where('uid', isEqualTo: uid).get();
    await _apagarEmLote(nicknames.docs.map((doc) => doc.reference));

    await _apagarPasta('fotos_perfil/$uid');
    await _apagarPasta('posts_midia/$uid');

    // Por ultimo: as regras dos passos acima consultam este documento.
    await _firestore.collection('users').doc(uid).delete();
  }

  /// Tira o uid das enquetes em que a pessoa votou — inclusive nas dos
  /// outros, que ela nao pode apagar.
  ///
  /// **A contagem nao e mexida, e isso e deliberado.** O que identifica a
  /// pessoa e o uid guardado em `votantes`/`votosPorUsuario`; o total de
  /// votos de cada opcao e numero agregado, que nao aponta pra ninguem.
  /// Tirar o nome e deixar o numero e exatamente o que anonimizar
  /// significa — e mexer no total abriria, na regra, uma porta pro cliente
  /// reescrever placar de enquete alheia.
  Future<void> _removerVotosEmEnquetes(String uid) async {
    final votadas = await _firestore.collection('posts').where('votantes', arrayContains: uid).get();

    for (final doc in votadas.docs) {
      await doc.reference.update({
        'votantes': FieldValue.arrayRemove([uid]),
        'votosPorUsuario.$uid': FieldValue.delete(),
      });
    }
  }

  /// Tira o uid dos posts que a pessoa curtiu — inclusive dos outros, que
  /// ela nao pode apagar.
  ///
  /// Diferente das enquetes, aqui nao sobra numero nenhum: a contagem de
  /// curtidas **e** o tamanho da lista, entao sair da lista ja desconta.
  Future<void> _removerCurtidas(String uid) async {
    final curtidos = await _firestore.collection('posts').where('curtidoPor', arrayContains: uid).get();

    for (final doc in curtidos.docs) {
      await doc.reference.update({
        'curtidoPor': FieldValue.arrayRemove([uid]),
      });
    }
  }

  /// O Storage nao apaga pasta: apaga arquivo. `listAll` devolve o que tem
  /// dentro, e cada um sai individualmente.
  Future<void> _apagarPasta(String caminho) async {
    try {
      final conteudo = await _storage.ref(caminho).listAll();
      await Future.wait(conteudo.items.map((item) => item.delete()));
    } catch (e, stack) {
      // Pasta que nunca existiu (conta sem foto propria, ou sem post com
      // midia) e o caso comum, nao um erro. Parar a exclusao aqui seria
      // impedir de apagar a conta justamente quem menos publicou.
      debugPrint('limpeza de $caminho falhou ou nao havia nada: $e\n$stack');
    }
  }

  /// Um lote do Firestore aceita ate 500 operacoes.
  Future<void> _apagarEmLote(Iterable<DocumentReference> referencias) async {
    const tamanhoDoLote = 500;
    final todas = referencias.toList();

    for (var inicio = 0; inicio < todas.length; inicio += tamanhoDoLote) {
      final fim = (inicio + tamanhoDoLote).clamp(0, todas.length);
      final lote = _firestore.batch();
      for (final referencia in todas.sublist(inicio, fim)) {
        lote.delete(referencia);
      }
      await lote.commit();
    }
  }

  Future<AuthCredential> _credencialDoGoogle() async {
    if (kIsWeb) {
      // Na web nao ha `authenticate()`: o popup devolve a credencial junto
      // com o login, e e ele que serve pra reautenticar.
      final resultado = await _auth.signInWithPopup(GoogleAuthProvider());
      return resultado.credential!;
    }

    await _garantirGoogleSignInInicializado();
    final conta = await GoogleSignIn.instance.authenticate();
    return GoogleAuthProvider.credential(idToken: conta.authentication.idToken);
  }

  String _nonceDaUltimaApple = '';

  Future<AuthorizationCredentialAppleID> _credencialDaApple() async {
    _nonceDaUltimaApple = _gerarNonce();

    return SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: _sha256DoNonce(_nonceDaUltimaApple),
    );
  }

  /// Envia os bytes (ja recortados/redimensionados por ModalCropFoto) pro
  /// Firebase Storage e grava a fotoUrl resultante no perfil, limpando o
  /// avatarPreset — a foto enviada passa a ser o avatar ativo, ja que
  /// chavePresetParaExibir da prioridade ao preset sobre fotoUrl quando os
  /// dois estao preenchidos.
  Future<String> atualizarFotoPerfil({required String uid, required Uint8List bytes}) async {
    final ref = _storage.ref('fotos_perfil/$uid/foto.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).set(
      {'fotoUrl': url, 'avatarPreset': '', ...UserModel.touchUltimoAcesso()},
      SetOptions(merge: true),
    );

    return url;
  }

  /// So funciona pra contas com provider de email/senha (ver
  /// AuthViewModel.temSenhaEmail) — Firebase exige reautenticacao recente
  /// pra operacoes sensiveis como troca de senha.
  Future<void> alterarSenha({required String senhaAtual, required String novaSenha}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(email: user.email!, password: senhaAtual);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(novaSenha);
  }
}
