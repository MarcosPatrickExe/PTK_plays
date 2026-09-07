# Checkpoint — PTK Plays

Snapshot do estado do projeto em **07/set/2026**, escrito pra retomar o
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

1. **Deploy pendente de Firebase.** A caixa de entrada do WhatsApp (ver
   abaixo) está no código mas **não está no ar**. Falta o usuário rodar,
   no Cloud Shell:
   ```
   firebase deploy --only functions        # webhook que grava
   firebase deploy --only firestore:rules  # regras da colecao nova
   ```
   Dá pra validar a ponta inteira com o **número de teste da Etapa 1** da
   Meta, sem comprometer número de produção.
2. **4 artes novas do PTK, em formato quadrado, esperando o arquivo.** O
   usuário enviou 4 artes 1:1 (joinha/nick, pensativo/senha, WhatsApp e
   selfie/foto) pra substituir as atuais, mas os arquivos **não chegaram
   ao disco do container** em duas tentativas — só apareceram na conversa.
   Pedir pra reenviar. Quando chegarem:
   - recortar o fundo com a mesma técnica das atuais (o script está
     descrito na seção "Artes do cadastro" mais abaixo);
   - converter pra WebP e substituir `assets/ptk/ptk_*.webp`;
   - **atenção ao enquadramento**: as atuais são 9:16 e o `FundoPTK` corta
     em `cover` alinhado ao topo com `escalaDaArte: .84`. Com arte
     quadrada o PTK vai ficar bem maior — provavelmente precisa baixar a
     escala.
   A arte do **@ (e-mail)** não faz parte do lote novo: continua a 9:16
   atual.
3. **Falta a arte de boas-vindas do cadastro.** É a única das 6 etapas sem
   arte própria do PTK — hoje ela mostra a **logo do canal**
   (`assets/ptk/ptk_logo.webp`) centralizada na área roxa, o que ficou
   bom, mas não é uma arte do personagem. Pra trocar: soltar o arquivo em
   `assets/ptk/` e apontar em `assetDaEtapa` (`lib/view/CriarConta.dart`).
4. **Custom claim de admin no Auth** — a pendência que o usuário pediu
   explicitamente pra fazer "na próxima". É uma Cloud Function que marca o
   admin com um custom claim, e resolve **duas** limitações de uma vez:
   - fechar a escrita no Storage (hoje qualquer logado pode subir arquivo
     na própria pasta `posts_midia/{uid}/`, mesmo sem conseguir publicar);
   - permitir que a remoção em cascata de usuário apague também a conta do
     Firebase Auth e os arquivos órfãos do Storage.
5. **App Store — status não verificado nesta sessão.** O build **1.2.1
   (17)** foi submetido à Apple em 25/ago/2026. Nenhuma sessão desde então
   checou o resultado. Perguntar ao usuário antes de assumir qualquer
   coisa.
6. **Google Play — aviso de nível de API.** O código está certo
   (`compileSdk`/`targetSdk` fixos em **36** desde 27/jul, e as tags
   `v1.2.1+13`, `1.2.1+14` e `v1.2.1+16` já contêm isso). O que o Play
   Console olha é o **artefato publicado** — o aviso só some quando um
   build feito a partir dessa versão for promovido. Ver `CLAUDE.md`.

## Estado do git

- Branch de dev: **`claude/ptk-plays-setup-2q86aw`**. Último merge em
  `main`: **`e256636`** (PR #69). Depois dele a branch acumulou **9
  commits da caixa de entrada do WhatsApp**, ainda **sem PR aberto** — o
  usuário não pediu.
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

- **303 testes** passando (`flutter test`), mais **46** no backend
  (`cd functions && npm test`).
- `flutter analyze`: **0 erros, 0 warnings**. Há uma baseline conhecida de
  ~96 *infos* antigas (nomes de arquivo em PascalCase, `withOpacity`
  deprecated) — não são regressão, não mexer sem pedir.
- Ocasionalmente o analyze mostra **um warning fantasma** em
  `lib/view/Videos.dart:120` na primeira execução após edições; ele some na
  segunda. É pré-existente e não relacionado às mudanças.
- **O container é reciclado sem aviso.** Em 07/set o SDK do Flutter sumiu
  do `/opt` no meio da sessão, junto com o `~/.pub-cache` e a pasta de
  uploads. O repositório não foi afetado. Pra restaurar:
  `cd /opt && git clone --depth 1 -b stable https://github.com/flutter/flutter.git`,
  e `cd functions && npm install` pros testes do backend.

## Deploys — o que já está publicado

Tudo abaixo **já foi deployado** pelo usuário (confirmado por print do
Cloud Shell):

- `firestore.rules` — última publicação em 04/set, com a remoção em
  cascata.
- `storage.rules` — publicado em 01/set (mídia em posts).
- Functions `twitchWebhook`, `kickWebhook`, `verificarYoutubeAoVivo` —
  publicadas em 02/set.

**Há deploy pendente** desde 07/set — a caixa de entrada do WhatsApp (ver
atenção 1). Atenção: `firebase deploy --only storage:rules` **não
funciona** (o CLI interpreta "rules" como nome de target); o comando certo
é `firebase deploy --only storage`.

## O que foi feito nas últimas sessões (28/ago → 07/set)

Resumo; o detalhe de cada decisão está no `ROADMAP.md`, seção por data.

### Painel ADM (`lib/view/PainelAdmin.dart`)

6 abas: **Usuários, Posts, Cargos, Badges, Notificações, WhatsApp**.
Usuários, Posts e WhatsApp são funcionais; as outras explicam o que falta.

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
- **WhatsApp**: a caixa de entrada (07/set). Ver a seção própria mais
  abaixo.

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

#### Artes do cadastro (04–05/set)

As artes eram JPEG com o cenário do desenho junto, e o retângulo delas
denunciava onde a imagem acabava — dava pra ver a emenda com o roxo do
app. Agora são **WebP com transparência**, só o personagem, e quem pinta a
área de cima é o `gradienteDoCenario` do `FundoPTK`.

O recorte foi feito com um script em **PIL puro** (não há numpy neste
ambiente): flood fill a partir da borda **de cima**, comparando cada pixel
com o **vizinho** de onde veio — o degradê do fundo é suave e a
propagação atravessa ele inteiro, enquanto o contorno de alto contraste do
personagem segura. Três armadilhas que custaram tempo, caso precise
refazer:

1. **Semear as laterais come o personagem.** Na arte da selfie o antebraço
   do "V" encosta na borda esquerda; uma semente ali entra no braço e o
   apaga de dentro pra fora. Só a linha de cima é fundo garantido em todas
   as artes.
2. **Isso ilha pedaços de fundo.** O fundo embaixo do antebraço só se liga
   ao resto por fora do quadro. Resolvido com uma segunda leva de
   sementes nas outras bordas, aceita só onde a cor bate com um
   **polinômio de 2º grau ajustado ao fundo já encontrado** — o modelo
   evita semear a calça escura, que também encosta na borda de baixo.
3. **As "estrelinhas" sobram opacas**, porque o flood passa em volta
   delas. Ficando só com o maior componente conectado, elas somem — e de
   quebra somem também os bolsões de fundo fechados, como o triângulo
   entre os dedos do "V".

WebP e não PNG porque o PNG equivalente passava de 1 MB por arte; as WebP
ficaram em ~100 KB, menos que os JPEGs de antes.

A **logo do canal** (`assets/ptk/ptk_logo.webp`) recebeu o mesmo
tratamento, mais um detalhe: o arquivo é um busto quadrado e os ombros
terminavam num corte reto na borda de baixo, que virou uma linha
horizontal visível na tela. O alfa dela **dissolve nos últimos 30%** — é
por isso que o desfoque por cima dela pôde ficar fraco (sigma 3.5). O
`login_logo.png` **continua com fundo** de propósito: lá ele é recortado
num círculo e o quadrado nunca aparece.

#### Regras do título por lado do cume (05/set)

O texto ficava ora à esquerda, ora à direita, seguindo o cume da onda.
Agora fica **sempre à esquerda**, e o cume decide só quanto espaço ele tem:

- **cume à esquerda**: título alto, mantendo a quebra de linha escrita no
  texto (`Como a gente\nte chama?`), subtítulo inteiro;
- **cume à direita**: nasce mais baixo, a quebra sai, a fonte diminui e
  entra a versão resumida do subtítulo.

Dois detalhes que não são óbvios olhando o código:

- `FormaDaOnda.topoDoTexto` mede a curva pela **metade esquerda**, não
  pela metade do cume. Como o texto é sempre à esquerda, medir pelo lado
  do cume deixava a curva passar por cima do título quando o cume caía à
  direita.
- O lado do cume vem da onda **da etapa**, não da onda do momento: com o
  teclado aberto a onda vira a `ondaCheia`, cujo cume é do outro lado, e o
  título se reorganizaria no meio da digitação.

A etapa de **boas-vindas centraliza o texto na faixa branca**, porque não
tem campos — nas outras, centralizar empurraria o título pra cima do
input.

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

### WhatsApp — caixa de entrada (07/set)

Contexto que decide tudo aqui, e que é fácil esquecer: **a Cloud API não
tem endpoint de histórico**. A Meta entrega cada evento uma vez, no
webhook, e não guarda nada pra consultar depois. E um número registrado na
Cloud API **deixa de funcionar no app do WhatsApp** — ele passa a ser
controlado pela API. Somando as duas coisas: o que não for gravado no
momento do webhook não existe em lugar nenhum.

Por isso o `whatsappWebhook` parou de só chamar `logger.info` e passou a
gravar na coleção **`mensagensWhatsapp`**:

- `extrairEventosDoWebhook` (`functions/src/webhook.js`) é função pura que
  percorre `entry[].changes[].value` e trata os dois sabores do envelope:
  `messages` (recebidas) e `statuses` (o que aconteceu com o que saiu).
- **O id do documento é o wamid.** Um status chega depois referenciando a
  mensagem pelo id — usando o wamid como id do documento, ele cai em cima
  do registro certo com `merge`, sem procurar e sem duplicar. A barra do
  base64 vira `_`, o único caractere que o Firestore recusa em id.
- **O 200 sai antes da gravação**, de propósito: a Meta reenvia o evento
  quando não recebe 200 rápido, e reenvio em cima de um erro de escrita
  permanente viraria loop.
- `firestore.rules`: leitura só pra admin, **escrita bloqueada pra todo
  cliente** (admin incluído). Quem escreve é o Admin SDK, que ignora as
  regras — assim ninguém forja uma mensagem que a Meta nunca entregou.

No app: `lib/data/models/MensagemWhatsapp.dart` (modelo +
`agruparEmConversas` + `janelaAbertaEm`),
`lib/data/repositories/WhatsappRepository.dart` (**só leitura**, de
propósito) e a aba WhatsApp do Painel ADM com a lista de conversas e os
balões.

**A regra das 24h** (`janelaAbertaEm`) é da plataforma, não nossa: texto
livre só nas 24h seguintes à última mensagem **da pessoa**; fora disso, só
modelo aprovado pela Meta. O caso que engana: mensagem **nossa** não abre
janela nenhuma, por mais recente que seja.

**O envio ainda não existe** — é a outra metade da aba, e depende do
número de produção e dos modelos aprovados. Quando entrar, deve ser uma
Cloud Function, não escrita direta na coleção, pra manter a garantia de
que nada ali foi inventado pelo app.

#### Coexistence: o que a documentação da Meta diz

O usuário quer um número virtual que funcione como WhatsApp Business **e**
seja usado pelo app. Isso é o recurso de *coexistence* — e ele é
**exclusivo de Solution Partners / Tech Providers** que fazem onboarding
de clientes via Embedded Signup. **Empresa direta não habilita no próprio
número.** Caminhos: (a) usar um BSP que suporte, (b) virar Tech Provider,
ou (c) seguir na Cloud API direta e usar a aba do painel como caixa de
entrada — que foi a escolha.

#### Detalhes que continuam valendo

- `whatsappWebhook` deployada no projeto `ptk-plays`, **região
  `us-central1`** (sem região explícita).
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

1. **Deploy das functions + regras** da caixa de entrada (ver atenção 1) —
   é só o usuário rodar dois comandos no Cloud Shell.
2. **Trocar as 4 artes quadradas** do cadastro, quando os arquivos
   chegarem (ver atenção 2).
3. **Arte de boas-vindas** do cadastro (trivial: 1 arquivo + 1 linha).
4. **Custom claim de admin** no Auth (ver atenção 4).
5. **Etapa 3 — mensagem privada do admin**: coleção `conversas` + regras +
   tela de chat. A opção já existe no menu e avisa que não está pronta.
   Quando existir, entra também na remoção em cascata (o lugar já está
   marcado no código).
6. **Etapa 4 — autoplay do preview na aba Vídeos** (mudo, um player por
   vez, com detector de visibilidade).
7. **Etapa 5 — badges pelo painel**: `badges` é travado contra escrita do
   cliente de propósito, então precisa de Cloud Function.
8. **Etapa 6 — notificações push por cargo.**
9. **Etapa 7 — cargos customizados com permissões**: a mais invasiva,
   reescreve boa parte do `firestore.rules`.
10. **Etapa 8 — envio pelo WhatsApp**: a caixa de entrada (leitura) já
    existe; falta o **envio**, que depende do número de produção e dos
    modelos de mensagem aprovados na Meta.

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
  `flutter`. **Ele pode não estar lá**: o container é reciclado sem aviso
  e em 07/set o SDK sumiu no meio da sessão. Se sumir:
  `cd /opt && git clone --depth 1 -b stable https://github.com/flutter/flutter.git`.
- `flutter analyze`/`build` sujam `analysis_options.yaml` — conferir
  `git status` antes de commitar.
- **Sem `firebase`/`gcloud` CLI** e sem credenciais: nenhum deploy, nenhum
  acesso ao Firestore real, e **nenhum teste de regra do Firestore** (não
  há emulador). Sempre avisar o usuário quando algo depender disso.
- `node`/`npm` disponíveis (`/opt/node22`) — `npm test` roda dentro de
  `functions/` (**46 testes Jest**). O `node_modules/` é gitignored e some
  na reciclagem do container: rodar `npm install` antes.
- **Python com PIL disponível, mas NÃO numpy** — foi assim que as artes
  do PTK tiveram o fundo recortado e viraram WebP. Qualquer script de
  imagem aqui precisa ser PIL puro.
- **Anexos de imagem podem não chegar ao disco.** Em 05 e 07/set o usuário
  mandou 4 artes que apareceram na conversa mas nunca foram salvas em
  `/root/.claude/uploads/`. Sempre conferir se o arquivo existe antes de
  prometer processá-lo.
- Testes de widget: `pumpAndSettle` **trava** em várias telas do app,
  porque o `AuthBackground` anima em loop infinito. Usar `pump()` com
  durações. O Painel ADM ainda precisa de janela larga (as 6 abas não
  cabem em 800x600) e de vários frames (o `StreamBuilder` da lista demora
  a resolver).
- Projeto Firebase `ptk-plays` no plano Blaze; `ptk-ai-studio` idem.
- Pasta local `appstore_screenshots/` (só na máquina do usuário) **não**
  deve ser commitada — decisão explícita.
