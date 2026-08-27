# Checkpoint — PTK Plays

Snapshot do estado do projeto em **20/ago/2026**, escrito pra retomar o
trabalho numa sessão nova do Claude sem perder contexto. Ver também
`ROADMAP.md` (pendências e decisões técnicas mais detalhadas) e `CLAUDE.md`
(regras permanentes: testes unitários, Toast/loading, commits, tags,
Google Play, signing).

## Estado do git

- Branch principal de dev: `claude/ptk-plays-setup-2q86aw`.
- `main` (deploy automático via Vercel, `plays.vercel.app`) está em sincronia
  com a dev branch — HEAD atual: `cfae63a` ("Merge pull request #34").
- Fluxo usado o tempo todo: feature branch → PR pra `claude/ptk-plays-setup-2q86aw`
  → merge → PR pra `main` → merge → sync do `main` local.
- iOS/Android buildam via Codemagic só quando uma tag `v*` é criada e
  enviada — **nunca criar tag sem o usuário pedir explicitamente**.

## O que já está implementado e funcionando (sessões anteriores)

- **Avatares pré-definidos** (6 personas) no cadastro/edição de perfil —
  `lib/data/models/AvatarPreset.dart`, `lib/components/SeletorAvatarPreset.dart`.
- **Máscara de telefone WhatsApp** corrigida (editar/apagar dígito no meio
  sem quebrar) — `lib/utils/MascaraTelefoneWhatsapp.dart`.
- **Troca de senha** dentro de Editar Perfil (reautenticação + nova senha) —
  `AuthRepository.alterarSenha` / `AuthViewModel.alterarSenha`.
- **Avatar padrão** ("Inscrito do canal") pra contas legadas sem preset/foto —
  `chavePresetParaExibir` em `AvatarPreset.dart`, usado tanto em `Profile.dart`
  quanto em `EditarPerfil.dart` (mesma prioridade nos dois lugares).
- **Upload de foto de perfil** com crop/zoom (`ModalCropFoto.dart`) →
  Firebase Storage (`fotos_perfil/{uid}/foto.png`). Exigiu configurar
  `storage.rules` (publicado manualmente pelo usuário no Console) e CORS do
  bucket via `gsutil cors set cors.json gs://ptk-plays.firebasestorage.app`
  no Cloud Shell (resolvido — a foto não aparecia na Web por causa do
  CanvasKit usando `fetch()`, que respeita CORS diferente de uma `<img>`
  comum).
- **Feedback de Toast** (não-bloqueante, ~3s, topo da tela) — regra
  permanente documentada em `CLAUDE.md`. `mostrarErroCustom` (modal
  bloqueante) continua só pra erro de validação de formulário.
  **Pendente/gap conhecido**: Login.dart, Cadastro.dart e o diálogo de
  excluir conta em Profile.dart ainda não foram retrofitados pra Toast.
- **Loading spinners** padronizados (cor do tema em tela cheia, branco
  `strokeWidth: 2` dentro de botão/badge).
- **Botões circulares com fundo opaco branco** (voltar / alternar tema) —
  `AuthTheme.themeBtnBgDark/Light = Colors.white`, extraídos pro componente
  compartilhado `BotaoVoltar` em `lib/components/AuthWidgets.dart`.
- **Recuperação de senha por e-mail** — `AuthRepository.enviarEmailRedefinicaoSenha`
  usa `FirebaseAuth.sendPasswordResetEmail` (zero infra nova). Botão
  "Esqueceu sua senha atual? Enviar link por e-mail" dentro do card "Alterar
  senha" em `EditarPerfil.dart`. Campo de e-mail (somente leitura) também
  adicionado em Editar Perfil.

Todos os itens acima têm teste unitário/widget cobrindo (78 testes Flutter
passando, `flutter analyze` com 50 issues — baseline conhecida e antiga, sem
problemas novos).

## Recuperação de senha — decisão de canais (18-19/ago/2026)

- **E-mail**: implementado (ver acima).
- **SMS**: não implementado. Não precisa de biblioteca de terceiros — o
  Firebase Auth já tem Phone Authentication nativo. Exige habilitar "Phone"
  em Firebase Console → Authentication → Sign-in method + reCAPTCHA pra Web.
- **WhatsApp**: em andamento (ver seção abaixo) — é o canal mais lento dos
  três, mas o usuário decidiu priorizar ele agora porque a aprovação no Meta
  for Developers leva alguns dias, e dá pra seguir trabalhando em outras
  coisas nesse meio tempo.

## WhatsApp — arquitetura e progresso (19-20/ago/2026)

### Decisão: apps separados no Meta for Developers

O usuário pretende usar o mesmo número/canal WhatsApp pra **dois projetos
diferentes**: **PTK Plays** (recuperação de senha) e **PTK AI Studio**
(painel separado de edição/publicação automática de vídeos de lives em
Threads/Instagram/Facebook). Recomendação dada: **dois apps separados no
Meta for Developers**, sob o mesmo Portfólio empresarial ("PTK soluções
digitais") — evita misturar escopo de App Review e isola risco de suspensão.

**Detalhe pendente**: o usuário já tinha adicionado os casos de uso
**Threads** e **WhatsApp** no mesmo app (`PTK Plays`, App ID
`1581341000249480`) por engano, e não achamos um botão de remover o Threads
na UI atual do Meta. Decisão: deixar o Threads inerte nesse app (sem
configurar nem submeter permissões dele) e seguir só com WhatsApp aqui. O
app dedicado ao PTK AI Studio (Threads + Instagram + Facebook) fica pra
quando esse projeto for priorizado.

**⚠️ Ponto em aberto, não resolvido**: durante a configuração do webhook,
apareceu no Cloud Shell (projeto GCP `ptk-plays`) uma lista de Cloud
Functions/Cloud Run **já existentes e implantadas**, aparentemente do PTK AI
Studio: `twitchWebhook`, `kickOAuthCallback`, `kickAuthStart`,
`verificarYoutubeAoVivo`, `notificarAoVivo` (gatilho Firestore), e o serviço
`ptk-ai-studio-dashboard` no Cloud Run — implantado em 15/jul/2026. Isso
**contradiz** a recomendação de projetos totalmente separados: o backend do
AI Studio já está rodando dentro do projeto Firebase/GCP do `ptk-plays`, não
num projeto `ptk-ai-studio` separado (que existe como projeto Firebase
próprio, visto na tela de billing/Storage, mas parece não ser onde esse
backend está hospedado). **Perguntar ao usuário**: esse backend já existia
de um trabalho anterior (outra sessão/ferramenta)? Motivo, é
proposital manter tudo no mesmo projeto GCP? Vale entender antes de
continuar decidindo arquitetura.

**Resolvido (27/ago/2026)**: sim, era trabalho de uma sessão anterior — o
código dessas functions existia numa branch `feat/notificacoes-ao-vivo`,
nunca mergeada, que tinha divergido do `main` antes do webhook do
WhatsApp. Trazida e mesclada na branch de dev nesta sessão, junto com a
nova escrita em `transmissoes` no `ptk-ai-studio` (ver `ROADMAP.md`, seção
"Backend (Cloud Functions) — escrita de transmissoes no Firestore do PTK
AI Studio"). O backend do AI Studio continua rodando dentro do projeto GCP
`ptk-plays` mesmo — não foi movido nem duplicado.

### Setup do WhatsApp Business Platform (Meta for Developers → caso de uso "Conectar-se com clientes pelo WhatsApp")

- **Etapa 1. Experimente** — concluída. Número de teste da Meta:
  `+1 (555) 198-5430` (Phone Number ID `1320793181110892`, WABA ID
  `1919413515403458`). Número de destinatário de teste cadastrado e
  verificado: `+55 (85) 99131-4881`. Mensagens de teste trafegando (visível
  no log de webhooks de teste da própria tela do Meta).
- **Etapa 2. Configuração da produção** — em andamento, no passo
  **"Configurar webhooks"**.

### Backend (Cloud Functions) — criado e mergeado, deploy real pendente

Novo diretório `functions/` (Node.js, Firebase Functions 2ª geração,
`engines.node: 20`), PR #33 (→ dev) e PR #34 (dev → `main`), ambos
mergeados:

- `functions/index.js`: HTTPS function `whatsappWebhook`.
  - `GET`: responde o handshake de verificação do Meta
    (`hub.mode`/`hub.verify_token`/`hub.challenge`).
  - `POST`: valida a assinatura `X-Hub-Signature-256` (HMAC-SHA256 com o App
    Secret) antes de aceitar qualquer evento; por enquanto só loga e
    responde 200 — a lógica de enviar/verificar código ainda não foi
    escrita (próxima etapa, depois do webhook aceito).
- `functions/src/webhook.js`: lógica pura (`verificarHandshakeWebhook`,
  `assinaturaValida`), testada em `functions/test/webhook.test.js` (8
  testes Jest, `npm test` dentro de `functions/`, passando).
- `firebase.json` ganhou a seção `functions`; `.firebaserc` criado
  apontando o projeto padrão pra `ptk-plays`.
- Segredos via Secret Manager (`defineSecret`, nunca no código):
  `WHATSAPP_VERIFY_TOKEN` e `WHATSAPP_APP_SECRET`.

**⚠️ Cuidado já aprendido**: o App Secret que aparece dentro da
configuração do caso de uso "Acessar a API do Threads" é **específico da
Threads API**, diferente do App Secret principal do app. O correto pro
webhook do WhatsApp é o App Secret em **Configurações do app → Básico**
("Chave Secreta do Aplicativo", ao lado do "ID do Aplicativo"
`1581341000249480`, nome de exibição "PTK Plays").

### Progresso do deploy (Google Cloud Shell)

Repositório já clonado em `~/PTK_plays` no Cloud Shell do usuário
(`marcospatrick039474@cloudshell`), projeto Firebase ativo confirmado
(`firebase use ptk-plays` → "Now using project ptk-plays").

- ✅ `WHATSAPP_VERIFY_TOKEN` — segredo criado com sucesso
  (`projects/696548413882/secrets/WHATSAPP_VERIFY_TOKEN/versions/1`). O
  valor não é repetido aqui por boa prática (não duplicar segredo em texto
  puro versionado no git) — já está salvo no Secret Manager; se precisar
  ver de novo pra colar no formulário do Meta, rodar
  `firebase functions:secrets:access WHATSAPP_VERIFY_TOKEN` no Cloud Shell.
- ❌ `WHATSAPP_APP_SECRET` — **pendente**. O usuário encontrou o campo certo
  (Configurações do app → Básico → "Chave Secreta do Aplicativo") mas não
  conseguiu copiar o valor completo (32 caracteres hex) pelo navegador
  mobile — o menu de seleção de texto não mostrou a opção "Copiar" depois
  de "Selecionar tudo". Vai terminar isso no computador.
- ❌ `firebase deploy --only functions` — ainda não rodado (depende do
  segredo acima).
- ❌ Colar a URL da function + o verify token no formulário "Configurar
  webhooks" do Meta — ainda não feito.

## Próximos passos exatos (retomar por aqui)

1. **No computador do usuário**: abrir
   `developers.facebook.com/apps/1581341000249480/settings/basic/`, copiar
   a "Chave Secreta do Aplicativo" completa (Ctrl+A / Ctrl+C no campo, ou
   clicar em "Mostrar" se disponível na versão desktop).
2. No Cloud Shell (`~/PTK_plays`, projeto `ptk-plays` já ativo):
   ```
   firebase functions:secrets:set WHATSAPP_APP_SECRET
   ```
   Digitar o comando **sem** o valor colado junto (aprender com o erro que
   já aconteceu com o `WHATSAPP_VERIFY_TOKEN` — esperar o prompt separado
   `Enter a value for WHATSAPP_APP_SECRET:` antes de colar).
3. Deploy:
   ```
   firebase deploy --only functions
   ```
   Vai imprimir a URL, algo como
   `https://us-central1-ptk-plays.cloudfunctions.net/whatsappWebhook` (ou
   região `southamerica-east1`, que é a usada pelas outras functions do
   projeto — confirmar qual região o deploy realmente usa).
4. No formulário "Configurar webhooks" do Meta (Etapa 2): colar a URL em
   "URL de callback", o valor do `WHATSAPP_VERIFY_TOKEN` em "Verificar
   token", clicar "Verificar e salvar".
5. Continuar Etapa 2: "Registre seu número de telefone do WhatsApp" (número
   de produção real, que **não pode** estar ativo no WhatsApp normal/Business
   App), "Adicione informações de pagamento", testar "Enviar mensagem".
6. Etapa 3 (Verificação da empresa) — upload de documentos, aprovação leva
   alguns dias.
7. **Depois do webhook aceito**: implementar as Cloud Functions
   `enviarCodigoRecuperacaoWhatsapp` / `verificarCodigoRecuperacaoWhatsapp`
   (gerar código, salvar no Firestore com expiração, chamar a Graph API pra
   enviar, validar depois) — e criar/aprovar um **template de mensagem
   categoria "Authentication"** no WhatsApp Manager, porque não dá pra
   mandar texto livre pro primeiro contato (janela de 24h fechada).
8. Resolver a pergunta em aberto sobre o backend do PTK AI Studio já estar
   no projeto GCP `ptk-plays` (ver seção acima).

## Notas úteis de ambiente

- Neste sandbox de dev, o Flutter fica em `/opt/flutter/bin`, **fora do
  PATH por padrão** — rodar `export PATH="$PATH:/opt/flutter/bin"` antes de
  qualquer comando `flutter`.
- `flutter analyze`/`flutter build` costumam sujar `analysis_options.yaml`
  automaticamente (injeta um bloco `analyzer: exclude:`) — sempre conferir
  `git status` e reverter esse arquivo (`git checkout -- analysis_options.yaml`)
  antes de commitar, se não for uma mudança intencional.
- Projeto Firebase `ptk-plays` está no plano **Blaze** (confirmado
  20/ago/2026, R$ 1.537,58 de crédito restante no teste sem custo). O
  projeto Firebase separado `ptk-ai-studio` também está no Blaze (confirmado
  antes, mas ver ponto em aberto acima sobre onde o backend realmente está
  implantado).
