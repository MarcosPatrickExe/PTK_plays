# Checkpoint — PTK Plays

Snapshot do estado do projeto em **11/set/2026**, escrito pra retomar o
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
- **`.claude/skills/atualizar-documentacao/`** — a skill que diz o que
  escrever em qual destes arquivos. Rode ela ao terminar uma entrega ou
  antes de um `/clear`.

## ⚠️ O que precisa de atenção AGORA

Só entra aqui o que **bloqueia trabalho** ou o que faria a próxima sessão
quebrar algo por não saber. Cada item diz o que fazer, não só o que está
pendente.

1. **A caixa de entrada do WhatsApp nunca recebeu uma mensagem de
   verdade.**

   *O que é*: em 07/set o `whatsappWebhook` passou a gravar tudo que a
   Meta entrega na coleção `mensagensWhatsapp`, e a aba **WhatsApp** do
   Painel ADM passou a mostrar isso como lista de conversas. Em 08/set o
   usuário rodou os dois deploys (`--only functions` e `--only
   firestore:rules`).

   *Por que ainda é atenção*: deploy feito **não** quer dizer que
   funciona. Falta a metade que não depende de código — a URL do webhook
   precisa estar cadastrada e **inscrita no campo `messages`** no painel
   do app no Meta for Developers, e isso está marcado como **"Não
   confirmado"** desde antes (ver "Detalhes que continuam valendo", na
   seção do WhatsApp). Se essa ponta estiver solta, a aba fica vazia pra
   sempre e nada no código denuncia isso.

   *Como confirmar, em 3 passos*:
   1. Do seu celular, mande uma mensagem qualquer **para o número de
      teste** que a Meta te deu na Etapa 1 (está em WhatsApp → API Setup,
      no painel do app). O seu número precisa estar na lista de
      destinatários de teste do mesmo painel — se não estiver, a Meta
      descarta a mensagem e nada chega.
   2. Abra o app como admin → menu lateral → **Painel ADM** → aba
      **WhatsApp**. A conversa deve aparecer em segundos, com o seu nome
      de perfil e a etiqueta "Resposta livre liberada".
   3. Não apareceu? Rode `firebase functions:log --only whatsappWebhook`.
      É esse comando que separa os dois cenários possíveis.

   *O que cada resultado significa*:
   - **Nenhuma linha nova no log** → a Meta não chamou o webhook. O
     problema está no painel dela: URL não cadastrada, verify token
     diferente do secret `WHATSAPP_VERIFY_TOKEN`, ou o campo `messages`
     sem inscrição. Pegue a URL certa com `firebase functions:list` (é
     função v2, então a URL **não** segue o formato antigo
     `cloudfunctions.net` — não chute).
   - **Log com `assinatura invalida`** → o secret `WHATSAPP_APP_SECRET`
     não bate com a "Chave secreta do app" no Meta.
   - **Log com `Falha ao gravar evento`** → a Meta chamou e a assinatura
     passou; o problema é a escrita no Firestore. A mensagem de erro vem
     junto no log.
   - **Log com `N evento(s) gravado(s)` mas a aba vazia** → gravou, e o
     problema é leitura: confira se a conta que você abriu tem `cargo ==
     'admin'`, porque a regra só libera leitura pra admin.

2. **Falta a arte de boas-vindas do cadastro.** É a única das 6 etapas sem
   arte própria do PTK — hoje ela mostra a **logo do canal**
   (`assets/ptk/ptk_logo.webp`) centralizada na área roxa, o que ficou
   bom, mas não é uma arte do personagem. Pra trocar: soltar o arquivo em
   `assets/ptk/` e apontar em `assetDaEtapa` (`lib/view/CriarConta.dart`).
   Se vier no mesmo estilo quadrado das outras cinco, passar pelo mesmo
   preparo (ver "Artes do cadastro" mais abaixo).
3. **Custom claim de admin no Auth** — a pendência que o usuário pediu
   explicitamente pra fazer "na próxima". É uma Cloud Function que marca o
   admin com um custom claim, e resolve **duas** limitações de uma vez:
   - fechar a escrita no Storage (hoje qualquer logado pode subir arquivo
     na própria pasta `posts_midia/{uid}/`, mesmo sem conseguir publicar);
   - permitir que a remoção em cascata de usuário apague também a conta do
     Firebase Auth e os arquivos órfãos do Storage.
4. **App Store — o build foi REPROVADO. Não reenviar como está.**

   *O que é*: o build submetido em 25/ago/2026 foi reprovado na revisão de
   **27/ago** (Submission `6db9576f-1f55-4ba0-aa62-6d06009a9495`), em dois
   guidelines: **2.1(a)** — o botão "Entrar com a Apple" deu erro no iPad
   Air 11" (M3), iPadOS 26.6 — e **4.2.2**, o app visto como agregador de
   conteúdo de web. O plano completo, com hipóteses ordenadas e o que
   confirma cada uma, está no `ROADMAP.md`, seção "Reprovação da Apple em
   27/ago/2026".

   *Por que ainda bloqueia*: o que fazia cada rodada custar duas semanas e
   render zero informação já foi corrigido (ver abaixo) — até 11/set o app
   colapsava qualquer falha do login com Apple em três frases fixas e só
   registrava o erro real num `debugPrint`, que não existe em release. Mas
   **a causa raiz continua desconhecida**: o código agora consegue dizer
   qual é, e ninguém rodou o app num iPad pra ler o que ele diz. Reenviar
   antes disso é apostar.

   *A parte de código já foi feita em 11/set* (3 commits, cobertos por 16
   testes em `test/auth_error_mapping_test.dart`):
   - **O erro real agora aparece na tela.** `codigoDeDiagnosticoDeLogin`
     (`lib/viewmodels/AuthViewModel.dart`) anexa à mensagem um código curto
     — `apple/unknown`, `auth/operation-not-allowed`,
     `cloud_firestore/permission-denied`, `plataforma/*`, `inesperado/*`.
     É o que faz um print de popup mandado por terceiro virar diagnóstico,
     já que `debugPrint` não existe em release.
   - `mapearErroLoginApple` passou a tratar `FirebaseException`. A escrita
     em `users/{uid}` faz parte do fluxo e, numa conta nova — o caso do
     revisor —, passa pelo `allow create` mais restritivo das regras; uma
     recusa ali virava a mesma frase de um erro da Apple.
   - `operation-not-allowed` não cita mais o Google
     (`lib/utils/AuthErrorTranslator.dart`), e a mensagem do código
     `unknown` oferece a hipótese do aparelho de teste em vez de afirmar
     que o iPad do revisor está sem conta Apple.

   *O que falta, e depende de você — nada disso é checável neste ambiente*:
   1. **Conferir no Firebase Console se o provedor Apple está habilitado**
      (Authentication → Sign-in method). É a checagem mais barata de todas
      e segue **"Não confirmado"** desde 30/jul. Se estiver desligado, o
      app agora mostra `(código: auth/operation-not-allowed)`.
   2. **Reproduzir num iPad**, não num iPhone — toda tentativa até hoje foi
      em iPhone ou emulador, e as duas reprovações vieram de iPad. Anotar o
      código que aparecer: ele diz qual das hipóteses do `ROADMAP.md` é a
      certa, sem precisar de Mac plugado no aparelho.
   3. **Escrever as App Review Notes** com uma **conta de demonstração**
      pronta, pra que o revisor não dependa do Sign in with Apple pra
      avaliar o app — hoje, se o login falha, ele não vê nada e reprova
      também por funcionalidade.

   *Sobre o 4.2.2, o que muda a leitura*: **tudo que faz o app ser nativo
   entrou depois** da submissão — feed, enquetes, mídia, moderação,
   cadastro em etapas e Painel ADM foram mesclados entre 03 e 09/set (PRs
   #63–#73). O revisor não viu nada disso; travado no login, ele julgou o
   app pela tela de login. Corrigir o 2.1(a) é o que destrava o 4.2.2.

   *Conferir também*: a Apple chama o binário de **"1.2.0 (17)"**, mas o
   `pubspec.yaml` diz `1.2.1+17`. Olhar a página do build no App Store
   Connect antes de concluir o que foi revisado.
5. **Google Play — aviso de nível de API.** O código está certo
   (`compileSdk`/`targetSdk` fixos em **36** desde 27/jul, e as tags
   `v1.2.1+13`, `1.2.1+14` e `v1.2.1+16` já contêm isso). O que o Play
   Console olha é o **artefato publicado** — o aviso só some quando um
   build feito a partir dessa versão for promovido. Ver `CLAUDE.md`.

## Estado do git

- Branch de dev: **`claude/ptk-plays-setup-2q86aw`**. Último merge em
  `main`: **`ceaff9e`** (PR #72). Depois dele a branch acumulou **4
  commits do layout desktop do cadastro** (ver seção própria mais
  abaixo), ainda **sem PR aberto** — o usuário não pediu pra abrir/
  mesclar nesta sessão.
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

- **319 testes** passando (`flutter test`), mais **46** no backend
  (`cd functions && npm test`).
- `flutter analyze`: **0 erros e 1 warning**, mais uma baseline conhecida
  de ~96 *infos* antigas (nomes de arquivo em PascalCase, `withOpacity`
  deprecated) — não são regressão, não mexer sem pedir.
- O warning é em **`lib/view/Videos.dart:120`**
  (`body_might_complete_normally_nullable`: o `itemBuilder` tem um `if` sem
  `else`, então retorna `null` implicitamente). Versões anteriores deste
  arquivo o chamavam de "fantasma que some na segunda execução" — **isso
  estava errado**: em 11/set ele apareceu em execuções seguidas. É
  pré-existente e inofensivo na prática (o `itemCount` é o tamanho da
  lista, então o `if` nunca falha), mas é real, e não some sozinho.
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

- `functions` e `firestore.rules` — republicados em **08/set**, com a
  caixa de entrada do WhatsApp.

**Não há deploy pendente no momento.** Atenção: `firebase deploy --only
storage:rules` **não funciona** (o CLI interpreta "rules" como nome de
target); o comando certo é `firebase deploy --only storage`.

## O que foi feito nas últimas sessões (28/ago → 09/set)

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

#### Artes do cadastro (04–07/set)

As artes eram JPEG 9:16 com o cenário do desenho junto, e o retângulo
delas denunciava onde a imagem acabava — dava pra ver a emenda com o roxo
do app. Em 07/set foram substituídas pelas versões **1:1** que o usuário
mandou, e hoje são **WebP com transparência**, só o personagem: quem pinta
a área de cima é o `gradienteDoCenario` do `FundoPTK`.

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
ficaram em 62–80 KB, menos que os JPEGs de antes.

**Depois do recorte vêm mais duas etapas**, e as duas importam se alguma
arte nova entrar:

1. **Recorte pela silhueta** (`getbbox()` no canal alfa). No quadrado
   original quase metade da largura era margem vazia; sem cortar isso o
   PTK aparecia pequeno demais na tela.
2. **Quadro comum às cinco**, ancorado embaixo e **sem reescalar**. As
   artes foram desenhadas na mesma escala, então colar cada recorte num
   quadro único mantém o PTK do mesmo tamanho em todas as etapas —
   recortar cada uma no próprio limite faria ele pular de tamanho na
   transição entre telas. O quadro hoje é 755×1159.

**O enquadramento mudou junto** (`FundoPTK._arte`). O jeito antigo —
`cover` na tela inteira, alinhado ao topo, com `Transform.scale` — foi
calibrado pra 9:16 e cortaria mais de um terço da largura de um quadrado,
justo onde estão o @ e a logo do WhatsApp. Agora é `contain` dentro da
**faixa colorida**, que vai até `fundoDaCurva` (o ponto mais baixo da
onda): daí pra baixo o branco cobre a largura toda e nada desenhado ali
seria visto.

`deslocamentoDaArte` e `escalaDaArte` deram lugar a um único
**`alturaDaArte`** (.90), medido **a partir da onda pra cima**. A folga
entra como recuo no topo, e não encolhendo a caixa: os pés precisam
continuar encostados na onda, senão o PTK flutua com um vão de gradiente
embaixo dele. Os 10% de folga dão ar pro cabelo — e pro celular da selfie,
que sobe mais que a cabeça.

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

#### Layout desktop: cartão de duas colunas (09/set)

Acima de **900px de largura** (`larguraDoCadastroDesktop`) a onda dá
lugar a um cartão centralizado: formulário à esquerda, a arte do PTK num
painel à direita, sem onda nenhuma — o `LayoutBuilder` do `build()` decide
sozinho qual dos dois layouts entra em cena.

O ponto que fez o trabalho valer a pena: **nenhum dos seis textos de
etapa foi duplicado**. `_conteudoDaEtapa` (o switch que já existia,
título/subtítulo/campos de cada etapa) ganhou um parâmetro `desktop`
repassado pra `_EstiloDaEtapa`, que desliga a lógica pensada pra disputar
espaço com a curva (largura parcial, quebra de linha forçada, subtítulo
resumido) — no cartão sobra espaço de sobra, então título sempre grande e
subtítulo inteiro. O painel da arte é `FundoPTK(onda: ondaInteira,
desenharOnda: false)` — a mesma arte e o mesmo gradiente do celular, sem a
curva (ver "Modo cartão no FundoPTK" abaixo). `_SeloDeEtapa` ("PASSO 2 DE
6") faz o papel das bolinhas de progresso, que no celular ficam sobre a
arte — aqui não há arte no painel do formulário pra colar bolinha nenhuma.

Duas armadilhas que não são óbvias olhando o diff, e que custaram uma
rodada de depuração cada:

1. **`MediaQuery.viewInsetsOf` precisa do context certo.** Calcular
   `tecladoAberto` dentro do builder do `LayoutBuilder` (um context mais
   interno, recriado a cada layout) em vez de no `build()` de fora
   quebrava *silenciosamente* o teste do "subtítulo some quando o teclado
   abre" — o rebuild parava de disparar quando a MediaQuery mudava, sem
   erro nenhum acusando o motivo. **Se algo parar de reagir a mudança de
   MediaQuery depois de uma refatoração, suspeitar disso primeiro.**
2. **Um `PageController` não sobrevive a remontar.** O celular anima a
   troca de etapa com um `PageView`/`PageController` de vida longa; o
   desktop troca com `AnimatedSwitcher` (keyed pelo `_etapaAtual`), sem
   controller nenhum. Um `PageController` reaberto depois de um tempo sem
   nenhum `PageView` anexado (a pessoa avança etapas no cartão, depois
   estreita a janela pro celular) volta pro `initialPage` (0) — ele não
   guarda a posição entre uma montagem e outra. Duas proteções: `_paginas
   .hasClients` antes de chamar `animateToPage` (senão lançaria erro
   sem `PageView` nenhum anexado), e um `addPostFrameCallback` em
   `_buildMobile` que corrige a página pro `_indice` certo se detectar
   que remontou fora de sincronia.

**Decisão registrada, não pedida de volta ainda**: a largura de corte
(900px) é um número escolhido, não testado contra dispositivos reais. No
teste visual em 950px (bem no limiar) o título de 34px ocupou 3 linhas no
painel estreito — funcional, mas mais apertado que os 1400px+ testados.
Se o usuário achar apertado numa janela de notebook comum, o ajuste é só
o valor de `larguraDoCadastroDesktop` ou o `tamanhoDoTitulo` do desktop em
`_EstiloDaEtapa`.

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

1. **Confirmar que o webhook está gravando** de verdade (ver atenção 1) —
   é mandar uma mensagem pro número de teste e olhar a aba.
2. **Arte de boas-vindas** do cadastro (trivial: 1 arquivo + 1 linha).
3. **Destravar a reprovação da Apple** (ver atenção 4). A parte de código
   saiu em 11/set; o que resta — provedor Apple no Firebase Console,
   reproduzir num iPad e escrever as App Review Notes — depende do usuário
   e de aparelho físico.
4. **Custom claim de admin** no Auth (ver atenção 3).
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
   existe e está no ar; falta o **envio**, que depende do número de
   produção e dos modelos de mensagem aprovados na Meta.

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
- **Anexos de imagem geralmente NÃO chegam ao disco.** Em 05 e 07/set o
  usuário mandou artes que apareciam na conversa mas nunca foram salvas —
  em 07/set o diretório `/root/.claude/uploads/` nem existia. Sempre
  conferir se o arquivo existe antes de prometer processá-lo.
  **A saída que funcionou**: pedir pro usuário subir os arquivos por
  *Add file → Upload files* na interface web do GitHub, dentro de uma
  pasta que **já exista** (a tela de upload não deixa digitar caminho), e
  então dar `git pull`. Em 07/set ele subiu em `assets/ptk/` com prefixo
  `novo_`, e os originais foram apagados no mesmo PR.
- Testes de widget: `pumpAndSettle` **trava** em várias telas do app,
  porque o `AuthBackground` anima em loop infinito. Usar `pump()` com
  durações. O Painel ADM ainda precisa de janela larga (as 6 abas não
  cabem em 800x600) e de vários frames (o `StreamBuilder` da lista demora
  a resolver).
- Projeto Firebase `ptk-plays` no plano Blaze; `ptk-ai-studio` idem.
- Pasta local `appstore_screenshots/` (só na máquina do usuário) **não**
  deve ser commitada — decisão explícita.
