# Checkpoint — PTK Plays

Snapshot do estado do projeto em **04/set/2026**, escrito pra retomar o
trabalho numa sessão nova do Claude sem perder contexto (a sessão anterior
passou por um `/clear` aqui). Ver também:

- **`ROADMAP.md`** — o registro detalhado, em ordem cronológica, de cada
  entrega e das decisões técnicas por trás delas. Quando algo aqui parecer
  raso, a explicação inteira está lá.
- **`CLAUDE.md`** — regras permanentes (testes unitários obrigatórios,
  Toast/loading, convenção de commits, tags de release, Google Play,
  signing do Android).
- **`REGRAS_DA_COMUNIDADE.md`** — as regras de convivência do feed e onde
  cada uma é aplicada no código.

## ⚠️ O que precisa de atenção AGORA

1. **Falta a arte de boas-vindas do cadastro.** É a única das 6 etapas sem
   arte do PTK — ela cai no fundo roxo liso, com a onda igual às outras.
   Pra resolver: soltar o arquivo em `assets/ptk/` e apontar em
   `assetDaEtapa` (`lib/view/CriarConta.dart`). As outras cinco artes já
   estão lá, convertidas pra JPEG 1080px.
2. **Custom claim de admin no Auth** — a pendência que o usuário pediu
   explicitamente pra fazer "na próxima". É uma Cloud Function que marca o
   admin com um custom claim, e resolve **duas** limitações de uma vez:
   - fechar a escrita no Storage (hoje qualquer logado pode subir arquivo
     na própria pasta `posts_midia/{uid}/`, mesmo sem conseguir publicar);
   - permitir que a remoção em cascata de usuário apague também a conta do
     Firebase Auth e os arquivos órfãos do Storage.
3. **App Store — status não verificado nesta sessão.** O build **1.2.1
   (17)** foi submetido à Apple em 25/ago/2026. Nenhuma sessão desde então
   checou o resultado. Perguntar ao usuário antes de assumir qualquer
   coisa.
4. **Google Play — aviso de nível de API.** O código está certo
   (`compileSdk`/`targetSdk` fixos em **36** desde 27/jul, e as tags
   `v1.2.1+13`, `1.2.1+14` e `v1.2.1+16` já contêm isso). O que o Play
   Console olha é o **artefato publicado** — o aviso só some quando um
   build feito a partir dessa versão for promovido. Ver `CLAUDE.md`.

## Estado do git

- Branch de dev: **`claude/ptk-plays-setup-2q86aw`**, sincronizada com
  `main` em **`26eca4e`** (merge do PR #63).
- **`main` → deploy automático no Vercel em `https://ptk-plays.vercel.app`**
  (atenção: `plays.vercel.app`, que consta em versões antigas deste
  arquivo, **dá 404** — não é o endereço certo).
- Cada PR gera um **preview próprio no Vercel**, comentado no próprio PR —
  é assim que o usuário revisa mudança visual antes de mesclar.
- `pubspec.yaml`: `version: 1.2.1+17`.
- iOS/Android buildam via Codemagic **só** quando uma tag `v*` é criada e
  enviada — nunca criar/enviar tag sem o usuário pedir, e esta sessão não
  consegue dar `git push` de tag de qualquer forma.

### Como o usuário trabalha (importante)

- **Ele mescla os PRs.** Nas últimas sessões ele pediu pra eu abrir **e**
  mesclar; na última, pediu só pra abrir, porque queria ver o preview do
  Vercel antes. **Perguntar, ou seguir o que ele disse no pedido.**
- **Um commit por arquivo alterado** — pedido explícito dele em
  04/set/2026. Não juntar vários arquivos num commit só.
- **Deploys de Firebase são feitos por ele**, no Cloud Shell. Esta sessão
  não tem `firebase`/`gcloud` CLI.

## Saúde do projeto

- **267 testes** passando (`flutter test`).
- `flutter analyze`: **0 erros, 0 warnings**. Há uma baseline conhecida de
  ~96 *infos* antigas (nomes de arquivo em PascalCase, `withOpacity`
  deprecated) — não são regressão, não mexer sem pedir.
- Ocasionalmente o analyze mostra **um warning fantasma** em
  `lib/view/Videos.dart:120` na primeira execução após edições; ele some na
  segunda. É pré-existente e não relacionado às mudanças.

## Deploys — o que já está publicado

Tudo abaixo **já foi deployado** pelo usuário (confirmado por print do
Cloud Shell):

- `firestore.rules` — última publicação em 04/set, com a remoção em
  cascata.
- `storage.rules` — publicado em 01/set (mídia em posts).
- Functions `twitchWebhook`, `kickWebhook`, `verificarYoutubeAoVivo` —
  publicadas em 02/set.

**Não há deploy pendente no momento.** Atenção: `firebase deploy --only
storage:rules` **não funciona** (o CLI interpreta "rules" como nome de
target); o comando certo é `firebase deploy --only storage`.

## O que foi feito nas últimas sessões (28/ago → 04/set)

Resumo; o detalhe de cada decisão está no `ROADMAP.md`, seção por data.

### Painel ADM (`lib/view/PainelAdmin.dart`)

6 abas: **Usuários, Posts, Cargos, Badges, Notificações, WhatsApp**. Só as
duas primeiras são funcionais; as outras explicam o que falta.

- **Usuários**: lista com avatar, selo de cargo e menu de 3 pontinhos com
  ícones — ver perfil, suspender (7 dias), banir, reativar, mensagem
  privada (ainda não pronta) e **remover usuário**.
- **Remoção em cascata** (`AdminRepository.removerUsuario`): apaga os posts
  da pessoa, a reserva do nickname em `nicknamesParaEmail` e, **por
  último**, o documento do usuário — nessa ordem porque as regras leem o
  cargo de quem chama a partir de `users/{uid}`. **Não** apaga a conta do
  Auth nem os arquivos do Storage (ver pendência 2 lá em cima).
- **Posts**: publicar, ver o post inteiro e apagar, mais a ação "Limpar
  avisos de live antigos".

### Feed (`lib/view/Home.dart`)

- **Inscritos publicam** aviso de texto; **admin** publica também enquete e
  mídia. Post de admin tem prioridade e fica no topo
  (`PostModel.ordenarParaFeed`).
- **Mídia (`avisoMidia`)**: foto e vídeo no mesmo post, só do admin. Vídeo
  toca dentro do card (`video_player`), começando parado.
- **Card de imagem no formato do Instagram**: a proporção acompanha a foto,
  entre 9:16 e 1.91:1.
- **Feed enxuto**: abre com 10 posts e nenhum com mais de 30 dias; rolando
  além disso o histórico entra, sempre depois dos recentes.
- **Avisos de live no formato antigo** (sem plataforma gravada) não são
  mais desenhados.

### Moderação de verdade

Antes, banir só marcava um campo — nada no app usava. Agora:

- `UserModel.estaBloqueado()` — banido sempre; suspenso só dentro do prazo
  (suspensão vencida libera sozinha).
- `ContaGate` (`lib/components/ContaGate.dart`) fica no `builder` do
  `MaterialApp`, **acima de toda a navegação**: cobre qualquer tela com o
  aviso de bloqueio, em tempo real, sem trocar de rota — o conteúdo segue
  montado por baixo, então uma suspensão que vence com o app aberto
  devolve a pessoa exatamente onde estava.
- `firestore.rules` trava `estadoModeracao`/`suspensoAte`/`motivoModeracao`
  contra escrita do próprio dono (antes, um banido se desbania sozinho numa
  escrita comum de perfil) e barra post/voto de conta bloqueada.

### Cadastro em etapas (`lib/view/CriarConta.dart`)

Substituiu a tela única. Uma pergunta por tela: **boas-vindas, nick,
e-mail, senha, foto, WhatsApp**. E-mail e senha somem no fluxo social.

- **Layout de onda**: arte do PTK no alto, onda branca subindo de baixo com
  o formulário sobre ela. Cada etapa tem uma curva diferente
  (`FormaDaOnda`/`ondasDoCadastro` em `lib/components/FundoPTK.dart`) — se
  o usuário quiser ajustar, é só mexer nos quatro números de cada linha.
- **Esta é a única tela do app sem troca de tema**, de propósito: as cores
  do formulário são fixas, não vêm do `ThemeController`.
- Campos com rótulo flutuante, ícone interno e **validação em tempo real**
  embaixo do campo (que só aparece depois que a pessoa mexe nele). A mesma
  função pura de `ValidacaoCadastro.dart` alimenta o aviso **e** a
  liberação do "Avançar".
- **Máscara de telefone aceita fixo** (10 dígitos) além de celular (11),
  decidindo o formato pela quantidade de dígitos.
- **Login social de conta nova cai aqui** em vez de ir pro feed, com o nick
  já sugerido pelo provedor.

### Correções visuais

- Foto do Google não aparecia na Web: `Image.network` cru falha para
  `lh3.googleusercontent.com` pelo caminho XHR+decode (que exige CORS) — a
  **mesma causa raiz** das miniaturas de vídeo. Resolvido com
  `WebHtmlElementStrategy.fallback` no `FotoPerfilRede` e no `ImagemRede`.
  **Se alguma imagem sumir na Web, suspeitar disso primeiro.**
- Menu de 3 pontinhos abria branco no tema escuro (texto branco em fundo
  branco); lixeira vermelha sumia no fundo roxo; card da aba Vídeos
  transparente demais (`cardVideoBgDark`, branco a 20%).

## Backend

### WhatsApp (webhook de recuperação de senha)

- `whatsappWebhook` implementada e deployada no projeto `ptk-plays`,
  **região `us-central1`** (sem região explícita).
- **Cuidado ao mexer em `functions/index.js`**: não usar `setGlobalOptions`
  pra região — isso mudaria a região do `whatsappWebhook` e quebraria a URL
  cadastrada no Meta. As functions de live usam `region:
  "southamerica-east1"` explícita, cada uma.
- **Não confirmado**: se a URL + verify token já foram colados no
  formulário do Meta for Developers, e se o número de produção foi
  registrado. Perguntar antes de assumir.

### Detecção de live + `transmissoes` no PTK AI Studio

`functions/lib/transmissoes.js` escreve na coleção `transmissoes` do
projeto **separado** `ptk-ai-studio`, via Application Default Credentials.
O backfill já rodou: **124 lives do YouTube + 3 VODs da Twitch**.

- **YouTube**: `vodId` é o próprio `videoId`.
- **Twitch**: VOD buscado via Helix depois do `stream.offline`; título via
  Helix no `stream.online`.
- **Kick**: sem VOD (a plataforma não expõe) e o id da transmissão é
  derivado do `started_at`.
- **Não verificado**: se o app/dashboard do PTK AI Studio já **lê** essa
  coleção — está num repositório separado que nenhuma sessão viu. Se o
  usuário quiser essa ponta conferida, anexar o repo com `add_repo`.

## Pendências, em ordem de esforço

1. **Arte de boas-vindas** do cadastro (trivial: 1 arquivo + 1 linha).
2. **Custom claim de admin** no Auth (ver atenção 2).
3. **Etapa 3 — mensagem privada do admin**: coleção `conversas` + regras +
   tela de chat. A opção já existe no menu e avisa que não está pronta.
   Quando existir, entra também na remoção em cascata (o lugar já está
   marcado no código).
4. **Etapa 4 — autoplay do preview na aba Vídeos** (mudo, um player por
   vez, com detector de visibilidade).
5. **Etapa 5 — badges pelo painel**: `badges` é travado contra escrita do
   cliente de propósito, então precisa de Cloud Function.
6. **Etapa 6 — notificações push por cargo.**
7. **Etapa 7 — cargos customizados com permissões**: a mais invasiva,
   reescreve boa parte do `firestore.rules`.
8. **Etapa 8 — aviso por WhatsApp**: bloqueada até o usuário ter número
   virtual + verificação na Meta.

**Ideias registradas, ainda não pedidas**: log de auditoria de moderação
(quem baniu quem e quando), campo de motivo ao banir (hoje o clique bane
direto, sem motivo), busca/paginação na lista de usuários, denúncia dentro
do app e moderação de mídia, `avisoFoto` legado, envelhecimento da
prioridade dos posts de admin.

**Faxina pendente**: `lib/view/Cadastro.dart` (a tela antiga) ficou só pro
harness de screenshots (`lib/main_screenshots.dart`) — remover quando o
fluxo novo estiver validado em produção.

## Notas de ambiente (sandbox de dev)

- Flutter fica em `/opt/flutter/bin`, **fora do PATH** — rodar
  `export PATH="$PATH:/opt/flutter/bin"` antes de qualquer comando
  `flutter`.
- `flutter analyze`/`build` sujam `analysis_options.yaml` — conferir
  `git status` antes de commitar.
- **Sem `firebase`/`gcloud` CLI** e sem credenciais: nenhum deploy, nenhum
  acesso ao Firestore real, e **nenhum teste de regra do Firestore** (não
  há emulador). Sempre avisar o usuário quando algo depender disso.
- `node`/`npm` disponíveis (`/opt/node22`) — `npm test` roda dentro de
  `functions/` (18 testes Jest).
- **Python com PIL disponível** — foi assim que as artes do PTK foram
  convertidas de PNG (1,7 MB cada) pra JPEG 1080px (~150 KB).
- Testes de widget: `pumpAndSettle` **trava** em várias telas do app,
  porque o `AuthBackground` anima em loop infinito. Usar `pump()` com
  durações. O Painel ADM ainda precisa de janela larga (as 6 abas não
  cabem em 800x600) e de vários frames (o `StreamBuilder` da lista demora
  a resolver).
- Projeto Firebase `ptk-plays` no plano Blaze; `ptk-ai-studio` idem.
- Pasta local `appstore_screenshots/` (só na máquina do usuário) **não**
  deve ser commitada — decisão explícita.
