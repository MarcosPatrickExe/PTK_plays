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
