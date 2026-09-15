# PTK Plays — Instruções para o Claude

## Regra permanente: testes unitários

Sempre que eu implementar ou corrigir algo no código (feature nova, bugfix,
refatoração), devo:

1. Implementar a mudança.
2. Escrever (ou atualizar) um teste unitário/widget que comprove o
   comportamento implementado/corrigido.
3. Rodar `flutter test` e `flutter analyze` antes de reportar a tarefa como
   concluída.
4. Contar ao usuário o que foi feito no código **e** qual teste cobre isso.
5. Se o teste não conseguir ser validado de ponta a ponta (ex: depende de
   infraestrutura externa — Firebase, Google/Apple Sign-In nativo, chaves de
   API, dispositivo físico — que não está disponível neste ambiente), avisar
   claramente qual é o motivo e o que falta para o usuário validar por conta
   própria.

## Regra permanente: feedback de ações (Toast) e indicador de carregamento

Padrão de UI definido em 18/ago/2026, a ser seguido em toda tela nova ou
alterada:

- **Resultado de uma ação de salvar/atualizar/enviar dados** (ex: salvar
  perfil, trocar senha, enviar foto) deve mostrar um **Toast** no topo da
  tela — `mostrarToast(context, mensagem: '...', erro: true/false)`, em
  `lib/components/Toast.dart`. É um feedback não-bloqueante que some sozinho
  (~3s), tanto pra sucesso quanto pra erro dessa ação específica.
- **Erros de validação de formulário** (campo obrigatório vazio, formato
  inválido, senhas não coincidem — algo que o usuário precisa corrigir antes
  de tentar de novo) continuam usando o modal bloqueante
  `mostrarErroCustom` (`lib/components/ModalMSG.dart`), que exige toque pra
  fechar — faz mais sentido reter a atenção do usuário nesses casos.
- **Toda operação assíncrona que demora perceptivelmente** (carregar dados
  do Firestore/API, enviar uma imagem, etc.) deve mostrar um
  `CircularProgressIndicator` enquanto isso — usar a cor do tema
  (`isDark ? AuthTheme.linkDark : AuthTheme.linkLight`) pra loading de tela
  inteira/seção, ou `CircularProgressIndicator(strokeWidth: 2, color:
  Colors.white)` dentro de um botão/badge pequeno (padrão já usado em
  `BotaoPrimario` e no botão de trocar foto em EditarPerfil.dart).

Login.dart, Cadastro.dart e o diálogo de excluir conta em Profile.dart ainda
usam só `mostrarErroCustom` pros próprios erros (não foram retrofitados pra
Toast ainda) — ao mexer nessas telas de novo, alinhar com essa regra.

## Regra permanente: toda falha diz de onde veio

Definida em 12/set/2026, depois de **duas revisões da App Store perdidas**
adivinhando a causa de um popup genérico (ver `CHECKPOINT.md`, atenção 8).

**A regra**: nenhuma mensagem de erro causada por uma exceção pode chegar
na tela sem um código que identifique a causa. Usar
`lib/utils/DiagnosticoDeErro.dart`:

- `mensagemComCodigo(erro)` — o caminho normal: traduz e anexa o código;
- `comCodigo('frase própria', erro)` — quando a tela tem uma frase melhor
  que a tradução automática;
- `comCodigoManual('frase', 'familia/detalhe')` — pra falha **sem exceção**,
  quando o próprio app detecta a condição (ex: `canLaunchUrl` devolve
  `false` sem lançar nada). Nunca inventar uma `Exception` só pra ter o que
  passar adiante — o código descreveria a exceção falsa, não a condição.

O formato na tela é `mensagem` + linha em branco + `(código: familia/detalhe)`.
A família diz em qual camada parar de procurar: `auth/`, `cloud_firestore/`,
`firebase_storage/`, `apple/`, `google/`, `plataforma/`, `inesperado/`.

**Onde NÃO usar**: erro de validação de formulário (campo vazio, senha
curta, senhas diferentes). Ali não houve exceção — não há causa a
diagnosticar, e o código vira ruído sobre algo que a pessoa já sabe
resolver. Esses continuam no `mostrarErroCustom` puro.

**Sim, é feio pro usuário.** É deliberado, e o pedido foi explícito: em
build de release o `debugPrint` não vai a lugar nenhum, e o que chega até
nós é sempre um print de tela mandado por terceiro — um revisor da Apple,
um inscrito no Discord. Se o print só diz "Ops! Tente novamente", a
investigação começa do zero.

**Duas armadilhas de implementação**, ambas já custaram tempo:

- `FirebaseAuthException` **é** subclasse de `FirebaseException`. O teste de
  tipo do Auth tem que vir primeiro, senão todo erro de autenticação pega a
  tradução errada — e nada no compilador acusa.
- **`catch` só do tipo esperado trava a tela.** Um `on FirebaseAuthException
  catch` sozinho deixa qualquer outra falha escapar: a Future estoura, o
  `setState` que desliga o loading nunca roda e o botão fica preso em
  "carregando" pra sempre. Capturar tudo e decidir o tipo por dentro.

## Regra permanente: a interface reage enquanto a pessoa digita

Definida em 13/set/2026, a partir de UX: **o olho humano registra mudança na
tela antes de ler qualquer texto.** Um botão cinza parado não comunica que
falta algo — a pessoa nem percebe que ele mudou de estado. Um botão que
**surge** diz "é por aqui" sem precisar de palavra nenhuma.

**A regra**: em qualquer tela com formulário, o botão de ação principal
**aparece e some** conforme a etapa passa a ter o mínimo preenchido, em vez
de ficar sempre visível e desabilitado. Vale pra toda tela — não só o
cadastro.

**O limiar de aparecer é mais frouxo que o de validar, de propósito.** No
cadastro: o nick mostra o botão na 2ª letra mas só libera na 3ª; o e-mail
basta ter `@`. Quando o botão aparece sem estar válido, ele aparece
**desabilitado**, e o aviso embaixo do campo diz o que falta. **É a folga
entre os dois limiares que faz o mecanismo funcionar** — o botão chama
atenção, o aviso explica. Se os limiares fossem iguais, o surgimento
significaria só "pode clicar", e não "você está quase lá".

Onde isso vive: `avancarVisivel` (`lib/view/CriarConta.dart`) e
`minimoParaMostrarAvancar` (`lib/utils/ValidacaoCadastro.dart`).

**Senha: nada de exigir maiúscula, número ou símbolo.** Mínimo de 6
caracteres e ponto final — a força fica com o usuário. Decisão explícita:
exigência complicada cansa e custa cadastro, e a comunidade vale mais que a
entropia da senha.

**Dado pessoal não essencial é opcional.** O WhatsApp era obrigatório e
virou opcional em 13/set, com um botão **"Pular"** discreto ao lado do
avançar. Dois motivos: a Apple recusa app que **exige** dado pessoal não
essencial ao que ele faz (guideline 5.1.1(ii)), e um revisor não vai querer
informar telefone. O que continua barrado é o dado **pela metade** — um
número quebrado parece contato e não é.

**Armadilha de teste**: `AnimatedSwitcher` só remove o filho que sai no
frame **seguinte** ao fim da animação. Um `pump(duração)` sozinho ainda
encontra o widget antigo, e o teste falha por timing, não por
comportamento. Usar `pump()` antes, depois `pump(duração)`.

## Regra permanente: tudo que a pessoa lê tem que existir em duas línguas

Definida em 14/set/2026. O app fala **português do Brasil e inglês dos
EUA**, e escolhe sozinho pela preferência do aparelho (`IdiomaApp.detectar`,
chamado no `main()`).

**A regra**, nas palavras do usuário (14/set): *"tudo que envolver texto no
app deve ser tratado como variável, pois um texto em inglês ou português
poderá substituir essa variável"*. Nenhuma frase que chega na tela nasce
como literal no código. Toda tela nova e toda feature nova entra com o
texto no catálogo — `lib/i18n/Textos.dart` (o contrato), `TextosPtBr.dart`
e `TextosEnUs.dart` (as duas línguas). No código, sempre
`textos.algumaCoisa`.

**Isso vale inclusive pro texto que a pessoa lê quando o app a está
recusando** — o aviso de conta banida, a mensagem de erro de login, o que
aparece antes de qualquer sessão existir. É justamente onde é mais fácil
esquecer, e é onde uma frase na língua errada machuca mais.

**Por que uma classe abstrata e não um mapa de String pra String.** Com
mapa, a chave que falta numa língua só aparece quando alguém abre aquela
tela naquela língua — e o que chega na tela é `null` ou a própria chave.
Aqui, esquecer uma frase em `TextosEnUs` **não compila**.

**Por que não o `gen_l10n` com arquivos ARB.** O gerado exige
`AppLocalizations.of(context)`, e boa parte do texto deste app nasce longe
de um `BuildContext`: `ValidacaoCadastro`, `AuthErrorTranslator`,
`AuthViewModel` e os repositórios devolvem frase pronta. Passar contexto até
lá seria arrastar UI pra dentro da regra de negócio; a saída usual (guardar
o `AppLocalizations` num global) perde exatamente a checagem que o ARB dava.

**Onde o texto NÃO é traduzido, e por quê** — são poucos casos, e cada um
tem motivo:

- **o nome do app** (`'PTK plays'`): é marca, não texto;
- **os nomes das línguas** na tela de configurações ("Português (Brasil)",
  "English (US)"): aparecem sempre na própria língua que nomeiam. Traduzir
  o nome de uma língua é o jeito exato de esconder a opção de quem precisa
  dela — quem abriu aquela tela porque não entende o que está escrito tem
  que conseguir achar a própria língua na lista;
- **as chaves salvas no Firestore** (`'admin'`, `'novato'`, `'gamer'`): o
  rótulo traduz, a chave não. Se o título traduzido fosse o que vai pro
  banco, uma conta criada com o app em inglês teria badges que o app em
  português não reconheceria;
- **`debugPrint`**: é texto pra quem programa.

**Data não é só palavra.** `09/03` é setembro no Brasil e março nos EUA.
Toda data passa por `textos.dataDiaMes...`, que inverte a ordem junto com a
língua. Deixar a ordem fixa faz a data mentir pra metade de quem lê, sem
nenhum sinal de que mentiu.

**Três armadilhas que já custaram tempo:**

- **`const` congela a frase na compilação.** Lista de `BottomNavigationBarItem`,
  catálogo de avatares, catálogo de badges, mapa de selos do painel: todos
  tiveram que deixar de ser `const` (ou virar getter) pra mudar de língua.
  O compilador avisa quando é `const` direto; **não avisa** quando a frase
  está dentro de um `const` maior.
- **A detecção mora no `main()`, nunca no catálogo.** Se o global
  consultasse a plataforma sozinho, todo `flutter test` viraria inglês — o
  ambiente de teste responde en-US — e centenas de asserts de texto
  quebrariam de uma vez sem nada ter mudado no app. O padrão é português; é
  o `main()` que troca.
- **Uma tela que só lê `textos.` não redesenha sozinha** quando o idioma
  muda. Quem precisa reagir na hora tem que observar o `IdiomaController`
  (`context.watch<IdiomaController>()`), do mesmo jeito que já observa o
  `ThemeController`.

**O que impede a regra de virar boa intenção** é o último teste de
`test/i18n_test.dart`: ele varre `lib/` atrás de literal com acento fora do
catálogo. Sem ele, a tela nova entra em português, ninguém repara, e o app
volta a ser meio bilíngue. A lista de exceções ali é nominal e cada linha
tem o motivo escrito ao lado — **acrescentar arquivo naquela lista precisa
de justificativa**, não é o jeito normal de fazer o teste passar.

## Regra permanente: quem é banido é expulso, mas o login dele NÃO some

Definida em 14/set/2026, corrigindo uma leitura errada minha.

**O login de uma conta banida não pode ser apagado.** É ele que carrega o
`uid` que aponta pro `users/{uid}` com o `estadoModeracao` — apagar o login
apagaria a memória do banimento, e a pessoa criaria outra conta com o mesmo
e-mail e entraria limpa. **O banimento mora na conta que continua
existindo.**

**E quem é banido jamais fica dentro do app como se estivesse logado.** Até
14/set o `ContaGate` desenhava uma tela de bloqueio **por cima** do app,
com a sessão ainda válida por baixo. Comprava uma coisa boa — uma suspensão
vencendo com o app aberto devolvia a pessoa exatamente onde estava — e
pagava caro: bastava a cortina falhar em qualquer caminho pra pessoa estar
usando o app de novo.

**O fluxo correto, em três tempos:**

1. **Expulsar.** Bloqueio detectado com o app aberto → `logout()` →
   `pushAndRemoveUntil` pro `Login`, levando o `BloqueioDaConta` junto.
2. **Barrar na porta.** Toda entrada — senha, Google e Apple — lê
   `users/{uid}` logo depois de autenticar e, se estiver bloqueada,
   **desloga antes de devolver**. A ordem importa: a regra do Firestore só
   libera ler `users/{uid}` pra quem está logado, então a leitura acontece
   com a sessão ainda de pé. O caminho social é a porta dos fundos mais
   óbvia do banimento — nunca deixá-lo de fora.
3. **Explicar.** `mostrarModalContaBloqueada` na tela de login, dizendo que
   a conta violou as regras de uso, o motivo que o admin escreveu (se
   escreveu) e, na suspensão, até quando. **Nas duas línguas**, como todo o
   resto.

**Não é `mostrarErroCustom`**, e a distinção importa: não houve erro
nenhum. A senha estava certa, a conta existe, e a entrada foi **recusada**.
Chamar isso de "Ops!" faria parecer falha do app e convidaria a pessoa a
tentar de novo.

**Suspensão vencida libera sozinha**, sem o admin clicar em "Reativar
conta" — quem decide é o prazo (`UserModel.estaBloqueado`), não o selo que
o Painel ADM mostra. Se dependesse do clique, toda suspensão viraria
banimento na prática quando o admin esquecesse de voltar nela.

Onde isso vive: `bloqueioDe` e `BloqueioDaConta`
(`lib/data/models/BloqueioDaConta.dart`), `ContaGate`
(`lib/components/ContaGate.dart`) e `mostrarModalContaBloqueada`
(`lib/view/ContaBloqueada.dart`).

## Regra permanente: um commit por arquivo alterado

Pedido explícito do usuário: **cada arquivo que eu mexer vira um commit
próprio**, nunca vários arquivos num commit só. Vale pra tudo — código,
teste, asset, documentação.

A mensagem de cada commit explica *o que mudou no entendimento do
projeto*, não o que o diff já mostra: qual era o problema, por que a
solução óbvia não servia. Um commit chamado "atualiza o checkpoint" não
serve pra nada seis meses depois.

## Regra permanente: documentação viva

Ao terminar uma entrega — e sempre antes de um `/clear` —, atualizar a
documentação do repositório seguindo a skill
**`.claude/skills/atualizar-documentacao/`**, que diz o que escrever em
qual arquivo:

- `CHECKPOINT.md` — o estado de hoje (o que uma sessão nova precisa saber);
- `ROADMAP.md` — por que cada coisa foi feita assim;
- `CLAUDE.md` (este arquivo) — só o que vale pra sempre.

Duas coisas que essa skill insiste, e que valem repetir aqui: registrar a
**armadilha**, não só o resultado; e marcar explicitamente o que é
suposição ("**Não confirmado**:") em vez de escrever como fato algo que
não foi checado nesta sessão.

## Convenção de commits

Meus commits usam o identificador de git configurado no ambiente
(`Claude <noreply@anthropic.com>`), já que não altero a configuração global
do git. Para refletir a autoria real do trabalho, incluo a trailer:

```
Co-Authored-By: Marcos Patrick <marcospatrick039474@gmail.com>
```

em toda mensagem de commit feita neste repositório.

## Tags de release (gatilho de build do Codemagic)

O Codemagic está configurado (27/jul/2026) pra só buildar quando uma tag
`v*` é criada e enviada ao GitHub (push/PR comuns não disparam build).

**Regra**: eu só crio e envio (`git push origin <tag>`) uma tag `v*` quando
o usuário pedir isso explicitamente. Se ele só pedir pra commitar/subir/abrir
PR, sem mencionar tag, eu faço só isso — sem criar tag nenhuma. Nem toda
atualização do PTK Plays precisa gerar um build de iOS/Android via
Codemagic.

## Regras da Google Play Store (Android)

### Nível desejado da API (target API level)

A Play Store exige que o `targetSdkVersion` do app esteja, no máximo, 1 ano
"atrasado" em relação à versão mais recente do Android — quem não atender
não consegue publicar atualizações.

- **Prazo em vigor detectado em jul/2026**: atualizar o nível desejado da API
  até **31 de agosto de 2026**, senão o app fica bloqueado pra novas
  atualizações no Google Play.
- Por decisão explícita do usuário, `android/app/build.gradle.kts` usa
  `compileSdk = 36` e `targetSdk = 36` **fixos** (não mais
  `flutter.compileSdkVersion`/`flutter.targetSdkVersion`), pra não depender
  da versão do Flutter usada no Codemagic pra cumprir essa exigência.
- **Isso precisa ser revisado manualmente** sempre que a Play Store exigir
  um nível mais novo (ela vai mandar um aviso parecido de novo quando o
  Android 17/18/etc. sair e o prazo de "1 ano de defasagem" apertar de novo)
  — não é mais algo que se resolve sozinho atualizando o Flutter.

### Teste fechado obrigatório antes de produção

Apps novos (sem histórico de produção) publicados no Google Play precisam
passar por um período de teste fechado antes de poder solicitar a
publicação em produção:
- Pelo menos 12 testadores que aceitaram participar.
- Testagem **contínua** por no mínimo 14 dias a partir da data de revisão.

O PTK Plays cumpriu esse requisito em jul/2026 e usou o botão "Solicitar a
produção" no Play Console — mas em 04/ago/2026 o Google recusou com "Seu
app precisa de mais testes para acessar a produção do Google Play" e
reiniciou a contagem dos 14 dias do zero.

**Causa raiz (não é bug de código, é operacional)**: a exigência não é "ter
12 testadores por 14 dias no total" — é ter **pelo menos 12 testadores
opt-in de forma ininterrupta** durante os 14 dias. Se em qualquer momento
o número de testadores ativos cai abaixo de 12 (um testador desinstala o
app, sai do grupo de teste, fica inativo o suficiente pro Google não
considerar "uso orgânico", ou é filtrado por parecer bot/fake), **a
contagem zera na hora** e recomeça do zero a partir daquele ponto.

**O que NÃO reinicia a contagem**: subir uma nova versão/build durante o
teste fechado não afeta o contador — ele rastreia os testadores estarem
opt-in continuamente, não qual versão eles estão testando. Dá pra seguir
iterando o app normalmente durante essa janela.

**Como evitar reiniciar de novo**: manter um buffer de testadores acima de
12 (ex.: 15-16 pessoas), combinar com eles pra não desinstalarem nem
saírem do teste fechado durante as 2 semanas, e não fechar/pausar o teste
fechado enquanto a contagem estiver rodando.

## Assinatura (signing) do Android no Codemagic

`android/app/build.gradle.kts` lê `storeFile` do `android/key.properties`
(`file(keystoreProperties["storeFile"] as String)`), em vez de um nome fixo
tipo `upload-keystore.jks`. Isso foi corrigido em 28/jul/2026 porque o
recurso nativo "Enable Android code signing" da UI do Codemagic gera o
próprio `key.properties` do jeito dele, apontando pro caminho onde ele
mesmo colocou o keystore — um valor fixo no Gradle nunca bate com isso e o
build falha com `Keystore file '...' not found for signing config
'release'`, mesmo com o keystore certinho subido na UI.

**Se esse erro voltar a aparecer**: não é falta de configurar o keystore de
novo na UI — é sinal de que essa leitura dinâmica quebrou (ou o
`key.properties` gerado pelo Codemagic não tem `storeFile`). Builds locais
continuam precisando de um `android/key.properties` (gitignored) com a
linha `storeFile=upload-keystore.jks`.
