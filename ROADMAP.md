# Roadmap / Pendências futuras

Itens identificados mas propositalmente adiados por não serem bloqueantes no momento.

## Recuperação de senha por e-mail/SMS/WhatsApp (18/ago/2026)

Usuário pediu recuperação de senha via código de verificação (email, SMS
e/ou WhatsApp) em vez de exigir a senha atual. Avaliação de cada canal:

- **Email — implementado.** `AuthRepository.enviarEmailRedefinicaoSenha`
  usa `FirebaseAuth.sendPasswordResetEmail`, recurso nativo do Firebase
  Auth: nenhuma infraestrutura nova, nenhuma revisão externa, funciona
  imediatamente (o projeto já usa Firebase Auth pra tudo). Botão "Esqueceu
  sua senha atual? Enviar link por e-mail" adicionado dentro do card
  "Alterar senha (opcional)" em EditarPerfil.dart, usando o email já
  cadastrado na conta (não precisa digitar de novo). Só aparece pra contas
  com provider de email/senha (`temSenhaEmail`), mesma regra da seção de
  troca de senha — Firebase recusa o envio pra contas só-Google/só-Apple.
- **SMS — não implementado, mas não precisa de biblioteca de terceiros.**
  O Firebase Auth já tem Phone Authentication (SMS OTP) nativo — não é uma
  "biblioteca pra mandar SMS" separada, é um provider de login que o
  próprio `firebase_auth` já suporta. Custo de implementação: habilitar
  "Phone" em Firebase Console → Authentication → Sign-in method, configurar
  reCAPTCHA pra Web (`RecaptchaVerifier`), e criar o fluxo de UI (digitar
  telefone → receber código → confirmar). Tem cota gratuita no Firebase,
  depois é cobrado por SMS enviado. Bem mais rápido que integrar uma API de
  SMS de terceiro (Twilio etc.), mas ainda exige configuração no Console e
  testes com número de telefone real.
- **WhatsApp — bloqueado em infraestrutura externa já documentada.** Depende
  da aprovação do app no Meta for Developers (ver seção "Integração futura
  com a API do WhatsApp Business" abaixo), processo de revisão que não está
  concluído. É o canal mais lento dos três — nem começa até isso ser
  resolvido pelo usuário.

**Conclusão: email é de longe o mais rápido** (já está pronto), SMS é
factível mas exige configuração adicional no Firebase Console + testes com
telefone real, WhatsApp depende de aprovação externa que já está em
andamento separadamente. Quando o usuário decidir priorizar SMS, o próximo
passo é habilitar Phone Authentication no Firebase Console.

## Backend (Cloud Functions) pro WhatsApp Business — webhook implementado (20/ago/2026)

Decisão de arquitetura (dois apps no Meta): o usuário pretende usar o mesmo
número/canal WhatsApp pra dois projetos diferentes — **PTK Plays**
(recuperação de senha via código) e **PTK AI Studio** (painel separado, de
edição/publicação automática de vídeos das lives em Threads/Instagram/
Facebook). Recomendação dada: **dois apps separados no Meta for
Developers**, sob o mesmo Portfólio empresarial — evita misturar o escopo
do App Review (mensageria WhatsApp x publicação de conteúdo são fluxos
muito diferentes pra justificar na mesma revisão) e isola o risco de uma
suspensão de um produto derrubar o outro. O usuário já tinha adicionado
Threads e WhatsApp no mesmo app por engano; como não achou um botão de
remover o caso de uso do Threads na UI atual do Meta, a decisão foi deixar
o Threads inerte nesse app (sem configurar nem submeter permissões dele) e
seguir só com WhatsApp aqui — o app dedicado ao PTK AI Studio (Threads +
Instagram + Facebook) fica pra quando esse projeto for priorizado.

Arquitetura de backend escolhida: **Cloud Functions (Firebase, 2ª geração)**
pra receber webhooks (WhatsApp agora; Twitch/Kick no futuro, pro PTK AI
Studio) e fazer chamadas agendadas (polling do YouTube) — já roda sobre a
mesma infraestrutura do Cloud Run por baixo, mas com integração pronta com
Firestore/Auth e gatilhos (`onRequest`/`onSchedule`) sem boilerplate.
**Cloud Run Jobs** fica reservado pra outra peça, futura, do PTK AI Studio:
processamento pesado de vídeo (corte/edição automática), que não deve rodar
dentro do handler de um webhook (precisa responder em segundos).

Implementado nesta etapa (`functions/`, novo diretório na raiz do repo):
- `functions/index.js`: Cloud Function HTTPS `whatsappWebhook`. No `GET`,
  responde o handshake de verificação do Meta (`hub.mode`/`hub.verify_token`/
  `hub.challenge`). No `POST`, valida a assinatura `X-Hub-Signature-256`
  (HMAC-SHA256 com o App Secret) antes de aceitar qualquer evento — sem
  isso, qualquer um que descobrisse a URL pública do webhook poderia mandar
  eventos falsos. Por enquanto só loga o evento e responde 200; a lógica de
  enviar/verificar código de recuperação de senha é a próxima etapa,
  depois que o webhook for aceito pelo Meta.
- `functions/src/webhook.js`: lógica pura (`verificarHandshakeWebhook`,
  `assinaturaValida`), testada isoladamente em
  `functions/test/webhook.test.js` (8 testes, `npm test` dentro de
  `functions/`) sem precisar de um request HTTP real nem do emulador.
- `firebase.json` ganhou a seção `functions` (aponta pro diretório
  `functions/`); `.firebaserc` criado apontando o projeto padrão pra
  `ptk-plays`.
- Segredos (`WHATSAPP_VERIFY_TOKEN`, `WHATSAPP_APP_SECRET`) usam
  `defineSecret` (Secret Manager) — nunca ficam no código. Precisam ser
  configurados manualmente pelo usuário via `firebase functions:secrets:set`
  (CLI, rodado no Google Cloud Shell — mesmo lugar usado antes pro
  `gsutil cors set`), já que este ambiente de desenvolvimento não tem
  `firebase login` autenticado com a conta do usuário.

**Pendente (ação do usuário, fora deste ambiente):**
1. Rodar `firebase functions:secrets:set WHATSAPP_VERIFY_TOKEN` e
   `WHATSAPP_APP_SECRET` no Cloud Shell, depois `firebase deploy --only
   functions` (projeto `ptk-plays` já no plano Blaze).
2. Colar a URL da function implantada (formato
   `https://<região>-ptk-plays.cloudfunctions.net/whatsappWebhook`) e o
   mesmo valor de `WHATSAPP_VERIFY_TOKEN` no formulário "Configurar
   webhooks" do Meta for Developers (Etapa 2. Configuração de produção).
3. Depois do webhook aceito: implementar as próximas Cloud Functions
   (`enviarCodigoRecuperacaoWhatsapp` / `verificarCodigoRecuperacaoWhatsapp`)
   e criar/aprovar um template de mensagem categoria "Authentication" no
   WhatsApp Manager (necessário pra iniciar conversa fora da janela de 24h
   — não dá pra mandar texto livre pro primeiro contato).

**Campo de email no cadastro**: já existe desde sempre (`Cadastro.dart`
sempre exigiu email pra criar a conta com `createUserWithEmailAndPassword`)
— nenhuma mudança necessária lá. Só faltava em EditarPerfil.dart, que agora
mostra o email da conta (somente leitura — trocar o email em si não foi
pedido, e é uma operação mais delicada: exigiria reautenticação e atualizar
o mapeamento `nicknamesParaEmail` usado pro login por nickname).

## Upload de foto de perfil, troca de senha e avatar padrão (implementado em 17/ago/2026)

Implementado em `lib/view/EditarPerfil.dart` a pedido do usuário:

- **Foto de perfil com upload próprio**: novo componente no topo da tela
  (`_FotoPerfilEditavel`), com um botão de lápis sobreposto que abre o
  seletor de imagens do dispositivo (`image_picker`) e depois um modal
  fullscreen de recorte/zoom (`lib/components/ModalCropFoto.dart` — pan
  livre com `InteractiveViewer`, zoom por botões +/-, captura via
  `RenderRepaintBoundary.toImage()`). Os bytes recortados (PNG) são
  enviados pro Firebase Storage em `fotos_perfil/{uid}/foto.png`
  (`AuthRepository.atualizarFotoPerfil`), que atualiza `fotoUrl` no
  Firestore e **limpa `avatarPreset`** — a foto enviada vira o avatar ativo,
  já que o preset tem prioridade sobre `fotoUrl` na exibição (ver abaixo).
- **Trocar senha**: nova seção opcional em EditarPerfil (3 campos: senha
  atual, nova senha, confirmar), só visível pra contas com provider de
  email/senha (`AuthViewModel.temSenhaEmail`, contas só-Google/só-Apple não
  veem essa seção). Reautentica com a senha atual antes de trocar
  (`AuthRepository.alterarSenha`), como já era feito em `excluirConta`.
- **Avatar padrão pra contas legadas**: contas sem `avatarPreset` escolhido
  e sem `fotoUrl` (criadas antes do recurso de avatares existir, ou login
  social sem foto do provedor) agora caem no preset "Inscrito do canal" em
  vez de um ícone genérico — `AvatarPreset.chavePresetParaExibir` centraliza
  essa prioridade (preset > fotoUrl > padrão) e é usada tanto em
  `Profile.dart` quanto no topo de `EditarPerfil.dart`, pra nunca mostrar
  coisas diferentes nas duas telas.
- **Bugfix da máscara de WhatsApp**: `MascaraTelefoneWhatsapp.formatEditUpdate`
  extraía dígitos do texto inteiro, incluindo o "+55" fixo do prefixo (que
  também contém dígitos '5'), fazendo qualquer edição/apagamento no meio da
  máscara (não só no final) corromper o número. Corrigido removendo o
  prefixo fixo antes de extrair dígitos, e reposicionando o cursor com base
  em quantos dígitos reais existiam antes dele (não sempre no fim).

**Pendência que só o usuário consegue resolver (infraestrutura externa)**:
o Firebase Storage precisa estar habilitado no Firebase Console pro projeto
`ptk-plays`, e as regras em `storage.rules` (criado nesse commit, cada
usuário só escreve na própria pasta `fotos_perfil/{uid}/`, até 5MB, só
imagens) precisam ser publicadas lá — mesmo processo manual já feito antes
pro `firestore.rules`. Sem isso, o upload de foto falha com erro de
permissão. Não dá pra validar o upload de ponta a ponta neste ambiente de
desenvolvimento (sem acesso ao Firebase real); o fluxo de UI (seleção,
recorte, zoom, pan) foi validado interativamente num navegador.

### Foto enviada não aparece na Web (18/ago/2026): provável falta de CORS no bucket

Depois do Storage habilitado e das regras publicadas, o usuário conseguiu
subir a foto (sem erro), mas ela aparece como um círculo em branco (só o
gradiente de fundo, sem a imagem) tanto em EditarPerfil quanto em Profile,
mesmo depois do ícone de carregamento sumir.

**Causa mais provável**: o build Web usa o renderer CanvasKit, que carrega
imagens de rede via `fetch()` pra decodificar via Skia — isso ativa a
checagem de CORS do navegador, diferente de uma tag `<img>` comum. Buckets
do Firebase Storage não vêm com CORS liberado por padrão, então o
`fetch()` da `fotoUrl` é bloqueado silenciosamente (sem erro visível pro
usuário, só a imagem não aparece). É um problema conhecido de Flutter Web +
Firebase Storage, não um bug no código do app — `Image.network` já foi
trocado por `FotoPerfilRede` (`lib/components/AuthWidgets.dart`), que pelo
menos mostra um ícone de erro em vez de ficar em branco quando isso
acontece, mas a causa raiz (CORS do bucket) só se resolve configurando o
bucket.

**Correção (só o usuário consegue fazer, exige acesso ao bucket real)**:
aplicar o `cors.json` (criado na raiz do repo) no bucket via `gsutil`,
rodando pelo **Google Cloud Shell** (console.cloud.google.com → ícone de
terminal `>_` no topo, não precisa instalar nada):

```
gsutil cors set cors.json gs://ptk-plays.firebasestorage.app
```

(precisa subir o `cors.json` pro Cloud Shell antes — tem um botão de upload
de arquivo lá dentro, ou dá pra colar o conteúdo com um editor de texto tipo
`nano cors.json` direto no terminal). Depois de rodar, `gsutil cors get
gs://ptk-plays.firebasestorage.app` confirma que aplicou. Não precisa
refazer isso a cada deploy — é uma config do bucket, não do código.

## Suporte a múltiplos idiomas (internacionalização)

Hoje o app tem todas as strings em português hardcoded direto nas telas. Não é
uma exigência da Apple/App Store (apps mono-idioma são aprovados normalmente),
mas pode valer a pena no futuro para alcançar um público internacional.

Escopo estimado, quando for priorizado:
- Configurar `flutter_localizations` + arquivos `.arb` (pt-BR e en, no mínimo).
- Extrair todas as strings hardcoded das telas (`lib/view/*.dart`,
  `lib/components/*.dart`) para as chaves de tradução.
- Adicionar seletor de idioma (provavelmente na tela de Perfil, ao lado do
  toggle de tema).
- Testar cada tela nos dois idiomas (atenção a textos longos quebrando layout).

## Migrar configuração do Codemagic para `codemagic.yaml` versionado no repo

Hoje a configuração de build/trigger do Codemagic vive só na UI do painel
(não existe `codemagic.yaml` no repositório). Em 27/jul/2026 o usuário já
configurou na UI o gatilho por tag (`Trigger on tag creation`, com os
demais gatilhos desmarcados, e o padrão `Include: v*` em "Watched tag
patterns") — funcionando, mas não versionado.

Quando for priorizado, migrar isso para um `codemagic.yaml` no repo traria
rastreabilidade (histórico de mudança de config via git) e evita depender só
da UI. Escopo, quando for feito:
- Criar `codemagic.yaml` reproduzindo o workflow atual (build `--release`,
  dart-defines incluindo `YT_API_KEY_IOS`, assinatura iOS/Android, etc. —
  precisa levantar a config atual da UI antes, já que não temos acesso ao
  painel do Codemagic por aqui).
- Incluir a seção `triggering` com `events: [tag]` e
  `tag_patterns: [{pattern: 'v*', include: true}]`, espelhando o que já foi
  configurado manualmente na UI.
- No painel do Codemagic, trocar o app de "Workflow Editor" para
  "codemagic.yaml" (toggle único, feito pelo usuário).

## Login com Apple falhando em build de TestFlight/produção (investigação em aberto)

Em 30/jul/2026 o build iOS no Codemagic falhava na assinatura com o erro
"Provisioning profile ... doesn't include the Sign In with Apple capability /
com.apple.developer.applesignin entitlement", mesmo o app já declarando o
entitlement em `ios/Runner/Runner.entitlements`. Causa raiz: o provisioning
profile "PTK Plays oficial community app ios_app_store 1783565999" tinha sido
gerado no Apple Developer Portal antes da capability "Sign In with Apple" ser
habilitada/propagada pro App ID. **Resolvido pelo usuário** habilitando a
capability no App ID e regenerando o profile — build seguinte arquivou e
enviou pra App Store Connect com sucesso.

Com o build já em TestFlight, ao testar o botão "Entrar com a Apple" no
dispositivo, apareceu o popup genérico "Ops! Não foi possível entrar com a
Apple. Tente novamente." Essa mensagem vem de `mapearErroLoginApple` em
`lib/viewmodels/AuthViewModel.dart` (linha ~108): ela cai nesse texto genérico
sempre que a Apple retorna um `SignInWithAppleAuthorizationException` com
código diferente de "cancelado" (ou qualquer outra exceção não mapeada). O
erro real é logado via `debugPrint('loginComApple falhou: ...')`
(commit `a5138f2`), mas isso só aparece em sessão de debug conectada — não
aparece em build de TestFlight/produção sem o dispositivo conectado ao Mac
via Console.app/Xcode.

**Ainda não confirmado / próximos passos, quando o usuário retomar:**
- Conectar o iPhone de teste ao Mac e capturar o log real
  (Console.app ou Xcode → Devices and Simulators → View Device Logs,
  filtrando por "PTK Plays") reproduzindo o erro, pra saber o código exato
  do `AuthorizationErrorCode` retornado.
- Conferir se **Firebase Console → Authentication → Sign-in method → Apple**
  está habilitado (config separada da capability do Xcode/profile).
- Conferir se o dispositivo de teste está logado numa conta Apple/iCloud
  válida (com 2FA) — Sign In with Apple exige isso no aparelho.
- Confirmar que o app instalado via TestFlight é a build nova (pós-fix do
  profile), não uma cópia antiga já instalada antes do reenvio.
- Depende de infraestrutura externa (dispositivo físico, Apple Developer
  Portal, Firebase Console) não disponível neste ambiente — não dá pra
  cobrir com teste unitário; a validação final é manual pelo usuário.

### Reprodução em 17/ago/2026: emulador de iPhone via Sauce Labs

O usuário testou o botão "Entrar com a Apple" num emulador de iPhone
rodando através do Sauce Labs (nuvem de dispositivos/emuladores pra teste) e
recebeu o mesmo popup genérico "Ops! Não foi possível entrar com a Apple.
Tente novamente.".

**Causa mais provável (ambiental, não é bug de código)**: o
`SignInWithAppleAuthorizationException` com código `unknown`
(`ASAuthorizationError` 1000 no lado nativo da Apple) é o que o sistema
operacional retorna quando a autorização falha antes de chegar a um motivo
mais específico — na prática, isso acontece quase sempre porque o
dispositivo/emulador **não está logado numa conta Apple (iCloud) com
autenticação de dois fatores**, que é uma exigência do Sign In with Apple
no nível do sistema operacional, independente do app. Emuladores/nuvens de
teste como o Sauce Labs tipicamente não vêm com uma conta Apple configurada
por padrão — não é algo que o código do app consiga contornar.

**O que foi feito no código** (`mapearErroLoginApple` em
`lib/viewmodels/AuthViewModel.dart`): o código `unknown` agora retorna uma
mensagem mais específica pro usuário, explicando que o dispositivo precisa
estar conectado a uma conta Apple/iCloud com 2FA, em vez do texto genérico
de "tente novamente" — evita achar que é sempre um bug quando na maioria
das vezes é o ambiente de teste que não tem Apple ID configurado. Coberto
por teste em `test/auth_error_mapping_test.dart`
(`mapearErroLoginApple codigo "unknown" ...`).

**O que falta pro usuário confirmar**: testar com uma conta Apple/iCloud
real logada no emulador (se o Sauce Labs permitir configurar isso na
sessão) ou, preferencialmente, num dispositivo físico próprio já logado no
iCloud — se o erro sumir nesse cenário, confirma que a causa era mesmo a
ausência de conta Apple no ambiente de teste, não um bug no app.

## Integração futura com a API do WhatsApp Business (Meta)

Em 04/ago/2026 o usuário começou a configurar o app no painel da Meta for
Developers, com o caso de uso "Conectar-se com os clientes pelo WhatsApp"
(WhatsApp Business Platform / Cloud API) já adicionado — os demais casos de
uso sugeridos por padrão pelo painel (Marketing API, Gerenciador de Anúncios,
API do Threads) não são necessários pro objetivo atual e podem ser removidos
pra reduzir o escopo do App Review.

**Motivações identificadas até agora**, quando for priorizado:
- Autenticação/segurança: OTP no cadastro (template categoria
  `authentication`), 2FA opcional pra usuários, confirmação de exclusão de
  conta (`AuthRepository.excluirConta`), alerta de login em novo
  dispositivo.
- Engajamento: aviso de novo vídeo publicado no PTK, aviso de nova
  atividade/mensagem na comunidade (fallback pra quem não usa push
  notification do app), mensagem de boas-vindas automatizada no cadastro.
- Suporte: canal de FAQ/suporte pelo número do WhatsApp Business, opção de
  pedir exclusão de conta por lá.
- Administração: alertas pro próprio usuário-dono (novo cadastro, denúncia
  recebida, erro crítico) enquanto o app é pequeno o suficiente pra
  acompanhar manualmente.

**Peça de arquitetura que falta**: a API do WhatsApp é servidor-a-servidor
(Graph API), não é algo que o app Flutter chama direto — precisa de um
token permanente (System User, nunca embutido no client), um webhook HTTPS
público pra receber eventos da Meta, e templates de mensagem pré-aprovados
pra qualquer mensagem iniciada pelo app (categorias `authentication`,
`utility`, `marketing`). Hoje o projeto só tem Firebase (Auth + Firestore)
como backend, sem servidor próprio — o caminho natural é usar Cloud
Functions do Firebase como ponte entre o webhook da Meta e o Firestore/app.

Escopo estimado, quando for priorizado:
- Criar Cloud Function(s) pra receber o webhook da Meta e outra(s) pra
  chamar a Graph API e enviar mensagens.
- Cadastrar e verificar o número de telefone comercial no painel da Meta.
- Submeter os templates de mensagem necessários pra aprovação (OTP primeiro,
  já que é o caso de uso mais simples de aprovar).
- Completar a verificação de negócio (Business Verification) na Meta, que é
  exigida pra escalar além do volume inicial de teste.
- App Review das permissões `whatsapp_business_messaging` e
  `whatsapp_business_management`.

## Ação pendente do usuário: publicar as novas regras do Firestore

Em 05/ago/2026 `firestore.rules` foi alterado pra permitir que o cadastro já
crie a conta com a badge `novato` (o `create` agora aceita `badges == []` OU
`badges == ['novato']`, antes só aceitava lista vazia). **Editar esse arquivo
no repo
não atualiza as regras em produção** — precisa ser publicado manualmente
(Firebase Console → Firestore Database → Regras → colar o conteúdo do
`firestore.rules` atual → Publicar, ou `firebase deploy --only
firestore:rules` via CLI local). Enquanto isso não for feito, o cadastro de
conta nova vai falhar com erro de permissão, porque o app já está enviando
`badges: ['novato']` mas as regras em produção ainda exigem lista vazia.

## Sistema de conquistas (gamificação): tela criada, mas progresso não avança sozinho

Em 05/ago/2026 foi criada a tela `Conquistas` (acessível tocando numa badge
no Perfil), com um catálogo inicial de 4 conquistas em
`lib/data/models/Conquista.dart`: `novato` (automática no cadastro),
`comentarista` (10 comentários), `popular` (50 curtidas),
`presencaVip` (5 cliques em lives) — baseadas nos contadores que já existiam
em `UserModel.contadores` (`comentarios`, `curtidas`, `cliquesLive`), mas que
nunca eram usados em lugar nenhum do app antes disso.

**Dois gaps de arquitetura, do mesmo tipo do que já foi mapeado pra
WhatsApp**:
- **Nada incrementa `contadores` hoje.** Não existe feature de comentário ou
  curtida implementada ainda (o app tem posts/enquetes/avisos, mas sem
  comentar/curtir) nem contagem de cliques em live. Enquanto isso não
  existir, a tela de Conquistas sempre mostra 0% de progresso pra todo mundo
  — o que é o comportamento correto e esperado até lá, não um bug.
- **O cliente não pode conceder badges sozinho.** `firestore.rules` trava
  `badges`/`contadores` contra alteração pelo cliente depois da criação da
  conta (anti-trapaça: só a `novato` inicial é permitida no create). Então,
  mesmo quando os contadores existirem de verdade, conceder `comentarista`/
  `popular`/`presencaVip` automaticamente quando a meta for atingida só pode
  ser feito por um backend de confiança (Cloud Function com Admin SDK, que
  ignora as regras de segurança) — a mesma peça de infraestrutura que falta
  pra WhatsApp. Vale desenhar os dois juntos quando for priorizado.

## Avatares pré-definidos no cadastro (implementado em 14/ago/2026)

No cadastro, o usuário escolhe 1 de 6 fotos de perfil pré-definidas (seleção
única, obrigatória, estilo visual do PTK Plays), representando personas:
**Gamer, Streamer, Inscrito do canal PTK Plays, Blogueiro, Maratonista de
Séries/Filmes e Otaku**.

- `UserModel.avatarPreset` (`lib/data/models/UserModel.dart`): campo novo,
  **separado** de `fotoUrl` (que continua reservado pra foto real vinda do
  Google/Apple Sign-In) — os dois conceitos não se misturam.
- Catálogo em `lib/data/models/AvatarPreset.dart` (chave/label/asset), com as
  6 imagens em `assets/avatares/avatar_<chave>.png` (fatiadas da arte
  enviada pelo usuário).
- Seletor visual reutilizável em `lib/components/SeletorAvatarPreset.dart`
  (grid 3x2, destaque + check no selecionado).
- No `Cadastro.dart`: seleção obrigatória, numa `CardVidro` própria acima do
  formulário de conta (validada por `validarAvatarPreset`).
- No `EditarPerfil.dart`: seção separada ("Foto de perfil"), abaixo da seção
  de dados da conta (nickname/WhatsApp), como combinado — mantém a
  organização visual entre os tipos de dado. Aqui a escolha não é
  obrigatória (conta antiga sem preset continua válida).
- Exibido no `Profile.dart` (`_CabecalhoPerfil`), com fallback pra `fotoUrl`
  e depois pro ícone genérico, na mesma ordem de prioridade.
- Não exige mudança no `firestore.rules`: é um campo cosmético comum,
  coberto pela regra genérica de update do dono (`allow update: if
  ehDono(userId) && ...`), sem trava anti-cheat como `badges`/`contadores`.

## Menu lateral (endDrawer) pós-login (21/ago/2026)

Botão de menu (3 linhas horizontais, `lib/components/MenuLateral.dart` →
`BotaoMenuLateral`) no canto superior direito, ao lado do botão de tema,
visível **só** em Home/Videos/Profile (as 3 telas que usam `buildHeader`,
`lib/components/Header.dart`, agora com parâmetro opcional `menu`). Login,
Cadastro e qualquer futura tela de recuperação de senha continuam usando o
`BotaoTema` avulso, sem esse parâmetro — nunca mostram o menu.

- Implementado com o mecanismo nativo do Flutter (`Scaffold.endDrawer` +
  `Scaffold.of(context).openEndDrawer()`), não um overlay customizado — já
  vem com animação de slide da direita, scrim de fundo e dismissal ao tocar
  fora, de graça.
- `MenuLateral` (o painel) tem largura `62%` da tela ("um pouco mais da
  metade", como pedido) e 3 opções: **Recuperação de senha**,
  **Privacidade**, **Configurações** — cada uma recebe um `VoidCallback`
  próprio da tela que a usa, em vez do widget navegar sozinho (evita a
  dependência de UserModel/AuthViewModel dentro do componente compartilhado).
- **Recuperação de senha**: em Home/Videos navega pra `Profile` (não tem o
  `UserModel` carregado ali pra ir direto em `EditarPerfil`); em Profile
  navega direto pra `EditarPerfil` reaproveitando o mesmo `_usuarioAtual` e
  callback que o ícone de editar já usa.
- **Privacidade** (`lib/view/Privacidade.dart`) e **Configurações**
  (`lib/view/Configuracoes.dart`) são telas novas, só com placeholder
  visual ("em breve") — ainda não têm conteúdo real definido (texto da
  política de privacidade, opções de configuração). Preencher quando
  priorizado.

## Ajustes visuais do menu lateral + Política de Privacidade dentro do app (21/ago/2026)

- **Fundo do menu lateral opaco**: o `Drawer` reaproveitava `cardBgDark`/
  `cardBgLight` (translúcidos de propósito, pensados pro `CardVidro` que
  tem seu próprio `BackdropFilter` de blur) — sem esse blur, o menu ficava
  com aparência "transparente". Criados `AuthTheme.menuBgLight` (branco
  100% opaco) e `AuthTheme.menuBgGradientDark` (gradiente branco→roxo,
  opaco, com o roxo só aparecendo perto do rodapé pra manter os itens do
  menu legíveis). Texto/ícones do menu usam uma cor fixa (`titleLight`)
  em vez de alternar com o tema, já que o fundo agora é sempre
  predominantemente branco nos dois modos.
  - Bug pego nesse processo: envolver os `ListTile` num `Container` com
    `decoration` quebra o ripple/ink deles (`Material` mais próximo fica
    "tapado"). Corrigido envolvendo o conteúdo num `Material(type:
    MaterialType.transparency)` entre o `Container` decorado e os itens.
- **Ícones dos botões circulares no modo escuro**: `AuthTheme.themeIconDark`
  era amarelo (`0xFFFFD24A`), baixo contraste contra o fundo branco opaco
  desses botões — trocado pra preto (`Colors.black`). Afeta `BotaoTema`,
  `BotaoVoltar`, `BotaoMenuLateral` e os botões inline de `Header.dart`
  (fonte única de verdade, `AuthTheme.themeIconDark`).
- **Política de Privacidade renderizada dentro do app**: antes abria o
  navegador externo (`abrirLinkExterno`/`LinkExterno.dart`, removidos);
  agora `lib/view/PoliticaPrivacidadeWeb.dart` usa `flutter_inappwebview`
  (já era dependência do projeto, sem uso até então) pra mostrar a página
  dentro do próprio app, com `BotaoVoltar`/`BotaoTema` flutuantes por cima
  (mesmo padrão visual das outras telas) pro usuário sempre poder sair.
  - **Tradução automática por localização**: `lib/utils/PoliticaPrivacidade.dart`
    decide a URL a carregar com base no *locale* do dispositivo/navegador
    (`WidgetsBinding.instance.platformDispatcher.locale`) — **não é GPS
    nem IP**, o app não pede permissão de localização pra isso. Locale com
    região Brasil (`countryCode == 'BR'`) carrega a página através do
    proxy `translate.goog` do Google Tradutor (`en→pt`); qualquer outra
    região (mesmo países de língua portuguesa como Portugal) carrega a
    URL original, em inglês — testado explicitamente com esse caso em
    `test/politica_privacidade_test.dart`.
    - **Risco conhecido**: o truque do `translate.goog` é um mecanismo não
      oficial (embora amplamente usado) do Google Tradutor pra traduzir
      qualquer página via proxy — pode parar de funcionar se o Google
      mudar esse comportamento. Não depende de nenhuma chave de API.
  - **Não validado de ponta a ponta neste ambiente de desenvolvimento**: a
    renderização real da `InAppWebView` (carregar a página de verdade, seja
    a original ou via `translate.goog`) depende de bindings de
    plataforma/rede que não existem no `flutter test` nem foram
    verificados via browser neste sandbox — só a lógica pura de
    montagem da URL (`urlPoliticaPrivacidadeParaLocale`) foi testada.
    `flutter build web` roda sem erros, então a integração compila
    certinho; falta o usuário confirmar visualmente que a página carrega
    e traduz como esperado.

### Correção (21/ago/2026): `translate.goog` recusa ser embutido em iframe na Web

Usuário testou no app publicado (Web) e a página apareceu como "conexão
recusada" — confirmado: no Flutter Web, `flutter_inappwebview` renderiza
via `<iframe>`, e o proxy `translate.goog` do Google (e possivelmente o
próprio Blogger) recusa ser carregado dentro de um iframe de outro site,
por segurança do lado de quem hospeda a página — isso não é algo que dê
pra contornar do nosso lado (é o mesmo tipo de proteção X-Frame-Options/
CSP `frame-ancestors` usada contra clickjacking). Em app nativo
(Android/iOS) isso não seria problema, porque lá `flutter_inappwebview`
usa uma WebView nativa de verdade, não um iframe, e essa restrição não se
aplica a navegação direta (só a embutir dentro de outra página).

**Correção**: `lib/utils/PoliticaPrivacidade.dart` ganhou
`abrirPoliticaPrivacidade(context)`, que decide o comportamento por
plataforma (`kIsWeb`):
- **Fora da Web** (Android/iOS/desktop): continua abrindo
  `PoliticaPrivacidadeWeb` dentro do app, como antes.
- **Na Web**: abre a URL numa aba nova do navegador via `url_launcher`
  (navegação direta, sem iframe — não esbarra na mesma restrição, já que
  X-Frame-Options só bloqueia ser *embutido*, não uma navegação de topo
  normal).

As 3 telas (Home/Videos/Profile) agora só chamam
`abrirPoliticaPrivacidade(context)` em vez de navegar direto pra
`PoliticaPrivacidadeWeb`.

## Backend (Cloud Functions) — escrita de `transmissoes` no Firestore do PTK AI Studio

### Contexto: código de detecção de live estava numa branch nunca mergeada

Ao executar esse pedido, descobrimos que as Functions de detecção de live
(`verificarYoutubeAoVivo`, `twitchWebhook`, `kickWebhook`, `kickAuthStart`,
`kickOAuthCallback`, `notificarAoVivo`) — já **implantadas em produção**
desde 15/jul/2026 (ver `CHECKPOINT.md`) — só existiam no repositório numa
branch antiga `feat/notificacoes-ao-vivo`, **nunca mergeada** e que
divergiu do `main` antes de todo o trabalho recente (webhook do WhatsApp,
menu lateral, política de privacidade). Isso resolve o ponto em aberto do
`CHECKPOINT.md` ("esse backend já existia de um trabalho anterior?"): sim,
é exatamente esse código, só que fora de sincronia com o git.

**O que foi feito**: trouxemos `functions/lib/{youtube,twitch,kick,
postAoVivo}.js` e `functions/scripts/setup-twitch-eventsub.js` dessa
branch pra dentro da branch de desenvolvimento atual, e mesclamos:
- `functions/index.js`: um único `initializeApp()`, exports do webhook do
  WhatsApp **inalterados** (continuam sem região explícita, ou seja
  `us-central1` — não usamos `setGlobalOptions` global pra região porque
  isso teria mudado também a região do `whatsappWebhook` já cadastrado no
  Meta for Developers, quebrando a URL do webhook). `notificarAoVivo`
  ganhou `region: "southamerica-east1"` explícita no lugar disso.
- `functions/package.json`: mantidas as dependências/scripts do webhook
  (`firebase-admin ^12.7.0`, `firebase-functions ^6.1.0`, jest), com
  `@google-cloud/firestore ^7.11.0` adicionado (compatível com a versão
  que o próprio `firebase-admin` já usa internamente — `npm install`
  fez o hoist certinho, sem duplicar).

### O pedido em si: `functions/lib/transmissoes.js`

Novo módulo que escreve em `transmissoes` no Firestore do projeto
**separado** `ptk-ai-studio`, via Application Default Credentials
(`new Firestore({ projectId: 'ptk-ai-studio' })` do pacote
`@google-cloud/firestore` — **sem** criar/baixar chave de service account,
como pedido; o IAM `roles/datastore.user` já foi concedido no console
pelo usuário). Não altera nada do que as Functions já escrevem em
`ptk-plays` (a lógica de `posts`/notificação em `postAoVivo.js` continua
igual — a escrita em `transmissoes` é só uma chamada adicional).

- **ID determinístico** `${plataforma}_${idDaTransmissao}`, sempre com
  `{ merge: true }`.
- **Como sabemos qual documento fechar no fim**: nem todo evento de "fim"
  traz o id da transmissão (o `stream.offline` da Twitch só traz dados do
  broadcaster, sem id da stream) — então `registrarInicioTransmissao`
  também guarda um estado ativo em `_privado/transmissoesAtivas/
  porPlataforma/{plataforma}` no Firestore do próprio `ptk-plays`,
  lido e apagado por `registrarFimTransmissao` (que também calcula o
  `duracaoSegundos` a partir daí).
- **`registrarFimTransmissao` só é chamado quando a checagem realmente
  detectou a transição ao_vivo → offline** (usa o retorno de
  `atualizarStatusPlataforma`, que diferencia `"encerrada"` de
  `"semMudanca"`) — evita logs de aviso toda vez que a checagem agendada
  do YouTube roda e o canal já estava offline (a maior parte do fim de
  semana).

**`vodId`/`vodUrl` por plataforma**:
- **YouTube**: de graça — o próprio `videoId` da live (que a checagem
  agendada já usa pro link) continua sendo o id do vídeo depois que a
  live vira gravação.
- **Twitch**: `stream.online` traz `event.id` (id da transmissão) pro
  início. No fim, como o `stream.offline` não traz VOD nenhum, adicionamos
  uma chamada à Helix `GET /videos?user_id=...&type=archive&first=1`
  (usando um token de app via `client_credentials`, com os secrets
  `TWITCH_CLIENT_ID`/`TWITCH_CLIENT_SECRET` — os mesmos já usados pelo
  script `setup-twitch-eventsub.js`, agora também declarados como secrets
  da própria function `twitchWebhook`) pra pegar o VOD mais recente do
  canal — assumindo que é o que acabou de terminar.
- **Kick**: **sem VOD** — o webhook `livestream.status.updated` não expõe
  isso, então `vodId`/`vodUrl` ficam ausentes, como pedido explicitamente
  ("se não der pra obter, deixe o campo ausente — não invente e não
  chute").

**⚠️ Ponto não verificado contra produção real — revisar quando a Kick
disparar o webhook de verdade**: não temos documentação/payload de exemplo
confiável do evento `livestream.status.updated` da Kick além do campo
`is_live` (já usado antes desta mudança). Como a Kick não expõe um "id de
transmissão" dedicado nesse payload, `extrairIdDaTransmissaoKick`
(`functions/lib/kick.js`) tenta, nessa ordem, `body.livestream.id`,
`body.id` e por fim deriva um id a partir de `body.started_at` (dado real
do payload, não inventado, só não é um id oficial da plataforma); se nada
disso vier, **não grava nada** e só loga um aviso — em vez de chutar um
campo que pode nem existir. Recomendo conferir isso nos logs
(`firebase functions:log`) na próxima vez que uma live da Kick abrir/
fechar, e ajustar `extrairIdDaTransmissaoKick` se o payload real trouxer
outro formato.

**Testado** (`functions/test/`, `npm test`, 15 testes Jest):
- `transmissoes.test.js`: `idDocumentoTransmissao` (formato do id) e
  `calcularDuracaoSegundos` (diferença em segundos, nunca negativa).
- `kick_transmissao_id.test.js`: `extrairIdDaTransmissaoKick` — todos os
  ramos (id via `livestream.id`, via `body.id`, derivado de `started_at`,
  e o caso "não inventa nada" quando não há nenhum campo usável).

**Não testado de ponta a ponta neste ambiente** (sem gcloud/firebase
autenticados, sem emulador do Firestore rodando, sem as credenciais reais
da Twitch/Kick/YouTube): as escritas de verdade em
`registrarInicioTransmissao`/`registrarFimTransmissao` (dependem de ADC
real pro projeto `ptk-ai-studio` e de um app do `firebase-admin`
inicializado), a chamada Helix de VOD da Twitch, e o payload real da Kick
mencionado acima. `npm test` cobre só a lógica pura. Falta o usuário
fazer o deploy (`firebase deploy --only functions`, como sempre, a partir
do Cloud Shell) e confirmar numa live de teste em cada plataforma que os
documentos aparecem certinho em `transmissoes` no projeto `ptk-ai-studio`.

### Campo `titulo` + backfill de lives passadas (27/ago/2026)

Pesquisado na documentação **oficial** antes de codar (não chutado):

- **`docs.kick.com/events/event-types`**: confirma que o payload do
  `livestream.status.updated` traz `broadcaster`, `is_live`, `title`,
  `started_at` e `ended_at` — **sem** nenhum id de transmissão dedicado.
  Isso valida a decisão anterior de derivar o id do `started_at`
  (`extrairIdDaTransmissaoKick`, `functions/lib/kick.js`) e resolve a
  incerteza que tinha ficado documentada antes — não é mais "não
  verificado", é confirmado que o campo não existe mesmo. `title` passou a
  ser gravado (`titulo`) direto desse payload.
- Também confirmado: a Kick **não tem nenhum endpoint público documentado**
  pra listar vídeos/VODs passados do canal (só o webhook em tempo real) —
  por isso o backfill histórico (abaixo) cobre só YouTube e Twitch.
- **`dev.twitch.tv/docs/eventsub/eventsub-reference`**: confirma que o
  evento `stream.online` **não traz título** (isso só vem no
  `channel.update`, que não assinamos). `functions/lib/twitch.js` ganhou
  `buscarTituloAoVivo`, que consulta a Helix `GET /streams?user_id=...`
  no momento do `stream.online` pra obter o título da live em andamento.
- **YouTube**: `titulo` sai de graça do próprio `search.list` que a
  checagem agendada já faz (`item.snippet.title`).

### Backfill de lives passadas (`functions/scripts/backfill-transmissoes-passadas.js`)

Script novo, roda uma vez manualmente (mesmo padrão do
`setup-twitch-eventsub.js`), grava retroativamente em `transmissoes` no
`ptk-ai-studio` as lives que já aconteceram antes dessa feature existir:

- **YouTube**: em vez de `search.list` (100 unidades de cota por chamada),
  usa a playlist de uploads do canal (`channels.list` + `playlistItems.list`,
  1 unidade/página) e depois `videos.list` em lotes de 50 ids (1
  unidade/lote) filtrando por quem tem `liveStreamingDetails` com
  `actualStartTime`/`actualEndTime` preenchidos — bem mais barato que
  paginar `search.list` pra achar lives antigas.
- **Twitch**: pagina `Get Videos` (`type=archive`) via Helix. **Correção
  (27/ago/2026)**: a primeira versão deste script usava `vod.stream_id`
  como `idDaTransmissao`, na suposição de que seria o mesmo id que
  `event.id` do `stream.online` (deteção em tempo real) — **suposição não
  confiável o suficiente pra apostar em fusão de documentos**: o `Get
  Videos` só devolve o id do VOD, um espaço de id diferente do id de
  stream, sem garantia documentada de equivalência entre os dois. Usar
  `vod.stream_id` (quando presente) como se fosse o id de stream e confiar
  no `merge: true` pra fundir com um doc futuro da detecção em tempo real
  seria uma aposta que, se errada, gera duplicata **silenciosa** (sem
  erro, só dois documentos distintos pra mesma live). Corrigido pra usar
  `vod.id` (id do próprio VOD) — aceitando explicitamente que documentos
  do backfill ficam "congelados": não tentam fundir com nada que a
  detecção em tempo real grave depois. Isso é seguro porque são eventos
  **passados** — o pior caso é, numa coincidência (mesma live pega tanto
  pelo backfill quanto por uma futura reexecução do backfill ou pela
  detecção ao vivo antes dele rodar), existirem dois documentos pra ela em
  vez de um, o que não quebra nada no lado do consumidor (PTK AI Studio).
  A duração vem no formato `"6h26m14s"` —
  `functions/lib/twitchDuracao.js` (`parseDuracaoTwitch`, testado em
  `twitch_duracao.test.js`) converte pra segundos.
- **Kick**: de fora, pelo motivo explicado acima (sem API oficial).
- Mesmo formato de documento e mesmo id determinístico
  (`${plataforma}_${idDaTransmissao}`, `merge: true`) do fluxo em tempo
  real — seguro rodar mais de uma vez, e seguro rodar depois que a
  detecção em tempo real já estiver ativa (não duplica).

**Credenciais**: como esse script roda fora do runtime das Cloud
Functions, ele não herda a identidade da conta de serviço automaticamente.
Como o usuário é dono (Owner) do projeto `ptk-ai-studio`, basta
`gcloud auth application-default login` com a própria conta Google — sem
precisar de chave de service account nem de conceder role adicional
nenhuma. Documentado no cabeçalho do próprio script. **Não testado de
ponta a ponta neste sandbox** pelo mesmo motivo de sempre (sem
gcloud/firebase autenticados aqui) — só a lógica pura de parsing de
duração tem teste automatizado.

---

# Painel ADM e enriquecimento dos cards (28/ago/2026)

## Já entregue (Etapa 1)

- **Cards de Vídeos com paridade ao Feed**: data de publicação + badge
  clicável do YouTube (`lib/components/VideoCard.dart`).
- **Preview nos cards de live do Feed**: Twitch e Kick já mandavam
  `thumbnailUrl`; o YouTube não manda nenhuma, mas a miniatura é deduzida
  do id do vídeo que já está no próprio link
  (`PostPlataformaAoVivo.previewUrl`), sem chamada extra de API.
- **Badge "Administrador"** no catálogo de conquistas — aparece no perfil
  de quem tem `cargo == 'admin'`.
- **"Painel ADM" no menu lateral**, visível só pra `cargo == 'admin'`.
- **Tela `PainelAdmin`** com as 5 seções previstas. Só **Usuários** está
  funcional: lista todos os usuários, com menu de 3 pontos → ver perfil,
  suspender (7 dias), banir e reativar. As demais seções aparecem
  explicando o que falta pra cada uma, em vez de sumirem da navegação.
- **`firestore.rules`**: regra nova permitindo que o admin altere
  `estadoModeracao`/`suspensoAte`/`motivoModeracao` de outras contas — e
  **só** esses campos (nunca cargo, badges ou contadores por essa via).

## Pendências, do mais fácil ao mais difícil

### Etapa 2 — barrar quem foi banido/suspenso — feita em 01/set/2026
Ver a seção "Bloqueio de conta banida/suspensa" mais abaixo.

### Etapa 3 — mensagem privada do admin (médio)
Coleção `conversas` + regras (só os dois participantes leem/escrevem) +
tela de chat. Hoje a opção existe no menu de 3 pontos e avisa que ainda não
está pronta.

### Etapa 4 — preview com autoplay na aba Vídeos (médio/difícil)
Reproduzir o vídeo automaticamente no card conforme ele entra na tela.
Precisa de um detector de visibilidade (`visibility_detector`) + o
`youtube_player_flutter` (já é dependência) por card, com só **um** player
ativo por vez pra não derrubar a performance. Complicações reais:
- Na Web, autoplay com som é bloqueado pelo navegador — tem que começar
  mudo, como Instagram/TikTok fazem.
- Vários players simultâneos travam o app em celular mais fraco; a
  reciclagem do `ListView` precisa liberar o player ao sair da tela.

### Etapa 5 — Badges pelo painel (médio/difícil)
Conceder badge a um usuário escolhido na lista. `badges` é **travado**
contra escrita do cliente no `firestore.rules` (de propósito — é
gamificação, não pode ser auto-concedida). Precisa de uma Cloud Function
com o Admin SDK, chamada pelo painel.

### Etapa 6 — Notificações por cargo (médio/difícil)
Enviar push com título e descrição pra todos ou pra um cargo específico.
Já existe FCM no projeto (`functions/lib/postAoVivo.js` dispara pro tópico
`ao_vivo`). Falta: uma Function que receba o envio do painel, e inscrever
cada usuário num tópico por cargo no login (`cargo_admin`, `cargo_vip`,
`cargo_inscrito`) pra poder segmentar.

### Etapa 7 — Cargos customizados com permissões (difícil)
Criar cargos além de inscrito/vip/admin e definir o que cada um pode. É o
mais invasivo: o `firestore.rules` hoje compara `cargo == 'admin'` numa
string fixa; passaria a ler uma coleção `cargos` com o mapa de permissões,
o que reescreve boa parte das regras e precisa de teste com o emulador.

### Etapa 8 — Aviso no WhatsApp (bloqueado por terceiros)
Mesmo formato das notificações, mas pelo número do bot do canal.
**Bloqueado** até a compra do número virtual e a verificação na Meta. O
webhook do WhatsApp Business já existe (`functions/src/webhook.js`), então
o trabalho restante é o disparo de mensagem (template aprovado pela Meta) e
a tela do painel.

## Ideias que podem valer a pena (não pedidas ainda)

- **Log de moderação**: registrar quem baniu/suspendeu quem e quando. Sem
  isso não há como auditar nem desfazer com contexto — barato de fazer
  junto da Etapa 2.
- **Busca e filtro na lista de usuários**: hoje ela carrega todo mundo de
  uma vez, sem paginação. Funciona com dezenas de contas; com centenas,
  vira problema de custo de leitura e de usabilidade.
- **Confirmação antes de banir**: hoje o clique bane direto. Um diálogo de
  confirmação com campo de motivo evita acidente e já alimenta o log acima.
- ~~**Aba "Posts" no painel**~~ — **entregue** em 30/ago/2026, junto com a
  publicação pelos inscritos (ver seção abaixo).

## Verificação pendente do usuário: cargo da conta admin

**Não consegui checar** se `marcospatrick039474@gmail.com` já está com
`cargo: 'admin'` no Firestore: este ambiente não tem credencial nenhuma do
Firebase (é o mesmo motivo pelo qual os deploys de Function são feitos por
você no Cloud Shell). Como conferir e corrigir:

1. Firebase Console → Firestore → coleção `users`.
2. Achar o documento cujo campo `email` é `marcospatrick039474@gmail.com`.
3. Conferir o campo `cargo`. Se estiver `inscrito` (o padrão de toda conta
   nova — ver `UserModel.novoInscrito`), editar pra `admin` e salvar.
4. Opcional: adicionar `'admin'` ao array `badges` do mesmo documento, pra
   a badge de Administrador aparecer no perfil.

Isso é feito pelo Console de propósito: o `firestore.rules` trava `cargo`
contra escrita do cliente justamente pra ninguém se auto-promover.


# Publicar no feed pelo app (30/ago/2026)

## Entregue

- **Aba "Posts" no Painel ADM**: lista o feed inteiro (inclusive os avisos
  de live), com botão de "Nova publicação" e exclusão com confirmação.
- **Botão de publicar no próprio Feed**, pra qualquer usuário logado — o
  inscrito publica **aviso de texto**; o admin também publica **enquete**.
- **Preferência do admin**: post de admin vai pro topo do feed
  (`prioridade` 100 contra 0 dos demais cargos), e dentro da mesma
  prioridade vale o mais recente (`PostModel.ordenarParaFeed`). Avisos de
  live e posts antigos criados no Console continuam no topo mesmo sem o
  campo gravado — a prioridade é deduzida na leitura, não precisou migrar
  nada no Firestore.
- **Selo ADMIN no card** e menu de 3 pontos pra excluir o próprio post
  (admin exclui o de qualquer um).
- **`firestore.rules`**: o create em `/posts` agora exige que `autorUid`
  seja o próprio usuário, que `autorCargo` bata com o cargo real gravado no
  perfil dele e que `prioridade` seja a do cargo — não adianta o cliente
  mandar `admin`/`100` na mão. Enquete continua restrita a admin; `aoVivo`
  não é aceito de cliente nenhum (só das Cloud Functions, que usam o Admin
  SDK e ignoram as regras). Delete: autor ou admin.

**Precisa de deploy**: `firebase deploy --only firestore:rules`. Enquanto a
regra antiga estiver no ar, só o admin consegue publicar — o inscrito leva
`permission-denied`.

## Pendências dessa parte

- **Foto no post (`avisoFoto`) pelo app**: o tipo já existe e o card já
  renderiza, mas publicar com foto precisa de um caminho novo no
  `storage.rules` (hoje só `fotos_perfil/{uid}/`) e de reaproveitar o
  `ModalCropFoto`. As regras do Firestore já aceitam `avisoFoto` vindo do
  admin.
- **Envelhecimento da preferência do admin**: a ordenação é literal — todo
  post de admin fica acima de todo post de inscrito, pra sempre. Com o
  tempo, avisos velhos do canal vão empurrar as postagens novas da galera
  pra baixo. Se isso incomodar, a saída é dar validade ao destaque (ex:
  admin no topo só nas primeiras 48h, depois entra na ordem normal) ou um
  campo `fixado` explícito, marcado post a post.
- **Moderação do que os inscritos publicam**: hoje não há filtro de
  palavrão, denúncia nem limite de quantos posts por dia. Vale revisitar
  junto com a Etapa 2 (barrar quem foi banido) — hoje um usuário banido
  ainda consegue publicar, porque nada no app usa `estadoModeracao` ainda.


# Preview das lives e miniaturas dos vídeos (31/ago/2026)

**Sintoma relatado**: o preview não aparece nos cards — nem durante a live,
nem depois. Na aba Vídeos, o card mostrava um quadrado cinza com ícone de
imagem (que era o `errorBuilder` do `Image.network` disparando).

**O que foi verificado**: a URL que a API do YouTube devolve
(`i.ytimg.com/vi/<id>/hqdefault.jpg`) responde 200 e manda
`access-control-allow-origin: *`. Ou seja, **não é URL errada nem CORS** —
o endereço está correto e a imagem existe. Não deu pra reproduzir o
navegador do usuário deste ambiente (a rede do sandbox bloqueia hosts
externos), então o usuário testou abrindo
`https://i.ytimg.com/vi/FqWsenFQARE/hqdefault.jpg` direto numa aba do mesmo
navegador: **carregou normalmente**. Isso descartou bloqueio de
extensão/DNS/provedor e isolou a causa no carregamento de imagem do Flutter
na Web.

**Causa raiz**: na Web o Flutter baixa os bytes da imagem por XHR e
decodifica (`_network_image_web.dart`), caminho que depende de CORS e que
falha pra `i.ytimg.com` — mesmo o endereço abrindo numa aba, onde o
navegador usa um `<img>` comum, que não passa por CORS.

**Correção**: `webHtmlElementStrategy: WebHtmlElementStrategy.fallback` no
`ImagemRede`. Quando o download de bytes falha, o Flutter monta um `<img>`
de verdade — exatamente o que a aba do navegador faz. Só age na Web e só
depois da falha, então não muda nada no Android/iOS nem nas imagens que já
carregavam.

**O resto do que foi feito** (`lib/components/ImagemRede.dart`): toda
imagem de rede do app passou a ter spinner enquanto carrega, uma **segunda
URL** tentada quando a primeira falha (`img.youtube.com` serve a mesma
miniatura por outro domínio) e um placeholder explícito quando tudo falha.

**Preview de live sem depender de deploy**: `previewUrl` passou a deduzir
também a prévia da **Twitch** a partir do login do canal no link
(`static-cdn.jtvnw.net/previews-ttv/live_user_<login>-440x248.jpg`),
enquanto a transmissão está no ar. Antes disso, um aviso de live da Twitch
só tinha imagem se as Cloud Functions já tivessem gravado `thumbnailUrl` —
e **elas ainda não foram publicadas**, o que sozinho já explicava a
ausência de preview nos cards de live.

**Continua pendente**: `firebase deploy --only functions:twitchWebhook,functions:kickWebhook,functions:verificarYoutubeAoVivo`.
Sem isso, a Kick continua sem prévia (não tem endereço previsível como a
Twitch) e nenhuma plataforma grava jogo/título/duração nos posts novos.

# Feed enxuto e mídia no post do admin (01/set/2026)

Quatro coisas num pacote só, todas pedidas depois de olhar o feed em
produção.

## 1. Nível desejado da API do Android: já estava atualizado

O aviso do Play Console ("Atualize o nível desejado da API até 31 de agosto
de 2026") **não corresponde ao estado do código**: `compileSdk` e
`targetSdk` estão fixos em **36** (Android 16) em
`android/app/build.gradle.kts` desde o commit `7ca9679` (27/jul/2026), e as
tags `v1.2.1+13`, `1.2.1+14` e `v1.2.1+16` já contêm essa mudança.

O que o Play Console olha é o **artefato publicado**, não o repositório —
o aviso some quando um build gerado a partir dessa versão do código for
enviado e promovido. Se ele persistir depois disso, é porque a faixa que
está em produção/teste ainda serve um AAB antigo.

## 2. Avisos de live no formato antigo saem do feed

Os cards de "ENCERRADA / Corre pra assistir agora!" sem miniatura e sem
badge de plataforma são posts que a **versão antiga** da Cloud Function
esvaziava ao encerrar a transmissão: ela apagava `linksPorPlataforma` em vez
de marcar `aoVivo: false`. Não dá pra recuperar o que foi apagado.

- `PostModel.formatoAntigo` identifica esses posts (tipo `aoVivo` com
  `plataformasAoVivo` vazio) e `semFormatoAntigo` os tira do feed.
- Uma ação **"Limpar avisos de live antigos"** na aba Posts do Painel ADM
  apaga esses posts de vez, em lote, com confirmação.

## 3. Post com mais de 30 dias só aparece rolando

O feed abre com **10 posts** e nenhum com mais de 30 dias. Descendo além
dessa primeira página (ou tocando em "Ver publicações mais antigas"), o
limite cresce de 10 em 10 e o histórico entra, sempre depois dos recentes —
`PostModel.paginarParaFeed`. A consulta do Firestore subiu de 30 pra 60
posts pra ter o que revelar.

Detalhe que o teste cobre: post antigo **não** entra pra completar a
primeira página mesmo quando sobra espaço nela (feed com 3 posts recentes
mostra 3, não 3 + 7 antigos).

## 4. Foto e vídeo no post — só do admin

- Novo tipo `avisoMidia`, com `fotoUrl` e `videoUrl` **no mesmo post**
  (`avisoFoto` vira formato legado, ainda lido).
- `NovoPost` ganhou os botões "Foto" e "Vídeo" (galeria via `image_picker`),
  com prévia e botão de tirar o anexo. Só aparecem pro admin.
- Upload em `posts_midia/{uid}/` no Storage, feito só no "Publicar" — quem
  desiste no meio não deixa arquivo órfão.
- Dependência nova: **`video_player`**, pro vídeo tocar dentro do card.
  Começa parado com o botão de play (nada de autoplay num feed).

**Por que inscrito não posta imagem**: está escrito em
`REGRAS_DA_COMUNIDADE.md` (documento novo, com as regras de convivência —
inclusive a de não xingar). Resumo: mídia é o que dá pra publicar de pior
sem ninguém revisar antes, e o app não tem fila de moderação nem detecção
automática. Quem barra de verdade é o `firestore.rules`: o tipo
`avisoMidia` é recusado pra quem não é admin, e um `avisoTexto` que venha
com `fotoUrl`/`videoUrl` também.

**Limitação conhecida do `storage.rules`**: regra de Storage não lê o
Firestore, então lá só dá pra amarrar a escrita ao dono da pasta — um
inscrito consegue subir um arquivo pra `posts_midia/<uid-dele>/`, mas não
consegue publicá-lo em post nenhum, então ele não aparece pra ninguém.
Fechar isso de vez pede um *custom claim* de admin no Auth (Cloud
Function), que fica anotado como pendência.

## 5. Card de imagem no formato do Instagram

`ImagemAdaptativa` mede a foto e ajusta a proporção do card a ela, entre
**9:16** (retrato de celular) e **1.91:1** (paisagem larga). O limite de
baixo é 9:16 em vez do 4:5 do Instagram de propósito: o pedido era o card
acompanhar a foto vertical, então uma 9:16 aparece inteira em vez de ser
cortada. A medição roda num `ImageStream` à parte — se falhar, a imagem
ainda aparece (o `ImagemRede` tem os próprios fallbacks), só que quadrada.

## Pendências que este pacote deixou

- **Publicar `firestore.rules` e `storage.rules`** — sem isso o admin não
  consegue publicar mídia (`permission-denied`) e o upload é recusado.
- *Custom claim* de admin, pra fechar a escrita no Storage.
- Denúncia dentro do app e moderação de mídia (ver
  `REGRAS_DA_COMUNIDADE.md`, seção 7).


# Bloqueio de conta banida/suspensa (01/set/2026)

Motivo de existir: até aqui, o Painel ADM só **marcava** `estadoModeracao`
no documento do usuário — nada no app consumia essa marcação. Banir alguém
não impedia nada; era decorativo. Descoberto ao investigar um relato do
usuário sobre um jeito diferente de burlar o banimento.

## O que uma conta banida/suspensa não consegue mais fazer

- **Usar o app**: `Home._construirTela` checa `usuario.estaBloqueado()`
  antes de montar o Feed e, se verdadeiro, mostra `ContaBloqueadaView` no
  lugar — banido vê "Sua conta foi banida"; suspenso vê até quando
  (`suspensoAte`), e o motivo quando o admin informou um. Só resta o botão
  "Sair". `UserModel.estaBloqueado()` trata uma suspensão vencida como
  liberada mesmo que o admin não tenha clicado em "Reativar conta" ainda.
- **Se desbanir sozinha**: a regra de update do próprio usuário em
  `firestore.rules` não travava `estadoModeracao`/`suspensoAte`/
  `motivoModeracao` contra mudança pelo dono — qualquer escrita comum de
  perfil (trocar nickname, por exemplo) podia incluir esses campos junto e
  a regra deixava passar, porque nada ali os mencionava. Nada de injeção
  envolvida: é só que a regra não continha a checagem. Uma conta com um
  token válido de autenticação fala direto com o Firestore usando o SDK —
  não existe camada de validação "por trás" do banco além das próprias
  regras, e o que a UI do app oferece ou esconde não é o que decide
  segurança. Agora os três campos ficam presos ao valor que já tinham,
  contra escrita do próprio dono. Só a regra separada do admin (que já
  existia) altera esses campos.
- **Publicar ou votar contornando o app**: mesmo que alguém tecnicamente
  capaz escrevesse direto no Firestore pulando a UI (inclusive porque a UI
  em si nem carrega mais pra uma conta bloqueada), a função nova
  `contaBloqueada()` também barra a criação de post e o voto em enquete
  pra quem está banido ou suspenso dentro do prazo.

## O que fica de fora (limitação conhecida)

Bloquear pelo Firestore não desativa a conta no **Firebase Auth** — a
pessoa continua logada tecnicamente, só não consegue fazer nada dentro do
app nem escrever no banco. Um banimento à prova de qualquer contorno (ex:
"eu recadastro com o mesmo e-mail depois que expira" não se aplica aqui,
mas "eu crio uma conta nova do zero" sempre vai ser possível — banir uma
conta nunca impediu cadastro de outra) pediria desativar a conta de
verdade via `admin.auth().updateUser(uid, {disabled: true})`, que é uma
Cloud Function — fora do escopo de hoje, registrado pra quando fizer
sentido.

## Testes

- `UserModel.estaBloqueado()`: ativo não bloqueia, banido bloqueia sempre,
  suspenso dentro do prazo bloqueia, suspensão vencida libera sozinha,
  suspenso sem `suspensoAte` gravado (defensivo) não bloqueia.
- `UserModel.motivoModeracao`: lido do Firestore quando presente, nulo em
  conta nunca moderada.
- `ContaBloqueadaView`: mensagem certa por estado (banido/suspenso), data
  formatada da suspensão, motivo aparece só quando existe, botão "Sair"
  chama o callback.
- **Não testado de ponta a ponta**: o `firestore.rules` em si (bloqueio de
  update de campo de moderação e de create/vote pra conta bloqueada) — este
  ambiente não tem o Firebase CLI nem o emulador de regras instalados, só
  dá pra validar a lógica do lado Flutter. Recomendo testar manualmente
  depois do deploy: banir uma conta de teste e confirmar que ela não
  consegue mais editar o próprio perfil pra reverter o estado, nem publicar
  post, usando o console do Firebase ou o próprio app.

## Pendência de deploy

`firebase deploy --only firestore:rules` — sem isso as três checagens
novas (`contaBloqueada()`, o travamento dos campos de moderação, e o uso
deles em `posts`/`podeVotar`) não valem nada em produção; o app já bloqueia
a UI, mas a regra antiga continua no ar até o deploy. **Já feito** pelo
usuário em 01/set/2026, junto com este pacote.

## O bloqueio virou global (mesmo dia)

A primeira versão só checava em `Home` (o Feed) — perguntado sobre isso,
ficou claro que não era em tempo real pra quem estivesse em outra tela
(Vídeos, Perfil, Conquistas) no momento do banimento: a pessoa só caía na
tela de bloqueio ao voltar pro Feed. Publicar/votar já era barrado na hora
de qualquer tela (via `contaBloqueada()` nas regras), mas a UI ficava
comportando-se como se nada tivesse acontecido até isso.

Correção: o bloqueio subiu pro `builder` do `MaterialApp`
(`lib/main.dart`), que envolve QUALQUER tela em qualquer rota — não só a
Home. Peças novas:

- **`AuthRepository.streamUsuarioReativo()` / `AuthViewModel` (mesmo
  nome)**: diferente do `streamUsuarioAtual()` usado pelas telas comuns
  (que fixa o uid no instante em que é chamado), este acompanha login e
  logout em si — troca de assinatura sozinho quando o uid muda. Precisa
  disso porque o gate vive o app inteiro e nunca é recriado por uma troca
  de tela pra "descobrir" de quem é a vez de ouvir.
- **`lib/components/ContaGate.dart`**: `GateDeConta` (widget puro, testável
  sem Firebase — só `Stack([child, if bloqueado ContaBloqueadaView])`) e
  `ContaGate` (a parte com Firebase, que alimenta o primeiro). O conteúdo
  normal do app continua **montado por baixo**, só coberto — não troca de
  rota. Isso é o que faz uma suspensão vencer com o app aberto devolver a
  pessoa pro exato lugar onde estava, sem perder navegação.
- **`main.dart`**: `MaterialApp` ganhou `navigatorKey` (um `GlobalKey`
  estático) e `builder: (context, child) => ContaGate(...)`. O
  `navigatorKey` existe porque o "Sair" do `ContaGate` precisa navegar pro
  Login, mas o `context` do `builder` fica ACIMA do `Navigator` do app —
  `Navigator.of(context)` não o alcançaria dali.
- O gate antigo, dentro de `Home._construirTela`, foi removido — ficou
  redundante (o `ContaGate` cobre a Home também).

Testado: `GateDeConta` isolado (usuário nulo/ativo/banido/suspenso dentro e
fora do prazo, conteúdo continua montado por baixo, botão "Sair" chama o
callback). `ContaGate` em si (a parte com Firebase/navegação) não tem teste
de ponta a ponta, mesma limitação de sempre neste ambiente.

# Correções na aba Usuários do Painel ADM (03/set/2026)

## Foto de perfil na lista

Cada card da lista de usuários passou a mostrar o avatar da pessoa, e o
modal de "Ver perfil" também — antes ele só listava os campos de texto,
sem foto nenhuma.

Para não repetir em cada tela o encadeamento de três casos (**preset
escolhido > `fotoUrl` > avatar padrão**, ver `chavePresetParaExibir`), isso
virou o componente `lib/components/AvatarUsuario.dart`.

## A foto do login com Google não aparecia

Duas causas somadas:

1. **O modal "Ver perfil" não tinha avatar nenhum** — nem pra quem entrou
   com Google, nem pra quem subiu foto própria. Resolvido junto do item
   acima.
2. **Na Web, `Image.network` cru falhava pra `lh3.googleusercontent.com`** —
   exatamente a mesma causa raiz das miniaturas de vídeo (31/ago): o Flutter
   baixa os bytes por XHR e decodifica, caminho que depende de CORS. O
   `FotoPerfilRede` ganhou `webHtmlElementStrategy:
   WebHtmlElementStrategy.fallback`, que monta um `<img>` de verdade quando
   o download falha. Isso conserta o avatar do Google em **todas** as telas
   (Perfil, Editar perfil e o Painel), não só no painel.

Terceiro ponto, menos visível: `_sincronizarUsuarioNoFirestore` só gravava
`fotoUrl` quando a conta era **nova**. Quem se cadastrou por e-mail/senha e
só depois entrou pelo Google ficava sem foto pra sempre, porque o ramo de
conta existente só tocava o `ultimoAcesso`. Agora ele preenche a `fotoUrl`
do provedor quando a conta está sem foto **e** sem preset — foto própria já
enviada e preset escolhido continuam intocados.

## Ícones no menu de 3 pontinhos

Cada opção ganhou ícone à esquerda: pessoa (Ver perfil), pause (Suspender),
bloqueio em vermelho (Banir), check (Reativar) e balão (Mensagem privada).
"Enviar mensagem privada" virou "Mensagem privada": com o ícone ocupando
espaço, o rótulo antigo estourava a largura máxima do menu — o teste novo
pegou isso.

## Testes

- `avatar_usuario_test.dart`: prioridade preset > foto > padrão, e o
  `FotoPerfilRede` pedindo o fallback pra `<img>` na Web.
- `painel_admin_test.dart`: ganhou um `FakeAdminRepository` (o `PainelAdmin`
  já aceitava o repositório injetado, então dá pra testar a aba Usuários sem
  Firestore) — card com avatar, ícones no menu, troca de suspender/banir por
  reativar em conta já moderada, e a foto no "Ver perfil".
- **Não testado de ponta a ponta**: o login social em si (Google/Apple
  precisam de plugin nativo e conta real). O backfill da `fotoUrl` no login
  precisa ser conferido entrando com uma conta que tenha se cadastrado por
  e-mail/senha antes.

# Criação de conta em etapas (03/set/2026)

Substitui a tela única `Cadastro.dart` (que pedia tudo de uma vez) por um
fluxo de uma pergunta por tela, com a arte do PTK ao fundo mudando junto.

## As etapas

`etapasDoCadastro(contaSocial:)` decide quais telas existem:

| Etapa       | Cadastro manual | Google/Apple | Arte do PTK        |
| ----------- | :-------------: | :----------: | ------------------ |
| Boas-vindas |       sim       |     sim      | *(falta)*          |
| Nick        |       sim       |     sim      | `ptk_nickname.jpg` |
| E-mail      |       sim       |     não      | `ptk_email.jpg`    |
| Senha       |       sim       |     não      | `ptk_senha.jpg`    |
| Foto        |       sim       |     sim      | `ptk_foto.jpg`     |
| WhatsApp    |       sim       |     sim      | `ptk_whatsapp.jpg` |

E-mail e senha somem no fluxo social porque o provedor já resolveu os dois
— pedir de novo seria criar uma segunda senha pra mesma conta.

## Decisões que valem registrar

- **Tudo é obrigatório**, e o "Avançar" fica desabilitado até a etapa estar
  completa. A mesma função pura de `ValidacaoCadastro.dart` alimenta o aviso
  embaixo do campo **e** a liberação do botão — assim os dois nunca
  discordam.
- **O aviso de erro é em tempo real, embaixo do campo, e não em modal.** A
  regra do CLAUDE.md (erro de formulário em modal bloqueante) continua
  valendo pro envio; aqui é checagem contínua a cada tecla, e um modal pra
  fechar a cada caractere seria insuportável. O aviso só aparece depois que
  a pessoa mexe no campo — acusar um campo intocado seria injusto.
- **O `PageView` não deixa arrastar** (`NeverScrollableScrollPhysics`):
  arrastar pularia a checagem da etapa.
- **A arte muda com cross-fade + deslize** (`FundoPTK`), não com corte seco:
  são todas do mesmo personagem no mesmo cenário, e o corte seco leria como
  glitch.
- **Etapa sem arte definida cai no gradiente do app**, sem quebrar — hoje
  só as boas-vindas, cuja arte ainda não chegou.
- As artes vieram em PNG de ~1,7 MB cada. Convertidas pra JPEG de largura
  1080: **8,4 MB → 775 KB nas cinco**, sem perda visível (o original já era
  941px de largura). Fundo de tela em PNG sem transparência é desperdício,
  ainda mais na Web.

## Máscara de telefone agora aceita fixo

`MascaraTelefoneWhatsapp` passou a decidir o formato pela quantidade de
dígitos: até 10 é fixo (`+55 (DD) NNNN-NNNN`), no 11º vira celular (`+55
(DD) NNNNN-NNNN`). Por isso ela deixou de mostrar um gabarito de espaços em
branco e passou a **crescer** conforme a digitação — com dois formatos
possíveis, um gabarito fixo estaria errado pra metade dos números. A
validação já aceitava os dois tamanhos; só a máscara visual não.

## Uma regra de nickname só

Existiam duas: `validarNickname` no `AuthViewModel` (só checava vazio e
"@") e a nova, mais completa (3 a 20 caracteres). A do `AuthViewModel` foi
removida e o `EditarPerfil` passou a usar a nova — duas regras com o mesmo
nome pro mesmo campo era pedir pra divergirem.

## Testes

- `validacao_cadastro_test.dart`: as sete validações, incluindo e-mail que
  ignora maiúsculas na confirmação e senha que **não** ignora.
- `criar_conta_test.dart`: as etapas por modo (manual x social), o mapa de
  artes, e o fluxo em si — avançar travado com campo vazio, aviso em tempo
  real, e-mails divergentes travando a etapa, voltar sem perder o que foi
  digitado, e o social pulando do nick pra foto.
- `whatsapp_telefone_test.dart`: atualizado pro formato dinâmico, com casos
  novos de fixo e da reformatação no 11º dígito.
- **Não testado de ponta a ponta**: a criação da conta em si (Firebase Auth
  + Firestore + Storage) e a câmera — dependem de infraestrutura e hardware
  que não existem neste ambiente.

## Login social cai no cadastro quando a conta é nova

`AuthRepository.loginComGoogle`/`loginComApple` passaram a devolver **se a
conta acabou de ser criada** (o `_sincronizarUsuarioNoFirestore` já sabia
disso pelo `doc.exists`; só não contava pra ninguém). O `AuthViewModel`
propaga isso num record `({erro, contaNova})`, e o `Login` usa pra decidir
o destino: conta nova vai pro cadastro em etapas com `contaSocial: true`
(sem as telas de e-mail e senha, que o provedor já resolveu), conta que já
existia vai direto pro feed.

O nick já vem sugerido com o nome da conta Google/Apple
(`AuthViewModel.nomeDoProvedor`) — melhor que abrir o campo em branco.

## Pendências deste fluxo

- **Falta a arte de boas-vindas**. Basta soltar o arquivo em `assets/ptk/`
  e apontar em `assetDaEtapa`.
- **`Cadastro.dart` (a tela antiga) ficou só pro harness de screenshots**
  (`main_screenshots.dart`). Remover quando o fluxo novo estiver validado
  em produção.

# Painel ADM: contraste no escuro e remoção de usuário (04/set/2026)

## Três correções visuais

- **O menu de 3 pontinhos abria branco no tema escuro**, com o texto dos
  itens também branco — ilegível. O `PopupMenuButton` usava o branco padrão
  do Material; agora ele recebe a cor de superfície do app conforme o tema.
- **A lixeira do post ficava vermelha no escuro**, sumindo no fundo roxo.
  Passou a ser branca só no modo escuro; no claro o vermelho continua,
  porque ali ele contrasta e sinaliza o risco.
- **O post aparecia cortado em 2 linhas** na aba Posts, escondendo
  justamente o que o admin precisa ler antes de apagar. Agora aparece
  inteiro.

## Remoção de usuário em cascata

Opção nova no menu (`AdminRepository.removerUsuario`), que apaga em
sequência:

1. todos os posts do feed com `autorUid` da pessoa;
2. a reserva do nickname em `nicknamesParaEmail` — sem isso o nick ficaria
   preso pra sempre a uma conta que não existe mais;
3. o documento do usuário, **por último**: as regras leem o cargo de quem
   chama a partir de `users/{uid}`, e apagar o documento no meio derrubaria
   a permissão do próprio admin se ele estivesse removendo a si mesmo.

Mensagens do grupo e conversas privadas entram nesse mesmo método quando
existirem (Etapa 3) — o lugar já está marcado no código.

**`firestore.rules`** precisou de duas mudanças: o admin não podia apagar
documento de outro usuário (`allow delete: if ehDono(userId)`), e
`nicknamesParaEmail` tinha `allow delete: if false` pra todo mundo.

### O que a remoção NÃO faz

- **Não apaga a conta do Firebase Auth.** Só o Admin SDK, numa Cloud
  Function, consegue. Na prática: se a pessoa entrar de novo pelo
  Google/Apple, uma conta nova e vazia é criada. O diálogo de confirmação
  avisa isso, porque é o tipo de coisa que o clique não deixa óbvia.
- **Não apaga os arquivos do Storage** (foto de perfil, mídia dos posts).
  Regra de Storage não lê o Firestore, então não há como autorizar o admin
  lá — os arquivos ficam órfãos. Mesma limitação que já vale pro upload de
  mídia; a saída de verdade é um *custom claim* de admin, já anotado.

## Testes

`painel_admin_test.dart` cresceu: opção no menu, cancelar não removendo
nada, confirmar removendo e dizendo quantos posts foram junto, o menu não
abrindo branco no escuro (e seguindo branco no claro), a lixeira branca, e
o post sem `maxLines`.

Dois detalhes do arquivo de teste que valem registro: o painel encadeia
animações (troca de aba, menu, diálogo) e o fundo anima em loop, então
`pumpAndSettle` trava — os testes usam vários `pump` espaçados. E a TabBar
tem 6 abas, que não cabem na janela padrão de 800x600 do teste; o grupo que
usa a aba Posts abre uma janela de desktop.

**Não testado de ponta a ponta**: a cascata em si e a regra `ehAdmin()`,
que dependem do Firestore real ou do emulador.

## Pendência de deploy

`firebase deploy --only firestore:rules` — sem isso a remoção falha com
`permission-denied` na hora de apagar o documento do usuário.


# Onda no cadastro e cards de vídeo no escuro (04/set/2026)

## Cards da aba Vídeos

No tema escuro o card era quase todo miniatura, e o vidro padrão
(`cardBgDark`, branco a 12%) deixava tão pouca superfície visível que a
miniatura parecia flutuar solta na tela. Constante nova
`AuthTheme.cardVideoBgDark` (branco a 20%), aplicada no card inteiro e na
faixa de texto — separada de propósito, pra não mexer nos cards do feed e
do painel, onde os 12% funcionam.

Dois consertos que apareceram junto, ao escrever o teste:

- o `CircleAvatar` do canal não tinha `onBackgroundImageError`, então uma
  falha ao baixar o avatar subia como exceção não tratada do Flutter em vez
  de só deixar o círculo com a cor de fundo;
- a linha "Publicado em ..." estourava a largura em card estreito (celular
  pequeno); virou `Flexible` com ellipsis.

## Cadastro com onda

O fundo deixou de escurecer a arte inteira. Agora a tela é dividida em
duas: a arte do PTK no alto (aproveitando o fundo colorido que já vem
nela, alinhada ao topo porque é onde está o rosto) e uma **onda branca**
subindo de baixo, onde o formulário vive.

`FormaDaOnda` descreve a curva em quatro frações da altura, então ela
acompanha qualquer aparelho: duas alturas de borda — a diferença entre elas
dá a inclinação — e dois pontos de controle, que decidem se a curva forma
crista ou vale. `ondasDoCadastro` traz uma forma por etapa, alternando o
lado da inclinação, pra as telas não parecerem a mesma tela com o texto
trocado.

Decisões que valem registrar:

- **A onda anima por interpolação dos quatro números**, não por cross-fade:
  assim ela escorre de um desenho pro outro, em vez de uma sumir enquanto a
  outra aparece.
- **O formulário anima junto** (mesma duração), num `AnimatedPositioned`
  que começa no ponto mais alto da curva — senão ele pularia de posição
  enquanto a onda ainda estivesse escorrendo.
- **Com o teclado aberto a arte encolhe pela metade.** É o mesmo número que
  desenha a onda, então as duas coisas acompanham e o formulário continua
  cabendo.
- **As bolinhas de progresso ficam sobre a arte**, no alto: ali não roubam
  espaço do formulário, e o branco delas aparece bem no fundo escuro.
- **Sem botão de trocar tema, de propósito.** É a única tela do app com
  identidade visual própria, e o conteúdo vive sempre sobre o branco — por
  isso as cores do formulário são fixas, e não vindas do `ThemeController`.

## Pendência anotada pra próxima

**Custom claim de admin no Auth**, via Cloud Function. Resolve de uma vez
duas limitações já registradas: fechar a escrita no Storage (hoje qualquer
logado pode subir arquivo na própria pasta, ainda que não consiga publicar)
e permitir que a remoção em cascata apague também a conta do Firebase Auth
e os arquivos órfãos do Storage.


# Correções da tela de cadastro (05/set/2026)

Três problemas reportados com print do preview, todos na mesma tela.

## O texto escapava pra cima da arte

Era um erro de conta meu, em duas camadas:

1. O formulário era posicionado pelo ponto **mais alto** da onda. O certo é
   o mais **baixo**: a faixa branca só existe em toda a largura dali pra
   baixo. Onde a curva descia numa borda, o texto ficava por cima da arte.
2. Esse "ponto mais alto" era o menor dos quatro números da forma — mas
   dois deles são **pontos de controle** da Bézier. A curva é puxada na
   direção deles e nunca chega neles, então o valor nem correspondia a uma
   altura que a curva tem.

`FormaDaOnda` agora sabe calcular a curva de verdade: `alturaEm(t)` é a
Bézier, `fundoDaCurva` acha o ponto mais baixo por amostragem, e
`topoDoConteudo(fracaoDeFolga)` desce mais 20% da altura da faixa branca
pra o texto não nascer colado na curva.

O teste que fecha o assunto percorre **todas** as ondas do cadastro
(incluindo a cheia) e confirma que o conteúdo começa abaixo da curva
inteira, ponto a ponto.

## A onda enche a tela quando o teclado abre

Enquanto a pessoa digita, a forma vira `ondaCheia` e a curva sobe até ~10%
do topo, cobrindo quase toda a arte. Perder o PTK de vista nesse momento é
de propósito: o que importa ali é digitar sem o campo espremido contra o
teclado.

- A animação já existente (interpolação dos quatro números) faz a subida
  parecer líquido enchendo a tela. A curva passou pra `easeOutCubic`, que
  sobe rápido e desacelera no fim, como líquido se acomodando.
- O formulário sobe junto, na mesma duração e curva — senão saltaria pro
  lugar antes de a onda chegar.
- A folga cai de 20% pra 6% nesse estado: ali o que importa é caber.
- As bolinhas de progresso trocam pro tom escuro, senão sumiriam no branco
  que passou a cobrir o topo.

**Detalhe que quase passou**: com o teclado aberto o `Scaffold` encolhe o
corpo, e é essa altura menor que a onda usa pra se desenhar. O formulário
estava sendo medido por `MediaQuery`, ou seja, pela tela inteira — as duas
coisas em escalas diferentes, e a folga errada justo no momento mais
apertado. Agora as duas leem a mesma altura, do `LayoutBuilder`.

## A arte subiu

`deslocamentoDaArte` (12% por padrão) puxa a imagem pra cima. As artes têm
o PTK de corpo inteiro, mas o que interessa na tela é o rosto. A faixa que
sobra vazia embaixo fica sempre coberta pela onda, então não aparece.
