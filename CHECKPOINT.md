# Checkpoint — PTK Plays

Snapshot do estado do projeto em **15/set/2026** (fim do dia), escrito pra retomar o
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

1. **Quatro entregas foram publicadas em 15/set e NENHUMA rodou contra o
   Firebase de verdade.**

   *O que é*: os dois deploys saíram (função + regras, confirmados pelo
   usuário) e o PR #78 foi mesclado. Curtidas, expulsão de conta banida,
   exclusão de conta completa e pré-teste de e-mail estão **no ar**, e
   todas as quatro dependem de regra do Firestore ou de Cloud Function —
   coisas que **só o servidor avalia**. Nenhum teste deste repositório
   alcança isso: não há harness de `firestore.rules`, e o `AuthRepository`
   cria `FirebaseAuth.instance` no próprio campo.

   *Por que é atenção*: uma regra errada não quebra build nem teste. Ela
   aparece como "sem permissão" na cara de quem usa, e o erro aponta pro
   lugar errado. A primeira sessão que mexer em qualquer uma dessas quatro
   coisas precisa saber que elas **nunca foram exercitadas**.

   *Como confirmar* — cada roteiro já está escrito no fim do arquivo de
   teste correspondente. Em ordem de risco:

   1. **Publicar um post** (feed → botão flutuante). É o teste mais barato
      e o de maior risco: a regra de `create` passou a exigir
      `curtidoPor == []` no lugar de `curtidas == 0`. Se o deploy das
      regras não tiver pego, **publicar para de funcionar** — e a mensagem
      diz "sem permissão", que manda procurar no lugar errado.
   2. **Curtir e descurtir** um post de outra pessoa; conferir que a
      contagem muda e as miniaturas aparecem. Roteiro de 5 pontos no fim de
      `test/curtidas_test.dart`.
   3. **Cadastrar com um e-mail que já existe** — o modal "Esse e-mail já
      tem conta" deve aparecer **na etapa de e-mail**, não no fim.
   4. **Apagar uma conta descartável** de cada tipo (senha, Google, Apple).
      Roteiro de 6 pontos no fim de `test/exclusao_de_conta_test.dart`.
   5. **Banir a própria conta** pelo Painel ADM em outro aparelho, com o
      app aberto. Roteiro de 5 pontos no fim de `test/conta_gate_test.dart`.

   *O que cada falha significa*:
   - **"sem permissão" ao publicar post** → o deploy de `firestore:rules`
     não pegou. Conferir no Console → Firestore → Regras se a versão
     publicada tem `curtidoPor == []`.
   - **curtida não registra, mas post publica** → a regra `podeCurtir()`
     não entrou. Mesma tela do Console.
   - **o modal de e-mail repetido nunca aparece** → a função não respondeu.
     `firebase functions:log --only emailJaCadastrado` diz se ela foi
     chamada. **Isso falha de forma gentil de propósito**: o cadastro segue
     normalmente, só sem o aviso antecipado.
   - **exclusão de conta trava no meio** → provavelmente a listagem de
     `nicknamesParaEmail`, que passou a exigir filtro por `uid`. O desenho
     é falhar deixando a conta **existindo**, então dá pra tentar de novo.

2. **Duas configurações de Console ficaram pendentes, e uma delas é de
   segurança.**

   *O que é*: o pré-teste de e-mail (`emailJaCadastrado`) é, por
   definição, um oráculo de enumeração — alguém pode perguntar "essa
   pessoa tem conta aqui?". Mover a pergunta pro servidor colocou uma
   **porta** nele, não o eliminou.

   *Por que é atenção*:

   - **App Check não está ligado**, e ele é a defesa de verdade: só o app
     de verdade consegue chamar a função. O que existe hoje é um contador
     de 30 perguntas por hora por origem, que quebra um script mas **não
     um atacante distribuído**. Ligar em Console → App Check, registrando
     o app Android/iOS/Web, e depois `enforceAppCheck: true` no `onCall`
     (`functions/index.js`) — **nessa ordem**, senão o app em produção
     para de chamar a função antes de estar registrado.
   - **A coleção `limitesDePreTesteDeEmail` acumula.** Cada documento leva
     um campo `expiraEm` esperando uma **política de TTL** do Firestore,
     que precisa ser criada em Console → Firestore → TTL, apontando pra
     essa coleção e esse campo. Sem ela o campo é decorativo e os
     documentos ficam. São pequenos, mas ficam.

   *Não confirmado*: se o App Check já foi registrado em algum momento
   anterior deste projeto. Nada no repositório indica que sim.

3. **Conta banida agora é EXPULSA pro login — e o login dela continua
   existindo, de propósito.**

   *Correção de uma leitura errada deste arquivo*: a versão anterior
   registrava "conta banida não consegue apagar a própria conta" como
   pendência de 5.1.1(v), como se apagar fosse o certo a fazer. **Não é.**
   O login é o que carrega o `uid` que aponta pro `users/{uid}` com o
   `estadoModeracao`. Apagar o login apagaria a memória do banimento — a
   pessoa criaria outra conta com o mesmo e-mail e entraria limpa.

   *O que estava errado de verdade*: o `ContaGate` desenhava uma tela de
   bloqueio **por cima** do app, com a sessão ainda válida por baixo. Quem
   foi banido continuava dentro do app, só com uma cortina na frente.

   *O que mudou em 14/set*: bloqueio detectado → desloga → `Login` com o
   modal explicando. E **toda entrada** (senha, Google e Apple) lê
   `users/{uid}` logo depois de autenticar e desloga antes de devolver se
   a conta estiver bloqueada.

   *O que sumiu junto*: a preservação de navegação. Antes, uma suspensão
   vencendo com o app aberto devolvia a pessoa exatamente onde estava; hoje
   ela cai no login. Troca aceita: quem está banido não tem pra onde
   navegar mesmo.

   *O que falta validar num aparelho* — o roteiro de 5 passos está no fim
   de `test/conta_gate_test.dart`. O principal: banir a própria conta pelo
   Painel ADM em outro aparelho, com o app aberto, e confirmar que a pessoa
   é jogada pro login com o modal.

   *Ainda vale conferir*: a Apple exige (5.1.1(v)) que **toda** conta possa
   ser apagada de dentro do app, e quem está banido não alcança mais o
   botão de excluir conta (ele mora no `Profile`). Diferente do que este
   arquivo dizia antes, isso **não** se resolve apagando o login no
   banimento — se for necessário atender à regra, o caminho é oferecer a
   exclusão a partir do próprio modal, com a pessoa reautenticando.
   **Não confirmado**: se a Apple de fato exige isso de conta moderada.

4. **A caixa de entrada do WhatsApp nunca recebeu uma mensagem de
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

5. **Falta a arte de boas-vindas do cadastro.** É a única das 6 etapas sem
   arte própria do PTK — hoje ela mostra a **logo do canal**
   (`assets/ptk/ptk_logo.webp`) centralizada na área roxa, o que ficou
   bom, mas não é uma arte do personagem. Pra trocar: soltar o arquivo em
   `assets/ptk/` e apontar em `assetDaEtapa` (`lib/view/CriarConta.dart`).
   Se vier no mesmo estilo quadrado das outras cinco, passar pelo mesmo
   preparo (ver "Artes do cadastro" mais abaixo).
6. **Custom claim de admin no Auth** — a pendência que o usuário pediu
   explicitamente pra fazer "na próxima". É uma Cloud Function que marca o
   admin com um custom claim, e resolve **duas** limitações de uma vez:
   - fechar a escrita no Storage (hoje qualquer logado pode subir arquivo
     na própria pasta `posts_midia/{uid}/`, mesmo sem conseguir publicar);
   - permitir que a remoção em cascata de usuário apague também a conta do
     Firebase Auth e os arquivos órfãos do Storage.
7. **App Store — o build foi REPROVADO. Não reenviar como está.**

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
   1. ~~Conferir no Firebase Console se o provedor Apple está
      habilitado.~~ **CONFIRMADO EM 13/set: ele estava DESLIGADO.** Era a
      hipótese 1, a mais barata da lista, e era a certa. Ver "A causa da
      reprovação" logo abaixo desta lista.
   2. **Reproduzir num iPad**, não num iPhone — toda tentativa até hoje foi
      em iPhone ou emulador, e as duas reprovações vieram de iPad. Anotar o
      código que aparecer: ele diz qual das hipóteses do `ROADMAP.md` é a
      certa, sem precisar de Mac plugado no aparelho. **Ninguém no projeto
      tem aparelho Apple** — o caminho montado pra isso é o Appetize, ver
      "Como rodar o app num iPad sem ter um" logo abaixo.
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
8. **Cadastro social estava quebrado — corrigido em 13/set, falta validar.**

   *O que era*: `CriarConta._criarConta` chamava `cadastrar` nos **dois**
   fluxos. Na conta social isso virava
   `createUserWithEmailAndPassword('', '')` — as etapas de e-mail e senha
   nem são exibidas ali, e a conta **já existia**, criada pelo provedor no
   login. Quem entrasse pela Apple ou pelo Google **ficava preso na última
   etapa do cadastro**, sem forma nenhuma de concluir.

   *Por que importa tanto*: é o caminho exato de um revisor da App Store
   assim que o login com Apple voltar a funcionar. Seria a terceira
   reprovação, logo depois de resolvermos a segunda. O usuário estava a uma
   tela de bater nisso no teste de iPad de 12/set.

   *A correção*: `AuthRepository.completarCadastroSocial`, que preenche o
   perfil em vez de criar conta. **Não validado de ponta a ponta** — exige
   Firebase real. O que dá pra fazer aqui é teste de widget do fluxo de
   etapas, que existe.

9. **Exclusão de conta por login social — CORRIGIDO em 14/set, falta
   validar num aparelho.**

   *O que era*: `AuthRepository.excluirConta` reautenticava sempre com
   `EmailAuthProvider.credential(email: user.email!, password: senha)`.
   Quem entrou pelo Google ou pela Apple **não tem senha** e podia nem ter
   e-mail — a reautenticação sempre falhava, e o diálogo ainda por cima
   exigia preencher um campo de senha que não existia em lugar nenhum. Beco
   sem saída, e reprovação na 5.1.1(v).

   *O que foi feito*: a forma de reautenticar passou a sair de
   `providerData` (`formaParaProvedores`), e o diálogo esconde o campo de
   senha pra conta social. A cascata de exclusão também cresceu: antes
   apagava só `users/{uid}`, agora apaga posts, reserva de nickname, os
   arquivos no Storage e o uid nas enquetes votadas.

   *O que falta, e só dá pra ver num aparelho* — o roteiro de 6 passos está
   escrito no fim de `test/exclusao_de_conta_test.dart`. Em resumo: apagar
   uma conta descartável de cada tipo (senha, Google, Apple) e conferir que
   o nick volta a ficar livre, que os posts somem, e que numa enquete
   votada o total continua igual e o uid sumiu.

   *A parte da Apple que continua pendente*: eles exigem (desde jun/2022)
   revogar o token ao apagar a conta. O código chama
   `revokeTokenWithAuthorizationCode`, mas isso depende da seção
   **"Configuração do fluxo de código OAuth"** (Team ID, Key ID e chave
   .p8) no provedor Apple do Firebase Console, que **continua vazia**. Sem
   ela a revogação falha, e a exclusão segue assim mesmo — de propósito:
   travar a exclusão da conta por causa da revogação seria trocar um
   problema por um pior. O efeito prático é o PTK Plays continuar listado
   em Ajustes → Apple ID → Login com a Apple.

   *E o que nenhum código do app alcança*: as mensagens em
   `mensagensWhatsapp` são indexadas por telefone e só o webhook escreve
   nelas (`write: if false` vale pra todo mundo, admin incluído). Limpá-las
   ao apagar a conta precisa de uma Cloud Function com o Admin SDK, que não
   existe. **Isso é dado pessoal** (telefone e nome de perfil) sobrevivendo
   à exclusão — vale resolver junto com o custom claim de admin (atenção 6).

10. **Google Play — aviso de nível de API.** O código está certo
   (`compileSdk`/`targetSdk` fixos em **36** desde 27/jul, e as tags
   `v1.2.1+13`, `1.2.1+14` e `v1.2.1+16` já contêm isso). O que o Play
   Console olha é o **artefato publicado** — o aviso só some quando um
   build feito a partir dessa versão for promovido. Ver `CLAUDE.md`.

## O que está esperando resposta do usuário

Registrado aqui porque o `/clear` apaga a conversa, mas não apaga o fato de
que estas decisões estão paradas. **Não decidir nada disso sozinho** —
onde há recomendação minha, ela está marcada como recomendação.

### Decisões de produto

1. **Badges contando de verdade — e por qual caminho.** O usuário já
   aprovou a feature ("vamos fazer as Badges contarem de verdade"), então
   isto não é a pergunta; a pergunta é **como**. A tela de Conquistas hoje
   mostra três metas inalcançáveis:

   | Badge | Promete | Estado |
   |---|---|---|
   | Comentarista | "Comente em 10 posts ou vídeos" | não há comentário no app |
   | Popular | "Receba 50 curtidas nos seus comentários" | **destravada pelas curtidas** — basta mudar a meta pra curtidas nos POSTS |
   | Presença VIP | "Clique pra assistir 5 lives" | o app já abre o link; falta contar o toque |

   O obstáculo é o mesmo pras três: `contadores` é travado contra escrita
   do cliente no `firestore.rules`. **Duas saídas, e elas não são
   equivalentes:**

   - **Exceção estreita na regra** (só o próprio uid, só `+1`, só o
     contador que muda). Sai hoje, sem deploy de função. O custo é que o
     cliente passa a poder inflar o próprio contador — não há como a regra
     saber se o clique na live aconteceu de verdade.
   - **Cloud Function** disparada por gatilho (`onDocumentUpdated` no post
     pra curtida, uma callable pro clique na live). Não dá pra falsificar,
     e custa um deploy e latência.

   **Minha recomendação**: Function pra "Popular" (o contador tem valor
   social e mentir nele estraga a badge pra todo mundo) e exceção na regra
   pra "Presença VIP" (ninguém ganha nada inflando quantas lives assistiu).
   Mas é recomendação, não decisão.

2. **Comentários — fazer ou adiar.** Discutido em 15/set e **não
   decidido**. O ponto que decide: comentário arrasta o **guideline 1.2**
   junto — conteúdo gerado por usuário exige filtro, denúncia, bloqueio de
   usuário e um caminho pra agir em até 24h. Não é "adicionar um campo de
   texto", é um pacote. Fazer sem isso troca um risco de reprovação por
   outro.

3. **Nome da badge de compartilhar.** Ideia do usuário: ganhar uma badge ao
   compartilhar o app com pelo menos uma pessoa. Ele sugeriu "O primeiro
   compartilhador"; apontei que soa como se só a primeira pessoa ganhasse,
   e sugeri algo que diga o papel — **"Espalhador"** ou **"Trouxe gente"**.
   Sem resposta. Depende do compartilhar existir (hoje está na barra do
   feed como "Em breve").

4. **"Regras de uso" ou "termos de uso"** no modal de conta banida. O
   usuário escreveu "termos de uso"; usei **"regras de uso"** porque o
   repositório tem um `REGRAS_DA_COMUNIDADE.md` e me pareceu melhor a
   mensagem apontar pro documento que existe. Flaguei e não houve resposta.
   Trocar é **uma linha em cada catálogo** (`bloqueioBanidaTexto` e
   `bloqueioSuspensaTexto`).

5. **Conta banida e a exclusão de conta (5.1.1(v)).** A Apple exige que
   **toda** conta possa ser apagada de dentro do app, e quem está banido
   não alcança mais o botão (ele mora no `Profile`, e o banido cai no
   login). O caminho seria oferecer a exclusão a partir do próprio modal de
   banimento. **Não confirmado**: se a Apple de fato exige isso de conta
   moderada. Ver atenção 3.

6. **`lib/view/Cadastro.dart` é código morto.** O `Login` navega pro
   `CriarConta` em etapas; o único caminho que ainda chega no `Cadastro` é
   a rota `/cadastro` do arranque de screenshots. Ele foi traduzido por
   completude em 14/set, mas é **candidato a exclusão**. Sem resposta.

### Ações que só o usuário pode fazer

7. **Chave APNs** — o único bloqueio real do push. Adiado por decisão dele
   em 14/set ("vamos deixar para a próxima etapa"). Gerar no Apple
   Developer Portal e carregar no Firebase Console.

8. **App Check e a política de TTL** — ver atenção 2. O App Check é o que
   protege o pré-teste de e-mail de verdade.

9. **App Review Notes com conta de demonstração** — continua sendo a coisa
   de maior alavancagem da lista inteira, e a mais barata. Sem ela, um
   revisor que esbarre no login não vê nada do app e reprova por
   funcionalidade também.

10. **Reproduzir o login com Apple num iPad** — ninguém no projeto tem
    aparelho Apple; o caminho montado é o Appetize (ver seção própria, com
    o limite de 3 minutos por sessão).

## Cadastro reativo e WhatsApp opcional (13/set)

Três mudanças no cadastro, sem PR aberto ainda.

**O botão "Avançar" aparece e some** conforme a etapa passa a ter o mínimo
preenchido, em vez de ficar visível e cinza. Virou **regra permanente** no
`CLAUDE.md` ("a interface reage enquanto a pessoa digita"), valendo pro app
inteiro a pedido do usuário. A parte que não se deduz do código: o limiar de
**aparecer** é de propósito mais frouxo que o de **validar** (nick aparece
na 2ª letra, libera na 3ª), e é essa folga que faz o mecanismo funcionar.

**WhatsApp virou opcional**, com botão **"Pular"** discreto ao lado do
avançar. Era risco de reprovação 5.1.1(ii). Duas coisas que desfazem o medo
de perder contato com o usuário, e que precisam estar escritas porque a
leitura fácil é a contrária:
- **o relay `@privaterelay.appleid.com` encaminha de verdade** — quem
  esconde o e-mail na Apple continua alcançável;
- **push** (pendência 4) resolve o aviso de live sem pedir dado nenhum.

**Bug real achado pelo teste novo**: a barra de botões **estourava 42px**
num aparelho de **420 de largura** quando os três controles apareciam juntos
("Voltar" + "Pular" + "Criar conta", o rótulo mais largo do fluxo). Isso é
faixa de celular comum, não caso extremo. O "Voltar" passou a ceder espaço.

**Armadilha de teste que custou uma rodada**: `AnimatedSwitcher` só **remove**
o filho que sai no frame **seguinte** ao fim da animação. Um `pump(duração)`
sozinho ainda encontra o widget antigo — o teste falha por timing, não por
comportamento. O helper `_esperarBotao` em `test/criar_conta_test.dart` faz
`pump()` antes do `pump(duração)`. E o tap num avatar tem que sair do
`SeletorAvatarPreset`, não de `find.byType(GestureDetector)` solto: a etapa
da foto tem outros `GestureDetector` antes dos avatares na árvore.

### Correções visuais da mesma leva

- **Degradê sobre a logo** (`FundoPTK`): duas camadas escureciam a logo e as
  duas abriam em 45% da faixa — somadas cobriam o rosto. O problema real que
  elas resolvem é só a borda reta de baixo, que **o alfa do próprio arquivo
  já dissolve** desde 07/set; eram cinto e suspensório de quando o alfa não
  existia. Agora abrem perto da onda (78% e 70%), com opacidade máxima
  `0x66` em vez de `0x8C`.
- **Avatares do seletor** viraram círculos de verdade e ganharam teto de
  **84px**. Duas notas: `BoxShape.circle` sozinho vira **elipse**, porque a
  célula da grade não é quadrada (`childAspectRatio` 0.82 menos o rótulo) —
  precisa de `Center` + `AspectRatio(1)`; e o tamanho não era um valor
  errado, era a **ausência** de um: a grade divide a largura disponível,
  então na coluna larga do iPad cada avatar esticava junto.
- **"Agora crie uma senha"** numa linha só, pro campo de confirmar caber.

### Hide My Email da Apple

A etapa de e-mail sumia pra toda conta social. Certo pro Google e pro
"Share My Email", errado pro **"Hide My Email"**: o que chega é um relay que
encaminha mas não serve pra contato nem pra reconhecer a pessoa.
`precisaPedirEmail` (`lib/view/CriarConta.dart`) decide — a etapa de
**senha** continua fora nos dois casos, só a de e-mail volta.

**Decisão registrada**: o e-mail informado vai pro **Firestore**, e o
Firebase Auth **continua com o relay**. Trocar o e-mail do Auth exigiria
verificação e mexeria no vínculo com a Apple, que é a identidade da conta —
risco alto pra ganho baixo.

## Correções do cadastro e o cenário das artes de volta (15/set)

### As artes voltaram a ter o fundo delas — e o motivo de eu ter tirado não se sustentava

O usuário perguntou por que eu tinha removido o fundo das artes que ele
subiu em PNG quadrado. A resposta honesta é que o recorte resolvia um
problema **de enquadramento**, e não da arte: com `contain`, o quadrado era
encaixado pela largura e sobrava gradiente do app acima dele, com uma
emenda horizontal visível no meio da tela.

Trocando pra **`cover`**, a emenda some sem custo nenhum — o quadrado cobre
a faixa colorida de ponta a ponta e o cenário da arte **vira** o fundo. O
corte do `cover` cai nas laterais, onde só há cenário; numa tela de celular
a conta dá corte zero na vertical.

Os originais estavam no histórico (`6702196^` e `15091cd^`) e voltaram de
lá, só convertidos pra WebP. **Ficaram menores** que os recortes: 55–73 KB
contra 62–82 KB — degradê comprime melhor que transparência, e o canal alfa
sumiu.

**Se alguém for mexer no enquadramento de novo**: `contain` traz a emenda
de volta, e é ela que gera a tentação de recortar o fundo. Os dois andam
juntos.

### O PTK some inteiro com o teclado aberto

A `ondaCheia` cobre quase tudo mas deixa uma faixa colorida de ~10% no
alto, e sobrava ali um PTK espremido — pequeno demais pra se reconhecer e
grande o bastante pra disputar atenção com o campo. Agora o `asset` vira
`null` quando o teclado abre, e o `AnimatedSwitcher` do `FundoPTK` faz o
cross-fade de saída.

### Só o título é estreitado; o subtítulo usa a linha inteira

O cabeçalho inteiro ia pra 70% da largura quando o cume da onda fica à
esquerda. O **título** precisa disso (ele sobe até o cume e esbarraria na
curva do outro lado); o **subtítulo** vem abaixo, onde a curva já desceu, e
herdava a restrição à toa. O sintoma era a etapa do WhatsApp: quatro linhas
curtas com metade da largura vazia ao lado.

### E-mail repetido para na etapa de e-mail

Antes o duplicado só aparecia **no fim do cadastro**, quando o Firebase
recusava o `createUserWithEmailAndPassword` — depois de a pessoa já ter
escolhido nick, senha, foto e WhatsApp.

**Não dá pra usar `fetchSignInMethodsForEmail`**: foi descontinuado
justamente por ser um oráculo de enumeração e, com a proteção contra
enumeração ligada no Console (padrão em projeto novo), devolve lista vazia
sempre — um pré-teste em cima dele mentiria dizendo que todo e-mail está
livre. A consulta vai em `nicknamesParaEmail`, pelo campo `email`.

**Três coisas pra saber antes de mexer nisso:**

1. **A consulta acontece no toque em "Avançar"**, e não a cada tecla. Por
   letra seriam dezenas de consultas por cadastro, e um oráculo bem mais
   aberto.
2. **O e-mail é normalizado** (minúsculas, sem espaço) na escrita e na
   leitura. A consulta do Firestore é sensível a maiúscula e não tem como
   pedir o contrário — sem normalizar, "Fulano@Gmail.com" e
   "fulano@gmail.com" passariam como endereços diferentes.
   **Não confirmado**: se há linhas antigas em `nicknamesParaEmail` com
   e-mail em caixa mista. Se houver, elas escapam do pré-teste até serem
   reescritas.
3. **Buraco conhecido**: quem entrou pelo Google/Apple e abandonou antes da
   etapa do nick não tem reserva, e passa por livre. O Firebase ainda barra
   no fim.

### A exposição de `nicknamesParaEmail` foi fechada

`allow read: if true` cobria **`get` e `list`**. Na prática, qualquer
pessoa — logada ou não — conseguia baixar a coleção inteira: todos os
nicknames, e-mails e uids do app.

Agora são duas regras separadas:

```
allow get: if true;
allow list: if ehAdmin() || (estaLogado() && resource.data.uid == request.auth.uid);
```

O `get` aberto continua porque o login por nickname resolve nick → e-mail
**antes** de haver sessão, e pra isso basta ler um documento pelo id.

As duas listagens que sobraram são as legítimas: a exclusão da própria
conta e a remoção em cascata do Painel ADM. A condição em
`resource.data.uid` **obriga a consulta a filtrar por uid** — sem o filtro,
algum documento devolvido reprova a regra e a consulta inteira é recusada.

**Isso só ficou possível porque o pré-teste de e-mail saiu do cliente.**
Enquanto ele era uma consulta do app, os dois não conviviam.

## Pré-teste de e-mail: a Cloud Function (15/set)

`emailJaCadastrado`, um **callable** em `southamerica-east1`. Recebe um
e-mail, devolve `{existe: bool}`. Só isso.

### Por que não dava pra fazer no cliente

Perguntar "esse e-mail tem conta?" é um oráculo de enumeração por
definição. A primeira versão consultava `nicknamesParaEmail` direto do app,
e pra isso aquela coleção precisava ficar listável por qualquer um — e ela
guarda o e-mail de todo mundo. A função devolve só um booleano, a coleção
voltou a ser fechada, e o servidor consegue contar quantas perguntas cada
origem faz.

O `fetchSignInMethodsForEmail` do cliente **não serve**: foi descontinuado
pelo mesmo motivo, e com a proteção contra enumeração ligada no Console
(padrão em projeto novo) ele devolve lista vazia sempre — um pré-teste em
cima dele mentiria dizendo que todo e-mail está livre.

### O que a função enxerga a mais

`getUserByEmail` do Admin SDK cobre **toda** conta do Auth, inclusive a de
quem entrou pelo Google/Apple e abandonou o cadastro antes de reservar o
nick — caso que a consulta ao Firestore deixava passar por livre.

### Decisões que uma sessão nova não deve desfazer

- **A região é declarada NA função**, nunca por `setGlobalOptions`. O
  global moveria o `whatsappWebhook` de `us-central1` e quebraria a URL
  cadastrada na Meta. A mesma região está escrita no cliente
  (`AuthRepository.emailJaCadastrado`) — errar lá não dá erro de
  compilação, dá "not found" em execução, que parece função inexistente.
- **Falha de infraestrutura responde "não existe"**, não erro. O pré-teste
  é uma gentileza pra avisar cedo; quem barra o duplicado de verdade é o
  Auth. Isso vale até pro `resource-exhausted` do limite.
- **O identificador do limite é um hash do IP**, não o IP. Guardar uma
  lista de IPs pra contar requisição seria criar um registro de quem tentou
  se cadastrar e quando.
- **A janela de tempo entra na chave do documento**, não num campo. É o que
  dispensa transação pra zerar o contador quando o relógio vira.

### Duas coisas que ficaram pendentes

1. **App Check não está ligado**, e ele é a defesa de verdade — só o app
   de verdade consegue chamar a função. O limite de 30 perguntas por hora
   por origem é o que existe enquanto isso; ele quebra um script, mas não
   um atacante distribuído.
2. **A coleção `limitesDePreTesteDeEmail` acumula.** Cada documento carrega
   `expiraEm` pra uma **política de TTL do Firestore** varrer sozinha, e
   essa política precisa ser criada no Console (Firestore → TTL). Sem ela,
   o campo é só informativo e os documentos ficam — são pequenos, mas
   ficam.

## Curtidas no feed (15/set)

O que motivou: a conversa sobre o que um avaliador de loja vê ao entrar. A
conclusão foi que **feed vazio não reprova, mas app que promete o que não
faz sim** — e a tela de Conquistas listava três metas inalcançáveis.

As curtidas foram o primeiro passo, escolhido por ser a menor feature que
deixa o feed visivelmente vivo **sem trazer carga de moderação**: ninguém
escreve texto ao curtir.

### O pedido, e o que ele tinha de específico

> "quando o avaliador entrar no app, ele vai poder ver quantas pessoas já
> interagiram com as postagem através da miniatura das fotos delas abaixo
> do botão de curtir"

O alvo não era a curtida: era **a miniatura**. Um número diz que houve
interação; rostos dizem que houve gente — e isso o avaliador enxerga em
cinco segundos, sem criar conta.

O modelo é o Instagram: barra de ações no pé do card com curtir, comentar e
compartilhar. **Comentar e compartilhar entram desabilitados**, com "Em
breve", pra o lugar deles no layout já ficar reservado.

### Decisões que uma sessão nova não deve desfazer

- **Não existe contador `curtidas` separado.** A contagem é
  `curtidoPor.length`. Um número guardado ao lado seria uma segunda fonte
  de verdade pro mesmo fato, e divergiria do que as miniaturas mostram.
- **Os perfis das miniaturas são LIDOS**, não copiados pro post. Guardar
  nick e foto congelados evitaria as leituras, mas o feed mostraria pra
  sempre o retrato antigo de quem trocou de avatar. O custo fica contido
  pelo limite de 3 na tela e por um cache de processo no
  `PostRepository`.
- **Sem transação.** `arrayUnion`/`arrayRemove` resolvem a concorrência no
  servidor; uma transação custaria uma ida a mais no gesto que mais precisa
  parecer instantâneo.
- **Curtida que funciona não gera toast.** O coração mudando de cor já é a
  confirmação. Só o erro fala.
- **Vale em todo tipo de post**, inclusive na enquete — que é a que mais
  fácil ficaria de fora, por já ter interação própria.

### A regra, e a armadilha que ela esconde

`podeCurtir()` é escrita nos dois sentidos porque **rules não tem subtração
de lista**: entrar é a lista virar exatamente a antiga mais o meu uid; sair
é o meu uid não estar mais lá, nada novo ter entrado, e a lista ter
encolhido em exatamente um.

O `hasOnly(['curtidoPor'])` é o que impede a curtida de virar carona pra
outra coisa. E conta bloqueada não curte — a regra checa `contaBloqueada()`,
igual ao voto.

### O que falta, e é o próximo passo

**Fazer as badges contarem de verdade** (pedido do usuário no mesmo
recado). Hoje a tela de Conquistas mostra três metas que ninguém alcança:

| Badge | Promete | Estado |
|---|---|---|
| Comentarista | "Comente em 10 posts ou vídeos" | não há comentário no app |
| Popular | "Receba 50 curtidas nos seus comentários" | **agora dá pra contar** — mudando a meta pra curtidas nos POSTS |
| Presença VIP | "Clique pra assistir 5 lives" | o app já abre o link; falta contar o toque |

O obstáculo é o mesmo pras três: `contadores` é travado contra escrita do
cliente no `firestore.rules`, e não existe Cloud Function que os
incremente. Ou se abre uma exceção na regra (só o próprio uid, só
incremento de 1), ou entra uma Function.

**Ideia registrada, ainda não pedida**: uma badge de "primeiro
compartilhador", ganha ao compartilhar o app com pelo menos uma pessoa.
Depende do compartilhar existir.

## Banimento: expulsa, não cobre (14/set)

Pedido do usuário, corrigindo o que eu tinha anotado: *"uma pessoa banida
jamais deve ficar dentro do app como se estivesse logada. Ela deve ser
expulsa para a tela de login. Pra quando ela tentar entrar de novo,
aparecer um modal avisando que ela violou os termos de uso."*

**O login não é apagado, e é isso que faz o mecanismo funcionar.** Ele
carrega o `uid` que aponta pro `users/{uid}` com o `estadoModeracao` — é a
memória do banimento. Apagar o login deixaria a pessoa criar outra conta com
o mesmo e-mail e entrar limpa.

**Três caminhos, todos cobertos:**

| Situação | Onde é barrado |
|---|---|
| Banido com o app aberto | `ContaGate` → `logout()` → `Login` com o modal |
| Tenta entrar com senha | `AuthRepository.login` → desloga e devolve o bloqueio |
| Tenta entrar pelo Google/Apple | `_sincronizarUsuarioNoFirestore` → idem |

O caminho social é o que mais fácil se esquece, e é a porta dos fundos mais
óbvia do banimento.

**A ordem dentro do repositório importa**: a regra do Firestore só libera
ler `users/{uid}` pra quem está logado. A leitura acontece com a sessão
ainda de pé, e o `signOut()` vem logo depois.

**O modal não é `mostrarErroCustom`**, e a distinção é deliberada: não houve
erro nenhum. A senha estava certa, a conta existe, e a entrada foi
**recusada**. Chamar isso de "Ops!" faria parecer falha do app e convidaria
a pessoa a tentar de novo.

**O que se perdeu**: a preservação de navegação. A versão antiga cobria o
app e, quando a suspensão vencia com o app aberto, a pessoa voltava
exatamente pro lugar onde estava. Hoje ela cai no login. Foi troca
consciente — o preço de manter aquilo era uma sessão válida na mão de quem
acabou de ser banido.

**Onde vive**: `bloqueioDe` e `BloqueioDaConta`
(`lib/data/models/BloqueioDaConta.dart`), `ContaGate`
(`lib/components/ContaGate.dart`), `mostrarModalContaBloqueada`
(`lib/view/ContaBloqueada.dart`). O `ContaBloqueadaView` e o `GateDeConta`
**não existem mais** — se algum código antigo os procurar, é daqui que eles
saíram.

## Duas línguas, o app inteiro (14/set)

O app fala **português do Brasil e inglês dos EUA**, e escolhe sozinho pela
preferência do aparelho. O motivo que o usuário deu não foi alcance de
público: **o revisor da App Store e o da Play Store leem em inglês**, e
duas reprovações já custaram semanas adivinhando o que o revisor viu na
tela.

O corte foi **nenhum**: ele pediu explicitamente o app inteiro de uma vez,
e não em levas. Foram ~300 frases em 40 arquivos.

### Onde isso mora

- `lib/i18n/Textos.dart` — o contrato (classe abstrata);
- `lib/i18n/TextosPtBr.dart` e `TextosEnUs.dart` — as duas línguas;
- `lib/i18n/Idioma.dart` — o enum, a detecção e o `IdiomaController`.

No código, sempre `textos.algumaCoisa`. A regra permanente, com o porquê de
cada decisão e as armadilhas, está no **`CLAUDE.md`**.

### O que uma sessão nova precisa saber pra não quebrar isto

1. **A detecção mora no `main()`**, não no catálogo. Se o global
   consultasse a plataforma sozinho, todo `flutter test` viraria inglês (o
   ambiente de teste responde en-US) e centenas de asserts de texto
   quebrariam de uma vez. O padrão é português; é o `main()` que troca.
2. **O último teste de `test/i18n_test.dart` varre `lib/`** atrás de
   literal com acento fora do catálogo. É ele que impede a regra de virar
   boa intenção. A lista de exceções ali é nominal — **acrescentar arquivo
   naquela lista precisa de justificativa**, não é o jeito normal de fazer
   o teste passar.
3. **`const` congela a frase na compilação.** Vários lugares tiveram que
   deixar de ser `const`: itens da barra de navegação, catálogo de
   avatares, catálogo de badges, mapa de selos do painel.
4. **Uma tela que só lê `textos.` não redesenha sozinha** quando o idioma
   muda. Quem precisa reagir na hora observa o `IdiomaController`, do mesmo
   jeito que já observa o `ThemeController` — hoje só `Configuracoes` e
   `PoliticaPrivacidadeWeb` precisam disso.

### Duas coisas que mudaram de comportamento junto

- **A política de privacidade segue o idioma do app**, não mais a região do
  aparelho. A regra antiga era `locale.countryCode == 'BR'` e errava dos
  dois lados: quem configurava só `pt`, sem região, lia a política em
  inglês com o app inteiro em português. Português de Portugal passou a ler
  em português, o que antes não acontecia — mudança consciente.
- **`?lang=en` no arranque de screenshots** (`lib/main_screenshots.dart`),
  igual ao `?theme=dark` que já existia. A ficha da loja é **por idioma**:
  a listagem em inglês precisa de capturas em inglês.

### Sobre a dúvida do idioma na web

O usuário perguntou se, na web, isso exigiria pedir **permissão de
localização**. **Não exige, e não tem relação.** O Flutter web preenche
`locales` a partir do `navigator.languages`, que é a lista de idiomas
configurada no próprio navegador. Idioma é uma preferência declarada; onde
a pessoa está é outro assunto, e o app não precisa saber.

## Exclusão de conta: qualquer login, e apagando tudo (14/set)

Pedido do usuário em 14/set: "todas as contas criadas dentro do app devem
fornecer a possibilidade de serem apagadas pelo próprio usuário", com
perfil, badges, cargo, posts, comentários e curtidas **apagados**, e
redirecionamento pro login.

**O que estava quebrado**: `excluirConta` reautenticava sempre com senha, e
apagava **só** `users/{uid}`. Detalhes e o que falta validar: atenção 9.

**A ordem da exclusão não é arbitrária** — é a parte que mais fácil se
quebra numa refatoração futura:

- a conta do **Auth cai por último**, porque as regras só autorizam apagar
  o que é "meu" enquanto `request.auth` existe. Apagando o login primeiro,
  todo o resto vira lixo que só o Admin SDK alcança;
- `users/{uid}` é o **último documento** do Firestore a sair, porque a
  regra de apagar post faz `get()` nele pra descobrir o cargo de quem
  chama. Sem o documento, a regra não avalia e a exclusão dos próprios
  posts é negada.

Falhar no meio deixa a conta **existindo**, e não meio apagada — de
propósito: dá pra tentar de novo.

**Comentários e curtidas não aparecem na cascata porque não existem como
documento**: hoje são só contadores dentro do post (`comentariosCount`,
`curtidas`). Quando virarem coleção, entram aqui.

**Nas enquetes, só o uid sai; a contagem fica.** O que identifica a pessoa
é o uid em `votantes`/`votosPorUsuario`; o total de votos é número agregado
que não aponta pra ninguém. Tirar o nome e deixar o número é o que
anonimizar significa — e liberar `opcoes` naquela regra daria ao cliente
uma porta pra reescrever placar de enquete alheia.

## Cadastro: o campo de confirmar senha saiu (14/set)

O usuário perguntou em 13/set que motivo plausível o campo tinha pra
existir, e a resposta honesta foi que não tinha um bom. Ele decidiu
remover.

O campo nasceu num mundo onde senha era sempre mascarada: digitar errado só
aparecia no próximo login, e repetir era a única defesa. Aqui o campo tem o
olho — dá pra ler o que foi digitado antes de seguir.

**O "Confirme o e-mail" continua**, e a assimetria é o ponto: e-mail errado
não tem conserto de dentro do app (a recuperação de senha vai pro endereço
errado e a conta fica órfã), senha errada tem — é só redefinir, justamente
pelo e-mail.

Junto saiu `validarConfirmacaoSenha`, e no lugar dela ficou um comentário
explicando a assimetria — pra ninguém recriá-la por simetria com o
`validarConfirmacaoEmail`, que continua ali do lado.

**O texto da etapa do WhatsApp mudou junto**, respondendo à outra pergunta
parada: o número é pedido pra **dar outra forma de entrar, confirmar troca
de senha e avisar quando o canal abre ao vivo**. Enquanto era obrigatório,
o texto não precisava convencer ninguém; opcional, precisa.

## Revisão geral das mensagens de erro (12/set)

Etapa 1 pedida pelo usuário depois do popup genérico do revisor da Apple:
varrer o app inteiro atrás de mensagem de erro sem identificação da causa.
A regra que saiu disso está no `CLAUDE.md` ("toda falha diz de onde veio");
o utilitário é `lib/utils/DiagnosticoDeErro.dart`.

**11 arquivos alterados.** O que a varredura encontrou, em ordem de
gravidade — e os dois primeiros não eram sobre mensagem genérica, eram
bugs:

1. **Seis métodos de autenticação travavam a tela.** `cadastrar`, `login`,
   `excluirConta`, `alterarSenha`, `atualizarPerfil` e o envio do e-mail de
   recuperação capturavam **só** `FirebaseAuthException`. Qualquer outra
   falha escapava: a Future estourava, o `setState` que desliga o loading
   nunca rodava, e o botão ficava preso em "carregando" pra sempre. É o
   mesmo bug já corrigido no login social meses atrás, que seguia de pé no
   resto da tela. **O caso que mais importa**: `cadastrar` grava a reserva
   do nickname no Firestore, e uma regra recusando essa escrita é
   `FirebaseException` — ou seja, cadastro de conta nova barrado por regra
   travava sem dizer nada. É o caminho de um revisor da App Store.
2. **Dois `catch (_)` engoliam o erro inteiro.** No `ModalCropFoto` o botão
   "Salvar" voltava ao normal e nada acontecia — sem mensagem, sem log, sem
   fechar o modal. No `VideoPost`, CORS na Web, arquivo corrompido e rede
   fora mostravam o mesmo aviso. **Erro sem mensagem nenhuma é pior que
   erro genérico**: ele nunca chega a ser reportado.
3. **Erros de Firestore e Storage caíam no "Algo deu errado"**, porque
   passavam pelo `traduzirErroDeAuth`, que não conhece nenhum código deles.
   Os dois casos mais comuns do projeto — regra ainda não publicada, e
   internet fora — eram justamente os invisíveis. Agora há
   `traduzirErroDeServico`.
4. O resto: live e vídeo (o `launchUrl` estava fora do try/catch, e o
   `canLaunchUrl` devolvendo false era indistinguível de falha real),
   câmera do cadastro, upload de mídia, publicação no feed, e as duas
   mensagens do Painel ADM que interpolavam o `$e` cru.

**O que ficou de fora, de propósito**: as validações de formulário
(`Login.dart`, `Cadastro.dart`, `CriarConta.dart`, `NovoPost.dart`). Não
houve exceção nelas — não há causa a diagnosticar, e o código seria ruído
sobre uma mensagem que a pessoa já sabe como resolver.

**Ainda não validado em aparelho**: nada disto foi visto rodando num iOS
real ou simulado. A cobertura é de teste unitário
(`test/diagnostico_de_erro_test.dart`, 10 testes).

## Sessão de teste no Appetize: 3 minutos, 30/mês (13/set)

O plano gratuito do Appetize dá **30 minutos por mês**, que reiniciam no dia
1º, e cada sessão dura **no máximo 3 minutos**. Em 13/set já restavam ~20.

**A consequência prática, e é ela que muda como trabalhamos**: a sessão é
curta demais pra explorar. Toda pergunta visual que puder ser respondida por
teste de widget nas medidas do aparelho **tem que ser respondida aqui**, no
sandbox, de graça e em segundos — o Appetize fica só pro que exige iOS de
verdade (Sign in with Apple, câmera, permissões nativas).

Foi assim que saíram, sem gastar minuto nenhum: a medida do cartão de login
no iPad, a troca de layout ao girar o aparelho, e o diâmetro dos avatares.

**Perde-se o login da Apple a cada sessão.** O aparelho é reiniciado entre
sessões (por isso o login some), então é preciso entrar de novo em Ajustes →
Apple Account antes de testar o app. Reserve ~1 dos 3 minutos pra isso, ou
faça o login numa sessão e o teste na seguinte.

**Roteiro pra não desperdiçar sessão** — decidir o que olhar ANTES de
apertar Start, porque descobrir o que testar dentro dos 3 minutos é o
desperdício principal:

1. Anotar as 2–3 perguntas da sessão, em ordem de valor.
2. Conferir se alguma delas é respondível por teste de widget. Se for, não
   gastar sessão com ela.
3. Tirar print de tudo — o print é o registro, não a memória.

## Como rodar o app num iPad sem ter um (12/set)

Ninguém no projeto tem iPhone, iPad ou Mac, e o Sauce Labs passou a cobrar.
A saída é o **Appetize** (o usuário já tem conta), que roda **simulador** no
navegador. Ele pede um `.zip` com o bundle **`.app`** dentro — **não um
`.ipa`**; `.ipa` é build de aparelho e o Appetize recusa.

Gerar esse `.app` exige macOS com Xcode, que não existe neste sandbox. Quem
faz isso é o workflow **`.github/workflows/ios-simulador.yml`**, num runner
`macos-latest`. **Primeira execução em 12/set: sucesso**, 8min24s, artefato
de 81 MB.

1. No GitHub, aba **Actions** → **"iOS pro Appetize (simulador)"** → botão
   **Run workflow** → escolher a branch.
2. Abrir a execução e rolar até o fim da página, seção **Artifacts**. O
   artefato é `PTKPlays-simulador` (~81 MB, build de debug).
3. **Descompactar uma vez** (ver a armadilha do zip duplo abaixo).
4. No Appetize, **Upload App** → soltar o `.zip` **de dentro**.

**Artefato não é release.** Ele não aparece na aba Releases nem em lugar
nenhum fora da página da própria execução do workflow, e **expira em 14
dias** (`retention-days: 14`). Passou disso, é só rodar de novo.

**Armadilha do zip duplo**: o GitHub re-empacota todo artefato num zip
próprio na hora do download, então o que chega no disco é

```
PTKPlays-simulador.zip      <- embalagem do GitHub
└── PTKPlays-simulador.zip  <- o do workflow, e ESTE que vai pro Appetize
    └── Runner.app
```

Subir o de fora faz o Appetize recusar, porque ele nao acha o `.app`.
**Não dá pra evitar** subindo a pasta `Runner.app` direto como artefato: o
`upload-artifact` não preserva symlinks (ele segue os links), e o bundle do
Flutter tem symlinks dentro dos frameworks — que é justamente o motivo de o
workflow compactar com `zip -y` antes. O zip duplo é o preço.

**Armadilha do `workflow_dispatch`**: o botão "Run workflow" só aparece se o
arquivo do workflow existir na **branch padrão** (`main`). Enquanto ele
estiver só na branch de dev, a aba Actions não mostra nada — e isso parece
"o workflow não funciona", quando na verdade ele nem foi oferecido.
**Mesclar antes de tentar rodar.**

Build de simulador **não precisa de assinatura nenhuma** — sem certificado,
sem provisioning profile, sem segredo da Apple. Por isso o workflow não
recebe credencial alguma e não tem como afetar a esteira de release (que é
do Codemagic, disparada por tag `v*`). O único gatilho é manual, de
propósito: minuto de macOS conta **10x** na cota do GitHub Actions em
repositório privado.

**O que o simulador prova e o que não prova** — a distinção que decide onde
gastar esforço:

- **Prova**: como o app aparece e se comporta num iPad. Serve inteiro pro
  **4.2.2** (a acusação de "conteúdo web agregado"), e serve pro
  `auth/operation-not-allowed` e `cloud_firestore/permission-denied`
  aparecerem, se forem esses os casos.
- **Não prova**: o Sign in with Apple de verdade. Simulador é justamente o
  ambiente que devolve `apple/unknown` — foi o que o Sauce Labs deu em
  17/ago. Um `apple/unknown` no Appetize é **inconclusivo**, não é
  diagnóstico.

Por isso as duas checagens gratuitas do Firebase Console (atenção 7) vêm
antes: elas não precisam de simulador nenhum.

### O iPad cai dos dois lados do corte de layout

O **iPad Air 11" (M3)**, aparelho das duas reprovações, tem **1180x820
pontos**. O corte do layout desktop do cadastro (`larguraDoCadastroDesktop`)
é **900**. Logo: **em paisagem o cadastro mostra o cartão de duas colunas**,
desenhado pra janela de navegador; em retrato, o layout de celular com a
onda. O app troca de layout quando a pessoa gira o aparelho.

Isso não é necessariamente bug — mas nunca foi olhado, e é a primeira coisa
concreta que se sabe sobre o que a Apple viu na tela. Coberto por
`test/criar_conta_test.dart`, grupo "CriarConta no iPad Air 11\"", inclusive
o caso de **girar o iPad no meio do cadastro** (que é a mesma remontagem de
`PageView` do redimensionamento de janela, chegando por outro caminho).

## Estado do git

- Branch de dev: **`claude/ptk-plays-setup-2q86aw`**, e ela está **igual à
  `main`** — nada em voo.
- Último merge: **PR #78** (`f850ad0`), com o cenário das artes de volta,
  três correções no cadastro e o pré-teste de e-mail virando Cloud
  Function. Antes dele, **PR #77** (curtidas) e **PR #76** (i18n, exclusão
  de conta, banimento).
- **Nenhum PR aberto.**
- **`main` → deploy automático no Vercel em `https://ptk-plays.vercel.app`**
  (atenção: `plays.vercel.app`, que consta em versões antigas deste
  arquivo, **dá 404** — não é o endereço certo).
- Cada PR gera um **preview próprio no Vercel**, comentado no próprio PR —
  é assim que o usuário revisa mudança visual antes de mesclar.
- `pubspec.yaml`: `version: 1.2.1+17`. Dependências novas desta leva:
  **`flutter_localizations`** (i18n) e **`cloud_functions`** (pré-teste de
  e-mail).
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

- **397 testes** passando (`flutter test`), mais **58** no backend
  (`cd functions && npm test`).
- `flutter analyze`: **0 erros e 1 warning**, mais uma baseline conhecida
  de ~96 *infos* antigas (nomes de arquivo em PascalCase, `withOpacity`
  deprecated) — não são regressão, não mexer sem pedir.
- O warning é em **`lib/view/Videos.dart:132`**
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

- **14/set** — `firestore.rules` + `storage.rules`, pela exclusão de conta
  (confirmado por print do Cloud Shell).
- **15/set** — `functions:emailJaCadastrado` (a função nova do pré-teste de
  e-mail) e `firestore.rules` de novo, carregando as curtidas e o
  fechamento da listagem de `nicknamesParaEmail`. Confirmado pelo usuário.

**Não há deploy pendente.** O que falta do lado do Firebase são **duas
configurações de Console**, que não são deploy: o App Check e a política de
TTL. Ver atenção 2.

Atenção: `firebase deploy --only storage:rules` **não funciona** (o CLI
interpreta "rules" como nome de target); o comando certo é `firebase
deploy --only storage`.

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

O recorte foi feito com um script em **PIL puro** (em 07/set não havia
numpy no ambiente; em 14/set ele instalou normalmente com `pip install
numpy scipy` — ver "A arte da selfie de joinha" no fim desta seção): flood
fill a partir da borda **de cima**, comparando cada pixel
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
2. **Quadro comum às cinco**, ancorado embaixo. As artes foram desenhadas
   na mesma escala, então colar cada recorte num quadro único mantém o PTK
   do mesmo tamanho em todas as etapas — recortar cada uma no próprio
   limite faria ele pular de tamanho na transição entre telas. O quadro
   hoje é 755×1159.

   **O encaixe é pela LARGURA, e isso importa.** Nas artes originais a
   silhueta ocupa os 755px inteiros, e é a largura que dá a sensação de
   "mesmo tamanho" entre as etapas. Encaixar pela altura faria o PTK sair
   6% maior que o das outras telas.

### A arte da selfie de joinha (14/set)

O PNG que o usuário subiu em 13/set (1,5 MB, fundo azul, espaços no nome)
substituiu a arte da **etapa da foto**. O recorte dele derrubou a técnica
descrita acima, e vale registrar por quê:

- **O flood fill a partir da borda não serve nesta arte.** A calça e a
  camisa são quase pretas, o fundo escurece embaixo, e o preenchimento
  vazava por ali e comia o personagem inteiro — sobrava só a cabeça e o
  braço.
- **O que separou foi a cor.** O fundo é azul saturado: o canal azul passa
  dos outros dois por 120 a 190, e nenhuma parte do desenho chega perto
  (camisa 15, celular 16, calça 6, pele negativa). Essa distância virando
  alfa já entrega o contorno com a borda suave de brinde.
- **Um risco de luz roxa do fundo encosta na camisa** e viajava junto por
  estar colado. A regra que resolve: só entra na componente o que é opaco
  sem dúvida (alfa ≥ 0.98), e a borda suave volta por dilatação curta — o
  risco, meio transparente, fica de fora.

Este ambiente **tem** `numpy`/`scipy` disponíveis via `pip install` (ao
contrário do que versões antigas deste arquivo diziam sobre "PIL puro").

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

1. **Exercitar as quatro entregas de 15/set contra o Firebase de verdade**
   (ver atenção 1) — é abrir o app e seguir cinco roteiros curtos. É o mais
   barato da lista e o de maior risco.
2. **Confirmar que o webhook do WhatsApp está gravando** (ver atenção 4) —
   mandar uma mensagem pro número de teste e olhar a aba.
3. **Arte de boas-vindas** do cadastro (trivial: 1 arquivo + 1 linha).
4. **App Check e política de TTL** no Console (ver atenção 2). Nenhum dos
   dois é código.
5. **Badges contando de verdade** — aprovado pelo usuário, com uma decisão
   de caminho em aberto (ver "O que está esperando resposta", item 1). As
   curtidas já destravaram a badge "Popular".
6. **Destravar a reprovação da Apple** (ver atenção 7). A parte de código
   saiu em 11/set; o que resta — reproduzir num iPad e escrever as App
   Review Notes — depende do usuário e de aparelho físico. O provedor Apple
   no Firebase Console **já foi ligado** pelo usuário em 13/set.
7. **Notificações push** — pedido em 13/set e **adiado pelo usuário em
   14/set** ("vamos deixar para a próxima etapa"). Bloqueado na **chave
   APNs**, que só ele pode gerar. O lado do código é: `firebase_messaging`
   no `pubspec.yaml`, token salvo no perfil do usuário, e uma Cloud
   Function disparada pelos webhooks de live **que já existem**
   (`twitchWebhook`, `kickWebhook`, `verificarYoutubeAoVivo`).

   **Atenção — metade disso já existe.** `functions/index.js` tem um
   `notificarAoVivo` (`onDocumentCreated` em `posts/{postId}`, região
   `southamerica-east1`) que já envia FCM pro tópico de live. **Não
   confirmado**: se ele chegou a ser deployado e se alguém já se inscreve
   no tópico pelo app. Conferir antes de reimplementar do zero.
8. **Comentários** — não decidido (ver "O que está esperando resposta",
   item 2). Arrasta o guideline 1.2 junto.
9. **Custom claim de admin** no Auth (ver atenção 6).
10. **Etapa 3 — mensagem privada do admin**: coleção `conversas` + regras +
    tela de chat. A opção já existe no menu e avisa que não está pronta.
    Quando existir, entra também na remoção em cascata (o lugar já está
    marcado no código).
11. **Etapa 4 — autoplay do preview na aba Vídeos** (mudo, um player por
    vez, com detector de visibilidade).
12. **Etapa 5 — badges pelo painel**: `badges` é travado contra escrita do
    cliente de propósito, então precisa de Cloud Function.
13. **Etapa 7 — cargos customizados com permissões**: a mais invasiva,
    reescreve boa parte do `firestore.rules`.
14. **Etapa 8 — envio pelo WhatsApp**: a caixa de entrada (leitura) já
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
- **Python com PIL disponível.** `numpy` e `scipy` **não vêm de fábrica**,
  mas instalam normalmente com `pip install numpy scipy` (confirmado em
  14/set) — versões anteriores deste arquivo diziam que não havia numpy e
  que todo script de imagem tinha que ser PIL puro, e **isso estava
  errado**: era só falta de instalar. Com scipy, `ndimage.label` resolve
  "fica só com o maior componente conectado" em uma linha, que em PIL puro
  vira uma BFS na mão.
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
