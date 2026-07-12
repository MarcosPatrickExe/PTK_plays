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
