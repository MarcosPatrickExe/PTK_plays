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
