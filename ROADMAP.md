# Roadmap / Pendências futuras

Itens identificados mas propositalmente adiados por não serem bloqueantes no momento.

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
