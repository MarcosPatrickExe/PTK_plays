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
