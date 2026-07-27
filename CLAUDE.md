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

## Convenção de commits

Meus commits usam o identificador de git configurado no ambiente
(`Claude <noreply@anthropic.com>`), já que não altero a configuração global
do git. Para refletir a autoria real do trabalho, incluo a trailer:

```
Co-Authored-By: Marcos Patrick <marcospatrick039474@gmail.com>
```

em toda mensagem de commit feita neste repositório.

## Regras da Google Play Store (Android)

### Nível desejado da API (target API level)

A Play Store exige que o `targetSdkVersion` do app esteja, no máximo, 1 ano
"atrasado" em relação à versão mais recente do Android — quem não atender
não consegue publicar atualizações.

- **Prazo em vigor detectado em jul/2026**: atualizar o nível desejado da API
  até **31 de agosto de 2026**, senão o app fica bloqueado pra novas
  atualizações no Google Play.
- Este projeto usa `compileSdk = flutter.compileSdkVersion` e
  `targetSdk = flutter.targetSdkVersion` em `android/app/build.gradle.kts`
  (sem valor fixo) — ou seja, o nível da API segue o default embutido em
  cada versão do Flutter SDK, não um número travado no código.
- **O que isso significa na prática**: o requisito só é cumprido se o
  **Flutter usado pelo Codemagic para gerar o build** estiver
  razoavelmente atualizado. Se o Codemagic estiver com uma versão antiga do
  Flutter presa em cache, o AAB gerado pode sair com um `targetSdkVersion`
  desatualizado mesmo com esse código sem alterações.
- Sempre que formos tratar um aviso de "nível da API desatualizado" do Play
  Console, checar/atualizar a versão do Flutter usada no Codemagic antes de
  mexer no `build.gradle.kts` — só travar um número fixo aqui se o
  Codemagic não puder ser atualizado por algum motivo.

### Teste fechado obrigatório antes de produção

Apps novos (sem histórico de produção) publicados no Google Play precisam
passar por um período de teste fechado antes de poder solicitar a
publicação em produção:
- Pelo menos 12 testadores que aceitaram participar.
- Testagem contínua por no mínimo 14 dias a partir da data de revisão.

O PTK Plays cumpriu esse requisito em jul/2026 e já pode usar o botão
"Solicitar a produção" no Play Console.
