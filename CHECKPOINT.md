# Checkpoint — PTK Plays

Snapshot do estado do projeto em **27/ago/2026**, escrito pra retomar o
trabalho numa sessão nova do Claude sem perder contexto (esta sessão vai
passar por um `/clear`). Ver também `ROADMAP.md` (pendências e decisões
técnicas mais detalhadas, principalmente do backend) e `CLAUDE.md` (regras
permanentes: testes unitários, Toast/loading, commits, tags, Google Play,
signing).

## ⚠️ O que precisa de atenção AGORA (nesta ordem)

1. **App Store — aguardando revisão da Apple.** Build **1.2.1 (17)**
   submetido pra revisão oficial em 25/ago/2026 23:48 (ID do envio
   `6db9576f-1f55-4ba0-aa62-6d06009a9495`), status **"Aguardando
   revisão"** na última checagem. TestFlight externo foi **pulado de
   propósito** (usuário não tem testadores com iPhone) — Apple não exige
   isso pra revisão oficial, diferente do Google Play. Só falta esperar a
   resposta (aprovação ou rejeição com motivo) — não fazer nada até lá.
2. **Branch de dev com 3 commits não mergeados em `main`**:
   `claude/ptk-plays-setup-2q86aw` está em `e1c156e`, `main` em `49e8e2f`
   (3 commits atrás: `cef29b6`, `0780210`, `e1c156e` — todo o trabalho de
   detecção de live + `transmissoes` do PTK AI Studio, ver seção
   dedicada abaixo). Já foi **deployado direto da dev branch** via Cloud
   Shell (não depende de merge pra funcionar), mas os commits ainda não
   viraram PR pra `main`. Perguntar ao usuário se quer abrir/mergear esse
   PR (não fazer sem pedir).
3. **PTK AI Studio: escrita confirmada, leitura não verificada.** O
   Firestore do projeto `ptk-ai-studio` já tem a coleção `transmissoes`
   populada (127 documentos: 124 lives do YouTube + 3 VODs da Twitch via
   backfill, mais o que a detecção em tempo real for gravando dali pra
   frente) — confirmado visualmente no Console pelo usuário. **Não
   verificado**: se o código do próprio app/dashboard do PTK AI Studio já
   lê essa coleção — isso está num repositório separado que esta sessão
   nunca viu. Se o usuário quiser essa ponta conferida, anexar o repo do
   PTK AI Studio (`add_repo`).

## Estado do git

- Branch de dev: `claude/ptk-plays-setup-2q86aw` — commit atual `e1c156e`.
- `main` (deploy automático via Vercel, `plays.vercel.app`) em `49e8e2f`,
  3 commits atrás da dev branch (ver item 2 acima).
- Fluxo usado: feature branch → PR pra `claude/ptk-plays-setup-2q86aw` →
  merge → PR pra `main` → merge.
- iOS/Android buildam via Codemagic só quando uma tag `v*` é criada e
  enviada — **nunca criar/enviar tag sem o usuário pedir explicitamente**,
  e mesmo assim **esta sessão (CCR) não consegue dar `git push` de tags**
  — quem faz isso é o usuário, da própria máquina dele.
- `pubspec.yaml`: `version: 1.2.1+17` (build já enviado pra Apple, ver
  acima).

## Funcionalidades implementadas recentemente (já mergeadas em `main`)

- **Menu lateral pós-login** (`lib/components/MenuLateral.dart`):
  `Drawer` deslizante (62% da largura), fundo branco opaco no claro,
  gradiente branco→roxo opaco no escuro, atalhos pra Recuperação de
  Senha, Privacidade, Política de Privacidade e Configurações.
- **Política de Privacidade dentro do app** (`lib/utils/PoliticaPrivacidade.dart`,
  `lib/view/PoliticaPrivacidadeWeb.dart`): renderiza a página num
  `InAppWebView` com botões flutuantes de voltar/tema, **exceto na Web**
  (o proxy de tradução `translate.goog` recusa ser embutido em iframe —
  corrigido abrindo em aba nova via `url_launcher` só nesse caso,
  `kIsWeb`).
- **Tradução automática por localização**: Brasil → português (via
  `translate.goog`), qualquer outro país → inglês, decidido pelo
  `countryCode` do locale do dispositivo/navegador (não por IP/GPS —
  Portugal, por exemplo, fica em inglês mesmo sendo `pt`).
- Ícones dos botões voltar/tema corrigidos pra preto no modo escuro
  (estavam amarelos sobre fundo branco).

Tudo isso com teste unitário/widget cobrindo, `flutter test` (78+ testes)
e `flutter analyze` rodados sem regressão.

## Backend — WhatsApp (webhook de recuperação de senha)

- `functions/index.js` (`whatsappWebhook`) implementado, deployado no
  projeto `ptk-plays`, **região `us-central1`** (sem região explícita —
  importante não mudar isso num deploy futuro, ver nota abaixo).
- Bug de deploy já resolvido: o secret `WHATSAPP_VERIFY_TOKEN` tinha 2
  caracteres a mais (parênteses perdidos ao colar) causando 403 — corrigido
  e confirmado via `curl` retornando 200/challenge corretamente.
- **Não confirmado nesta sessão**: se a URL da function + o verify token
  já foram colados no formulário "Configurar webhooks" do Meta for
  Developers (Etapa 2), e se o número de telefone de produção já foi
  registrado lá. Perguntar ao usuário antes de assumir que essa etapa
  está fechada.
- Próximo passo, depois do webhook aceito pelo Meta: implementar
  `enviarCodigoRecuperacaoWhatsapp`/`verificarCodigoRecuperacaoWhatsapp` +
  criar um template de mensagem categoria "Authentication" no WhatsApp
  Manager (não dá pra mandar texto livre sem isso).

## Backend — detecção de live + `transmissoes` no PTK AI Studio (27/ago/2026)

### Descoberta importante

As Functions de detecção de live (`verificarYoutubeAoVivo`, `twitchWebhook`,
`kickWebhook`, `kickAuthStart`, `kickOAuthCallback`, `notificarAoVivo`) já
estavam **implantadas em produção** desde 15/jul/2026, mas o código só
existia numa branch antiga `feat/notificacoes-ao-vivo`, **nunca
mergeada**, que tinha divergido do `main` antes do webhook do WhatsApp.
Trazido pra dev branch e mesclado nesta sessão — resolve o "ponto em
aberto" que ficava documentado aqui antes sobre o backend do AI Studio
estar rodando dentro do projeto GCP `ptk-plays` (continua lá, não foi
movido).

**Cuidado ao mexer em `functions/index.js` de novo**: não usar
`setGlobalOptions` global pra região — isso mudaria também a região do
`whatsappWebhook` (que fica sem região explícita, logo `us-central1`) e
quebraria a URL cadastrada no Meta. As functions de live usam
`region: "southamerica-east1"` explícita cada uma.

### O que foi implementado

`functions/lib/transmissoes.js` escreve em `transmissoes` no Firestore do
projeto **separado** `ptk-ai-studio`, via Application Default Credentials
(`@google-cloud/firestore`, `projectId: 'ptk-ai-studio'` — **sem** chave
de service account; IAM `roles/datastore.user` concedido no console pra
conta de serviço `696548413882-compute@developer.gserviceaccount.com`).
ID determinístico `${plataforma}_${idDaTransmissao}`, sempre
`merge: true`. Campos: `plataforma`, `iniciadaEm`, `urlDaLive`,
`idDaTransmissao`, `titulo`, `encerrada`, `encerradaEm`,
`duracaoSegundos`, `vodId`, `vodUrl`.

- **YouTube**: `vodId` de graça (é o próprio `videoId`). `titulo` vem do
  `search.list` que a checagem agendada já faz.
- **Twitch**: id da transmissão vem do `event.id` do `stream.online`. VOD
  buscado via Helix `GET /videos?type=archive` depois do `stream.offline`
  (o evento em si não traz VOD). Título via Helix `GET /streams` no
  momento do `stream.online` (`stream.online` não traz título — só o
  `channel.update`, que não assinamos — confirmado em
  `dev.twitch.tv/docs/eventsub`).
- **Kick**: confirmado em `docs.kick.com/events/event-types` que o
  payload do `livestream.status.updated` traz `title` mas **não** tem
  nenhum id de transmissão dedicado — o id é derivado do `started_at`
  (`extrairIdDaTransmissaoKick`, `functions/lib/kick.js`). **Sem VOD**: a
  Kick não expõe isso nesse webhook, campo fica ausente (não inventado).

### Backfill de lives passadas

`functions/scripts/backfill-transmissoes-passadas.js` — script avulso
(não Function implantada), já **rodado com sucesso** pelo usuário via
Cloud Shell: **124 lives do YouTube + 3 VODs da Twitch** gravados,
confirmados no Console do Firestore do `ptk-ai-studio`.

- **YouTube**: usa a playlist de uploads do canal + `videos.list` em
  lote filtrando `liveStreamingDetails` (bem mais barato em cota que
  `search.list`).
- **Twitch**: pagina `Get Videos` (`type=archive`). Usa `vod.id` (id do
  próprio VOD) como `idDaTransmissao` — **não** `vod.stream_id`: esse
  campo existe mas não há garantia documentada de que seja o mesmo espaço
  de id do `event.id` do `stream.online` em tempo real, então apostar
  nisso com `merge: true` arriscava uma duplicata **silenciosa**.
  Documentos do backfill ficam "congelados" de propósito, sem tentar
  fundir com o que a detecção ao vivo grava depois — seguro porque são
  eventos passados.
- **Kick**: de fora do backfill — confirmado em `docs.kick.com` que não
  existe nenhum endpoint oficial pra listar VODs/lives passadas do canal.
- **Credenciais do script**: `gcloud auth application-default login` com
  a própria conta do usuário (Owner do `ptk-ai-studio`) — não precisa de
  chave de service account nem role adicional.

### Deploy confirmado (27/ago/2026)

Deploy rodado com sucesso via Cloud Shell (`firebase deploy --only
functions`, projeto `ptk-plays`) — as 8 functions aparecem íntegras no
Console (`kickWebhook`, `notificarAoVivo`, `twitchWebhook`,
`kickOAuthCallback`, `kickAuthStart`, `verificarYoutubeAoVivo` em
`southamerica-east1`; `whatsappWebhook` em `us-central1`, região
preservada; `ptk-ai-studio-dashboard` no Cloud Run, pré-existente e
intocado). Secrets `TWITCH_CLIENT_ID`/`TWITCH_CLIENT_SECRET` já existiam
no Secret Manager do `ptk-plays` (usados antes só pelo script
`setup-twitch-eventsub.js`, agora também pela própria `twitchWebhook` em
runtime pra buscar VOD/título).

**Não testado de ponta a ponta** (sem credenciais reais nesta sessão de
dev): payload real de produção da Kick, resposta real da Helix da Twitch
em uso — só a lógica pura tem teste automatizado (`functions/test/`, 18
testes Jest). Ver `ROADMAP.md` pra detalhes completos de cada decisão e
teste.

## Recuperação de senha — decisão de canais

- **E-mail**: implementado (`AuthRepository.enviarEmailRedefinicaoSenha`,
  `FirebaseAuth.sendPasswordResetEmail`).
- **SMS**: não implementado (Firebase Phone Auth nativo, precisa habilitar
  "Phone" em Authentication → Sign-in method + reCAPTCHA pra Web).
- **WhatsApp**: em andamento, ver seção do backend acima.

## O que já está implementado e funcionando (sessões mais antigas, resumido)

- Avatares pré-definidos (6 personas), máscara de telefone WhatsApp
  corrigida, troca de senha em Editar Perfil, avatar padrão pra contas
  legadas, upload de foto de perfil com crop/zoom (Firebase Storage +
  CORS configurado), Toast não-bloqueante pra feedback de ação (regra
  permanente em `CLAUDE.md` — Login/Cadastro/exclusão de conta ainda não
  retrofitados), loading spinners padronizados, botões circulares com
  fundo opaco branco.
- Todos com teste cobrindo. `flutter analyze` tem uma baseline conhecida
  de ~55 issues antigas (nomes de arquivo em PascalCase, `withOpacity`
  deprecated, etc.) — não são regressão, não mexer nisso sem pedir.

## Notas úteis de ambiente (sandbox de dev)

- Flutter fica em `/opt/flutter/bin`, fora do PATH — rodar
  `export PATH="$PATH:/opt/flutter/bin"` antes de comandos `flutter`.
- `flutter analyze`/`flutter build` sujam `analysis_options.yaml`
  automaticamente — conferir `git status` e `git checkout --
  analysis_options.yaml` antes de commitar, se não for intencional.
- Este sandbox **não tem** `firebase`/`gcloud` CLI — todo deploy
  (Functions, tags de release) é feito pelo usuário na própria máquina
  ou no Cloud Shell, nunca por esta sessão diretamente.
- `node`/`npm` disponíveis aqui (`/opt/node22`) — dá pra rodar
  `npm test`/`npm install` dentro de `functions/` normalmente.
- Projeto Firebase `ptk-plays` está no plano Blaze. Projeto separado
  `ptk-ai-studio` também está no Blaze e tem Firestore ativo (confirmado
  via Console, coleção `transmissoes` populada).
- Pasta local `appstore_screenshots/` (só na máquina do usuário) **não**
  deve ser commitada — decisão explícita do usuário, é só material de
  referência visual, não faz parte do repositório.
