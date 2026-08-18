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
